
# PG2

# Общие сведения

- наследник PG(one)
- c 2022
- на Clojure
- медленно (2-3 раза)
- на Java быстрее

- что значит быстрее?
- не быстрее PG JDBC, но быстрее next.jdbc

next.jdbc = Java JDBC + Clojure API
быстрее кложурной обвязки


# Драйвер или клиент?


## Кто пользуется?

XTDB для тестов Wire Protocol (позже)
https://github.com/xtdb/xtdb/pull/3857


Sync data from any Postgres DB to another
https://schemamap.io/

и другие (но мало)

сам -- нет, но надеюсь


## О чем презентация

- о специфике
- Postgres Wire Protocol
- зачем браться за свое решение
- парсинг текстовых и бинарных данных
- сопоставление типов
- дизайн и API


## Demo time!

- получить соединение
- простой запрос
- разные типы полей (дата, время, json)
- транзакция (вложенная)
- copy-in/out
- SSL с сертификатом
- массивы
- отладочный лог
- ?

## Postgres Wire Protocol

1. подключаемся к соекту
2. передаем сообщение
3. читаем сообщение
4. все!

Глава 55. Клиент-серверный протокол
https://postgrespro.ru/docs/postgresql/15/protocol

Сообщения

┌─────┬──────────┬───────────────────────────────────────┐
│ tag │  length  │             byte payload              │
└─────┴──────────┴───────────────────────────────────────┘

- отправка
- чтение до какого-то условия
- отправка

пример Query

Для парсинга `java.nio.Bytebuffer`
забирать все
пример


## Первичный обмен сообщениями (Startup)

 -> StartupMessage
<-  AuthenticationResponse(code)

TODO


- типов сообщений много
- Startup phase is slow (новое соединение на каждый запрос)
- Auth Scram SHA: 4096 XOR-итераций (с версии 15)

## Дальнейший обмен сообщениями

 -> Query

TODO

## Зачем?

- интересно
# ^^^^^^^^^
- задействовать Postgres по максимуму
- JDBC -- общий знаменатель (угодить всем)

1. JSON           нет
2. COPY API       CopyManager
3. Date & Time    java.sql.Timestamp
4. SSL            keystore

Хочу:

1. JSON           да
2. COPY API       functions
3. Date & Time    java.time.*
4. SSL            параметр

+ не настраивать это в каждом проекте

## Дизайн и API

- где API лучше
- отталкиваться от задач

## Я не одинок

- postgres-async-driver
https://github.com/alaisi/postgres-async-driver (java)
https://github.com/alaisi/postgres.async        (clojure)

- VertX stack
Reactive PostgreSQL Client
https://vertx.io/docs/vertx-pg-client/java/

Rust Postgres
https://github.com/sfackler/rust-postgres



# Специфика

## Query vs Execute

  Query -- выполнить одно и более выражений без параметров
#                    ^^^^^^^^^^^^           ^^^^^^^^^^^^^^
Execute -- выполнить одно выражение с параметарми
#                    ^^^^           ^^^^^^^^^^^^^

Query
-----

conn.query(...)

 -> Query            select * from users where email ilike 'gmail.com'
<-  RowDescription   id(int), email(text), age(int)
<-  DataRow          1, kek@gmail.com, 42
<-  DataRow          2, lol@gmail.com, 23
<-  DataRow          3, foo@gmail.com, 88
<-  CommandComplete  SELECT 3
<-  ReadyForQuery    I

- работает давно
- данные в текстовом виде (чуть позже)
- несколько выражений в одном запросе

~~~sql
select * from users where email ilike 'gmail.com';
select * from orders where sku = 'ABC-123';
~~~

 -> Query               .......

<-  RowDescription      id(int), email(text), age(int)
<-  DataRow
<-  DataRow
<-  DataRow
<-  CommandComplete     SELECT 3

<-  RowDescription      sku(text), title(text), created_at(timestamp)
<-  DataRow
<-  DataRow
<-  DataRow
<-  CommandComplete     SELECT 42

<-  ReadyForQuery    I

Exploits of a Mom
https://xkcd.com/327/


"select * from students where name = '" + $user + "'"

"select * from students where name = '" + "ivan" + "'"

select * from students where name = 'ivan'

Robert'; drop table students;--

select * from students where name = 'Robert'; drop table students;--'

1. select * from students where name = 'Robert';
2. drop table students;
3. --'

=====================
NEVER: str, format, +
=====================

Execute
-------

conn.execute(...)

Расширенный протокол: выполнить с параметрами

Execute = Parse + Describe + Bind + Execute + Sync + Flush + Close

 -> Parse                 select * from users where name = $1, ps1
<-  ParseComplete
<-  Describe              ps1
<-  ParameterDescription  (text)
 -> Bind                  "Robert", prt1
<-  BindComplete
 -> Execute               prt1, 100
 -> Sync
 -> Flush

<-  RowDescription
<-  DataRow
<-  DataRow
    ...
<-  CommandComplete       SELECT 100
<-  ReadyForQuery         I

 -> Close                 prt01
 -> Close                 ps1
 -> Sync
 -> Flush
<-  CloseComplete
<-  CloseComplete
<-  ReadyForQuery         I

  Итого
# ^^^^^

- 8-10 сообщений до того, как получили данные
- только один запрос
- безопасно в плане инъекций (кавычки, дефисы)
- кэш подготовленных выражений!

JDBC - скрытый кэш

{SQL -> PSid}

{select * from users where name = $1  -> ps5131}

parse, describe ...

bind(ps5131 + Ivan)
bind(ps5131 + Huan)


  Query подходит для миграций и DDL
# ^^^^^

~~~sql
# V001_initial.sql

create table users (....);

create index ...

create enum color as (red, blue, green)
~~~

(pg/query conn (slurp "V001_initial.sql"))

  Execute -- для чтения и записи таблиц
# ^^^^^^^


Text vs Binary format
---------------------

- Postgres передает данные в двух форматах
- Выбирает клиент
- с точностью до поля

Что это значит -- таблица TODO с типами TXT/BIN

- когда малые значения -- расход трафика
- когда большие значения -- экономия трафика

- бинарный формат: удобней парсить (нет вариативности)

примеры (массив, даты)

PG EPOCH OFFSET

строки с null-окончанием, неудобно парсить

примеры с датами, форматы
numeric type (ссылка на JDBC)
нагромождение кода





Заказ формата
-----------

Bind: передать параметры запросу

-> select * from users where name = $1 and age = $2
<- ps1


  Bind ps1, ivan, 66
# ^^^^

~~~
[F][PAYLOAD][F][PAYLOAD]
|----------||----------|
    ivan         66
~~~


Text params
~~~
1 4 ivan   1 2 66
~~~

Binary params

~~~
0 4 ivan   0 4 0 0 0 66
~~~


Columns

0
1
0 1 1 ...
│ │ │
│ │ └─ age
│ └─ email
└─ id

  RowDescription
# ^^^^^^^^^^^^^^

id    int4  0
email text  1
age   int4  1

              id  email  age
 <- DataRow   bin text   text
 <- DataRow   bin text   text
 <- DataRow   bin text   text

(как правило -- все сразу)

node-pg только текст

опции PG
{
 :binary-encode? false
 :binary-decode? false
}

## (Де)кодирование

- записать         txt
              x
- прочитать        bin


int4
----

|        | txt                    | bin         |
|--------|------------------------|-------------|
| decode | Integer.parseInteger() | bb.getInt() |
| encode | Integer.toString()     | bb.putInt() |


float4
------

|        | txt                | bin           |
|--------|--------------------|---------------|
| decode | Float.parseFLoat() | bb.getFloat() |
| encode | Float.toString()   | bb.putFloat() |


тип -> 4 операции

int2, int4, int8, float4, float8, bool, text...

  сложные типы -- коллекция примитивов
# ^^^^^^^^^^^^

polygon ((1.0,2.0),(3.0,4.0),(5.3,6.2))

[N, double1, double2, double3, double4...]


[1 0 0 0 2 63 -16 0 0 0 0 0 0 64 0 0 0 0 0 0 0 64 8 0 0 0 0 0 0 64 16 0 0 0 0 0 0]

wtf?

[1                    bool    closed?
 0 0 0 2              int     N of points
 63 -16 0 0 0 0 0 0   double  x1
 64   0 0 0 0 0 0 0   double  y1
 64   8 0 0 0 0 0 0   double  x2
 64  16 0 0 0 0 0 0   double  y2
 ]

Если непонятно?

- смотреть исходник
- pg_type

~~~sql
select
    oid, typname, typinput, typoutput, typreceive, typsend
from
    pg_type
where
    oid = 25
~~~

-[ RECORD 1 ]--------
oid        | 25
typname    | text
typinput   | textin
typoutput  | textout
typreceive | textrecv
typsend    | textsend

pg-vector

sparsevec_send

https://github.com/pgvector/pgvector/blob/5bc7937715c67add21c8bcc0d4284162c7a0174f/src/sparsevec.c#L546


* Сопоставление типов *
-----------------------

- таблица pg_types
- откуда?

посевочный файл
https://raw.githubusercontent.com/postgres/postgres/master/src/include/catalog/pg_type.dat

парсер и генератор
https://github.com/igrishaev/pg/blob/6146b4f32f04e6d48f0ea47acb58366ba66991f2/pg-common/tasks/fetch_oids.clj

результат
https://github.com/igrishaev/pg/blob/6146b4f32f04e6d48f0ea47acb58366ba66991f2/pg-common/src/pg/oid.clj

тип pg -- это oid

pg
int4, int2, text, bool, float4, ....
23    21    25    16    700


java
Integer, Long, String, Float, ...

# примитивы

int4   <--->  Integer
int8   <--->  Long
text   <--->  String
bool   <--->  Boolean

# расширенные

                ???
                java.sql.Timestamp? :(

timestamptz     java.time.OffsetDateTime
timestamp       java.time.LocalDateTime
time            java.time.Time
timetz          java.time.OffsetTime
date            java.time.LocalDate

# сложные

json            ?
hstore          ?
polygon         ?
line            ?


json --> {}
{} --> json ?

hstore --> ?
? --> hstore?

polygon --> []
[] --> polygon?

int4[] <-- [1 2 3]

1. маппинг -- это сложно
---------------------


2. расширяемость
----------------

<- RowDescription id(int4), email(text), created_at(timestamptz)

switch oid {
    case int4: parseInt(payload);
    case text: parseText(payload);
    case timestamptz: parseTimestamp(payload);
    ...
}

проблемы:
- нерасширяемость
- свои типы

расширения, которые создают типы
- hstore
- pg_vector
- postgis

OID случайный!

Свои типы:

  CREATE TYPE triple AS (id int4, email text, created_at timestamp);
# ^^^^^^^^^^^               ^^^^        ^^^^             ^^^^^^^^^

CREATE TABLE test (id int, data triple);

INSERT INTO test (id, data) VALUES (1, '(100,test@test.com,2024-12-03 12:15:54.987685+03)');

SELECT * from test;

-[ RECORD 1 ]------------------------------------------
id   | 1
data | (100,test@test.com,"2024-12-03 12:15:54.987685")


select * from pg_type where typname = 'triple';


-[ RECORD 1 ]--+------------
oid            | 24587
typname        | triple
#                ^^^^^^
typnamespace   | 2200
typowner       | 16384
typlen         | -1
...

неправильно (один к одному):
-
oid -> java
java -> oid


правильно (пары):
-

[oid, java] -> encode

[jsonb map]     -> json.encode(...)
[jsonb vector]  -> json.encode(...)
[jsonb bool]    -> json.encode(...)
[jsonb nil]     -> nil
[jsonb string]  -> string

[jsonb [1 2 3]]      -> "[1, 2 ,3]"
[jsonb false]        -> false
[jsonb nil]          -> nil
[jsonb "[1, 2, 3]"]  -> "[1, 2, 3]"


[hstore map]     -> Hstore.fromMap(x).toSQL()
[hstore string]  -> string

[point {:x 1 :y 2}] -> (1, 2)
[point [1 2]]       -> (1, 2)

TypeProcessors
--


Вот что получилось:


~~~
                                                         methods
                                                    ┌────────────────┐
                                                    │    fromMap     │
                                                    ├────────────────┤
                            TypeProcessor           │    fromList    │
      PG OID              ┌────────────────┐    ┌──▶├────────────────┤
┌────────────────┐        │   encodeBin    │────┘   │   fromString   │
│      int4      │        ├────────────────┤        ├────────────────┤
├────────────────┤        │   encodeTxt    │────┐   │      ...       │
│      int8      │───────▶├────────────────┤    │   └────────────────┘
├────────────────┤        │   decodeBin    │    │
│      text      │        ├────────────────┤    │
└────────────────┘        │   decodeTxt    │    │   ┌────────────────┐
                          └────────────────┘    │   │    fromMap     │
                                                │   ├────────────────┤
                                                │   │    fromList    │
                                                └───▶────────────────┤
                                                    │   fromString   │
                                                    ├────────────────┤
                                                    │      ...       │
                                                    └────────────────┘
~~~

- сложно, громоздко
+ можно передать свои типы

10234  ->  PGVectorProcessor

pgvector -> типы по запросу

oid? 1001, 100123, 514123

{:type-map {"public.vector" Processor}}

{:type-map {:public/vector VectorProcessor
            :public/sparsevec SparseVectorProcessor}}


~~~sql
select pg_type.oid, pg_namespace.nspname || '.' || pg_type.typname as type
from pg_type, pg_namespace
where
    pg_type.typnamespace = pg_namespace.oid
and pg_namespace.nspname || '.' || pg_type.typname in (
  'public.vector', 'public.sparsevec'
)
~~~

123151 | public.vector
123153 | public.sparsevec



{:public/vector VectorProcessor
 :public/sparsevec SparseVectorProcessor}

+

{public.vector 123151
 public.sparsevec 123153}

=

{123151 VectorProcessor
 123153 SparseVectorProcessor}


Зачем схема?

# Enums

create schema foo;
create schema bar;

create type foo.color as enum (red, green blue);
create type bar.color as enum (C, M, Y, K);

foo.color = 51233
bar.color = 13139


{:enums [foo.color, bar.color]}

->

{foo.color -> EnumProcessor
 bar.color -> EnumProcessor}


Парсинг
-------

 -> Query            select * from users where email ilike 'gmail.com'
<-  RowDescription   id(int), email(text), age(int)
<-  DataRow          1, kek@gmail.com, 42
<-  DataRow          2, lol@gmail.com, 23
<-  DataRow          3, foo@gmail.com, 88
<-  CommandComplete  SELECT 3
<-  ReadyForQuery    I


RowDescription

┌─────┬──────────┬───────┬───────┬─────────┬────────────┬─────────┬─────────┬─────────┬─────────┐
│  T  │  length  │ N-col │ name  │table OID│ column OID │type OID │type size│type mod │ format  │
└─────┴──────────┴───────┼───────┴─────────┴────────────┴─────────┴─────────┴─────────┴─────────┘
                                                         field 1                                │
                         └ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─
                         ┌───────┬─────────┬────────────┬─────────┬─────────┬─────────┬─────────┐
                         │ name  │table OID│ column OID │type OID │type size│type mod │ format  │
                         ├───────┴─────────┴────────────┴─────────┴─────────┴─────────┴─────────┘
                                                         field 2                                │
                         └ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─


format: 0=bin, 1=txt


DataRow

┌─────┬──────────┬───────┬───────┬─────────┬───────┬─────────┬───────┐
│  B  │  length  │ N-col │  len  │  bytes  │  len  │  bytes  │  ...  │
└─────┴──────────┴───────┼───────┴─────────┼───────┴─────────┼───────┘
                               field 1           field 2
                         └ ─ ─ ─ ─ ─ ─ ─ ─ ┴ ─ ─ ─ ─ ─ ─ ─ ─ ┘



RowDescription
id    ... ... 21 0 email ... ... 25 0

DataRow
 2 4 2
16 i v a n @ g r i s h a e v . m e


распарсить в
[{:id 42 :email "ivan@grishaev.me"}
 {:id 99 :email "test@foobarxx.ru"}]


~~~java
RowDescription rd = conn.readRowDescription();
List<?> result = new ArrayList();

while (has_more) {
    row = conn.readDataRow()
    map = parseDataRow(rd, row)
    result.add(map)
}
~~~

медленно
--

- не все поля нужны

~~~clojure
select * from users where ...

(println (:id user) (:email user))
~~~

- задерживаем соединение


clojure.java.jdbc: result-set-seq
https://github.com/clojure/java.jdbc/blob/master/src/main/clojure/clojure/java/jdbc.clj#L545


ленивый парсинг
-

- забрать все сразу
- не парсить
- парсить по запросу

next.jdbc: mapify
https://github.com/seancorfield/next-jdbc/blob/develop/src/next/jdbc/result_set.clj#L479


reify (ResultSet)
  clojure.lang.Counted
  clojure.lang.IPersistentCollection
  clojure.lang.ILookup
  clojure.lang.Indexed


pg2
--

PG2: RowMap class
https://github.com/igrishaev/pg2/blob/master/pg-core/src/java/org/pg/clojure/RowMap.java

class RowMap extends APersistentMap {

    RowDescription
    DataRow
    {i -> keyName}
    ToC [0 [ 0 6]
         1 [ 7 18]
         2 [19 52]
         ... ]
    cache: {i -> value}


    assoc -> parse all and return a real map

}


  (get my-row 2)
# ^^^^^^^^^^^^^^

2 -> ToC -> [19 52]

DataRow [19 52] -> byte-array[...]

RowDescription -> 2 -> OID -> text (25)
RowDescription -> 2 -> format -> 1 (binary)


TypeMapping -> 25 -> TypeProcessor

TypeProcessor -> decodeTxt
              -> decodeBin(byte-array)

=> test@test.com

set cache: {2 -> test@test.com}

  (get my-row :email)
# ^^^^^^^^^^^^^^^^^^^

:email -> {:email -> 2} -> 2

GOTO (get my-row 2)





class RowMap extends APersistentMap {
     ┌───────────┬─────┬───────────┬────────────────┐
     │           │     │███████████│                │
     └───────────┴─────┴───────────┴────────────────┘
      0           1     2           3
}





Performance parse vs lazy parse
===========

lazy read:
https://grishaev.me/assets/static/aws/pg2-bench-3/02.svg


full eval read
https://grishaev.me/assets/static/aws/pg2-bench-3/08.svg


стратегия:
- все забрать
- обработать

~~~clojure
(with-conn [conn pool]
  (let [users
        (pg/execute conn "select users ...")

        orders
        (pg/execute conn "select orders ...")]

    (process-business-logic users orders)))
~~~


~~~clojure
(let [users
      (with-conn [conn pool]
        (pg/execute conn "select users ..."))

      orders
      (with-conn [conn pool]
        (pg/execute conn "select orders ..."))]

  (process-business-logic users orders))
~~~

Free connections!
==



Редьюсеры
===

- выбрать всех пользователей
[{:id 1}, {:id 2}]

- сгруппировать по id
{1 {:id 1, :email...}
 2 {:id 2, :email...}}

- приклеить куда-то

(for [id ...]
  (let [user (get id->user id)]
    ...))

CSV <- users

- O(N) выборка
- O(N) индекс

= O(2N)

модификации за O(N)
--

next.jdbc: plan:

(jdbc/plan conn ...) -> IReduceInit

~~~clojure
(let [reducible (jdbc/plan conn "...")]
  (reduce
   (fn [acc row]
     ...)
   []
   reducible))
~~~

pg2: folders

ns pg.fold:

- index-by   :id
- group-by   (-> email getDomain)

TODO пример

gmail.com -> [user1, user2]
mail.ru -> [user3, user4]

- map         any func
- key-value   {(fn-key row) -> (fn-val row)}
- reduce


- columns [id, age]

{:id 1 :email "test@test.com" :age 42}

[[1 42]
 [2 53]
 ...
]

to-edn
to-json

run
into/xform

TODO пример

TODO алиасы

~~~clojure
(fn
  ([])        -> acc
  ([acc row]) -> acc
  ([acc])     -> finalize
  )

;; default
(fn
  ([])        -> (transient [])
  ([acc row]) -> (conj! acc row)
  ([acc])     -> (persistent acc)
  )
~~~

Copy
==

- JDBC: только InputStream (в CSV сам)
- вставка из словарей
- map -> CSV row -> COPY
- бинарый формат COPY ... WITH FORMAT BIN
- по одной записи
- быстрее

Контриб
==

- pg-component
- pg-honeysql
- pg-hugsql
- pg-migration

- pgvector
- JSONb
- geometry

планирую
- postgis

удобный SSL


КОНЕЦ
=====












┌─────┬──────────┬───────────────────────────────────────┐
│ tag │  length  │             byte payload              │
└─────┴──────────┴───────────────────────────────────────┘


┌─────┬─────────────┬───────────────────────────────────────┐
│ Q   │  4 + 31 + 1 │ select from users where id = 42\0     │
└─────┴─────────────┴───────────────────────────────────────┘


 -> StartupMessage
 <- AuthenticationMessage
 ...


# Text Vs Binary

Query: text only
Execute: both text and binary


node-postgres: text only
https://www.npmjs.com/package/pg




| Type     | Text                | Binary                            |
|----------|---------------------|-----------------------------------|
| Byte     | 1                   | [49]                              |
| Integer  | 1                   | [0, 0, 0, 1]                      |
| Long     | 1                   | [0, 0, 0, 0, 0, 0, 0, 1]          |
| Long MAX | 9223372036854775807 | [127, -1, -1, -1, -1, -1, -1, -1] |
|          |                     |                                   |

~~~clojure
(count (str 9223372036854775807))
19
~~~

~~~clojure
(-> (java.nio.ByteBuffer/allocate 8) (.putLong Long/MAX_VALUE) (.array))
[127, -1, -1, -1, -1, -1, -1, -1]
~~~


Text



# Парсинг

-> Query                select id, email, created_at from users
<- RowDescription       [(name id, type int...), (name email, type text...), (name created-at, type timestamptz...)]
<- DataRow              [1, test@test.com, 2023-04-13]
<- DataRow              [2, ivan@acme.com, 2022-03-13]
<- DataRow              [3, jora@kyky.com, 2021-12-30]
<- CommandComplete      SELECT 3
<- ReadyForQuery        .


(state machine)


55.7. Форматы сообщений
https://postgrespro.ru/docs/postgresql/15/protocol-message-formats

RowDescription

┌─────┬──────────┬───────┬───────┬─────────┬────────────┬─────────┬─────────┬─────────┬─────────┐
│  T  │  length  │ N-col │ name  │table OID│ column OID │type OID │type size│type mod │ format  │
└─────┴──────────┴───────┼───────┴─────────┴────────────┴─────────┴─────────┴─────────┴─────────┘
                                                         field 1                                │
                         └ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─
                         ┌───────┬─────────┬────────────┬─────────┬─────────┬─────────┬─────────┐
                         │ name  │table OID│ column OID │type OID │type size│type mod │ format  │
                         ├───────┴─────────┴────────────┴─────────┴─────────┴─────────┴─────────┘
                                                         field 2                                │
                         └ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─


format: 0=bin, 1=txt




DataRow

┌─────┬──────────┬───────┬───────┬─────────┬───────┬─────────┬───────┐
│  B  │  length  │ N-col │  len  │  bytes  │  len  │  bytes  │  ...  │
└─────┴──────────┴───────┼───────┴─────────┼───────┴─────────┼───────┘
                               field 1           field 2
                         └ ─ ─ ─ ─ ─ ─ ─ ─ ┴ ─ ─ ─ ─ ─ ─ ─ ─ ┘


# Множественные выражения

-> Query                select * from users; select * from orders;

<- RowDescription       [(name id, type int...), (name email, type text...), ...]
<- DataRow              [1, test@test.com, 2023-04-13]
<- DataRow              [2, ivan@acme.com, 2022-03-13]
<- DataRow              [3, jora@kyky.com, 2021-12-30]
<- CommandComplete      SELECT 3

<- RowDescription       [(name sku, type text...), (name user_id, type int...), ...]
<- DataRow              [XAG-123, 1001]
<- DataRow              [URG-553, 2021]
<- CommandComplete      SELECT 2

<- ReadyForQuery        .

~~~clojure
(pg/query conn "select * from users; select * from orders;")

[[{:id 1 :email "test@test.com"}
  {:id 2 :email "ivan@acme.com"}
  ...]
 [{:sku "XAG-123" :user-id 1001}
  {:sku "URG-553" :user-id 2021}
  ...
 ]]
~~~

А если ошибка?

-> Query                select * from users; select * from orders;

<- ErrorResponse        permission to table users denied...

<- RowDescription       [(name sku, type text...), (name user_id, type int...), ...]
<- DataRow              [XAG-123, 1001]
<- DataRow              [URG-553, 2021]
<- CommandComplete      SELECT 2

<- ReadyForQuery        .


## Протокол
##
##
##
##
##
##



Table of Content

PG2
- pg(one)
-


зачем?
- интересно
-
