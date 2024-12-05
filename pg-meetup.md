
# PG2

https://github.com/igrishaev/pg2

# Общие сведения

- наследник PG(one) https://github.com/igrishaev/pg
- c 2022
- на Clojure
- медленно (2-3 раза)
- на Java быстрее

- что значит быстрее?
- не быстрее PG JDBC, но быстрее next.jdbc

next.jdbc = Java JDBC + pgjdbc + Clojure API
https://github.com/pgjdbc/pgjdbc

быстрее кложурной обвязки


# Драйвер или клиент?

- драйвер: для JDBC

JDBC -- абстрактный API

- Python PEP 249 – Python Database API Specification v2.0
- клиент: когда свое (pg2)




## Кто пользуется?

Clojars: 7500 загрузок

XTDB для тестов Wire Protocol (позже)
https://github.com/xtdb/xtdb/pull/3857/files


Sync data from any Postgres DB to another
https://schemamap.io/

и другие (но мало)

  сам -- нет, но надеюсь
# ^^^^^^^^^^









## О чем презентация

- Demo
- Postgres Wire Protocol
- зачем браться за свое решение
- парсинг текстовых и бинарных данных
- сопоставление типов
- дизайн и API




## Demo time!

TODO demo

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

1. подключаемся к сокету 127.0.0.1:5432
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
- конечный автомат

Query

┌─────┬──────────┬───────────────────────────────────────┐
│ Q   │ 0 0 0 33 │ select * from users where id = 1\0    │
└─────┴──────────┴───────────────────────────────────────┘


~~~java
InputStream in = socket.getInputStream()

byte tag = in.read()
int len = in.readInt()
byte[] buf = new byte[len]

in.read(buf)

pair = [tag buf]

switch tag {
  case 'S' -> parseThis()
  case 'R' -> parseThat()
  case 'd' -> parseMore()
  default: throw "msg not supported"
}
~~~

Connection.java switch
https://github.com/igrishaev/pg2/blob/master/pg-core/src/java/org/pg/Connection.java#L497


Для парсинга `java.nio.Bytebuffer`
- забирать все

- типов сообщений много

## Первичный обмен сообщениями (Startup)

~~~clojure
 <- StartupMessage[protocolVersion=196608, user=test, database=test, options={application_name=pg2, client_encoding=UTF8}]

 -> AuthenticationSASL[SASLTypes=[SCRAM_SHA_256]]
 <- SASLInitialResponse[saslType=SCRAM_SHA_256, clientFirstMessage=n,,n=test,r=81f91ead-f29d-452c-a927-d9f53bd75e4c]
 -> AuthenticationSASLContinue[serverFirstMessage=r=81f91ead-f29d-452c-a927-d9f53bd75e4cF8nnFdUr+KnDOLmcN5/LMeYk,s=xUjJk01c+u6AorZaFYvm2A==,i=4096]
 <- SASLResponse[clientFinalMessage=c=biws,r=81f91ead-f29d-452c-a927-d9f53bd75e4cF8nnFdUr+KnDOLmcN5/LMeYk,p=5nWW0Ze1GBl9EIL3F1aV9EZnOaSvrywE5JSqqr31tfw=]
 -> AuthenticationSASLFinal[serverFinalMessage=v=JCxEPArBiwMWSWu9O47KsPF6zYIjoz7j/2hZbdZQwOM=]
 -> AuthenticationOk[]

 -> ParameterStatus[param=application_name, value=pg2]
 -> ParameterStatus[param=client_encoding, value=UTF8]
 -> ParameterStatus[param=DateStyle, value=ISO, MDY]
 -> ParameterStatus[param=default_transaction_read_only, value=off]
 -> ParameterStatus[param=in_hot_standby, value=off]
 -> ParameterStatus[param=integer_datetimes, value=on]
 -> ParameterStatus[param=IntervalStyle, value=postgres]
 -> ParameterStatus[param=is_superuser, value=on]
 -> ParameterStatus[param=server_encoding, value=UTF8]
 -> ParameterStatus[param=server_version, value=14.13 (Debian 14.13-1.pgdg110+1)]
 -> ParameterStatus[param=session_authorization, value=test]
 -> ParameterStatus[param=standard_conforming_strings, value=on]
 -> ParameterStatus[param=TimeZone, value=Etc/UTC]

 -> BackendKeyData[pid=78, secretKey=2142925098]

 -> ReadyForQuery[txStatus=IDLE]
~~~

- Startup phase is slow (новое соединение на каждый запрос)
- Auth Scram SHA: 4096 XOR-итераций (с версии 15)

## Дальнейший обмен сообщениями

~~~
 <- Query[query=select * from users]
 -> RowDescription[columnCount=11, columns=[Column[index=0, name=int4, tableOid=0, columnOid=0, typeOid=23, typeLen=4, typeMod=-1, format=TXT],
                                            Column[index=1, name=int8, tableOid=0, columnOid=0, typeOid=20, typeLen=8, typeMod=-1, format=TXT],
                                            ...
 -> DataRow[count=11, buf=java.nio.HeapByteBuffer[pos=2 lim=166 cap=166]]
 -> DataRow[count=11, buf=java.nio.HeapByteBuffer[pos=2 lim=166 cap=166]]
 -> CommandComplete[command=SELECT 2]
 -> ReadyForQuery[txStatus=IDLE]
~~~

конечный автомат:
- запомнить RowDescription
- распарсить DataRow -> {}
- сложить в список
- CommandComplete - вернуть список


Итого
- простой, понятный протокол
- своего рода стандарт
- бинарый обмен данными (образец)
- TCP клиент-сервер





## Зачем?

- интересно
# ^^^^^^^^^
- задействовать Postgres по максимуму
- JDBC -- общий знаменатель (угодить всем)

1. jsonb          - (PGObject)
2. COPY API       CopyManager
3. Date & Time    java.sql.Timestamp (java.util.Date deprecated 1.1)
4. SSL            keystore
5. Listen/Notify  -

Хочу:

1. JSON           да
2. COPY API       functions
3. Date & Time    java.time.*
4. SSL            параметр
5. Listen/Notify  PubSub

+ не настраивать это в каждом проекте




## Дизайн и API

- подумать о дизайне
- решение задач
- где API лучше









## Другие библиотеки

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

psycopg .query() .execute()

  Query -- выполнить одно и более выражений без параметров
#                    ^^^^^^^^^^^^           ^^^^^^^^^^^^^^
Execute -- выполнить одно выражение с параметарми
#                    ^^^^           ^^^^^^^^^^^^^

Query
-----

conn.query(...)

 -> Query            select * from users where email ilike '%@gmail.com'
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
select * from orders where sku = 'ABC-123'
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

conn.execute() = Parse + Describe + Bind + Execute + Sync + Flush + Close

 -> Parse                 select * from users where name = $1, stmt1
<-  ParseComplete
<-  Describe              stmt1
<-  ParameterDescription  (text)
 -> Bind                  stmt1, "Robert", portal1
<-  BindComplete
 -> Execute               portal1, 100
 -> Sync
 -> Flush

<-  RowDescription
<-  DataRow
<-  DataRow
    ...
<-  CommandComplete       SELECT 100
<-  ReadyForQuery         I

 -> Close                 portal1
 -> Close                 stmt1
 -> Sync
 -> Flush
<-  CloseComplete
<-  CloseComplete
<-  ReadyForQuery         I

  Итого
# ^^^^^

- 8-10 сообщений до того, как получили данные
- execute только один запрос
- безопасно в плане инъекций (кавычки, дефисы)
- кэш подготовленных выражений!

JDBC - скрытый кэш

{SQL -> PS}

{select * from users where name = $1 -> ps5131}

DISCARD ALL



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



Заказ формата
-----------

Bind: передать параметры запросу

-> select * from users where name = $1 and age = $2
<- ps1


  Bind ps1, [ivan, 66]
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

как правило -- все сразу

node-pg только текст

опции PG2
{
 :binary-encode? false
 :binary-decode? false
}



Parse Text vs Binary
---

Легче?

- 12345              0, 0, 48, 57
- 14.23452           64, 44, 120, 19, 0, 0, 0, 0
- false              0
- hello              104, 101, 108, 108, 111
- null               -1, -1, -1, -1

Короче?

- когда малые значения -- расход трафика
- когда большие значения -- экономия трафика

| Type     | Text                | Binary                            |
|----------|---------------------|-----------------------------------|
| Byte     | 1                   | [49]                              |
| Integer  | 1                   | [0, 0, 0, 1]                      |
| Long     | 1                   | [0, 0, 0, 0, 0, 0, 0, 1]          |
| Long MAX | 9223372036854775807 | [127, -1, -1, -1, -1, -1, -1, -1] |
#            36 bytes              8 bytes
             4.5 times >

datetime

2023-07-10 22:25:22.046553+03
2023-07-10T22:25:22.046553+03:00
2023-07-10 22:25:22.046553
2022-07-03T00:00+03:00
2023-01-01 00:00:00Z

10:29:39.853741+03:00
10:29:39+03


[.[SSSSSS][SSSSS][SSSS][SSS][SS][S]][[XXX][XX][X]]

    static {
        frmt_decode_timestamptz = new DateTimeFormatterBuilder()
                .appendPattern("yyyy-MM-dd HH:mm:ss" + patternMsTz)
                .toFormatter()
                .withZone(ZoneOffset.UTC);

see DateTimeTxt.java
    ^^^^^^^^^^^^^^^^

{null,"foo\"bar","C:\\windows"}

[nil "foo\"bar" "C:\\windows"]

null != "null"

arrays:

{{{a,b},{c,d}},{{e,f},{g,h}}}

[[["a" "b"] ["c" "d"]]
 [["e" "f"] ["g" "h"]]]

bin:

   [0,  0,  0,  2,  ;; dims
    0,  0,  0,  1,  ;; nulls true
    0,  0,  0,  23, ;; oid
    0,  0,  0,  2,  ;; dim1 = 2
    0,  0,  0,  1,  ;; ?
    0,  0,  0,  3,  ;; dim2 = 3
    0,  0,  0,  1,  ;; ?
    0,  0,  0,  4,  ;; len
    0,  0,  0,  1,  ;; 1
    0,  0,  0,  4,  ;; len
    0,  0,  0,  2,  ;; 2
    0,  0,  0,  4,  ;; len
    0,  0,  0,  3,  ;; 3
    0,  0,  0,  4,  ;; len
    0,  0,  0,  4,  ;; 4
   -1, -1, -1, -1,  ;; null
    0,  0,  0,  4,  ;; len = 4
    0,  0,  0,  6   ;; 6
    ]

нет вариативности

Даты:

2022-01-01 12:01:59.123456789+03

[0 2 119 -128 79 11 -14 1]

(-> [0 2 119 -128 79 11 -14 1]
    (byte-array)
    (java.nio.ByteBuffer/wrap )
    (.getLong))

  694342919123457
#          ^^^^^^

/ 1.000.000

694342919.123457

694342919 sec + PG offset
   123457 microsec

123457 * 1000 = 123457000 nanosec

duration b/w 1970-01-01 and 2000-01-01
= 946684800 seconds

694342919 + 946684800 = 1641027719

1641027719 sec
 123457000 nanosec


Instant.ofEpochSecond(sec, nanoSec)
2022-01-01 12:01:59.123457Z







## (Де)кодирование

- отправить        txt
              x
- получить         bin


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

path ((1.0,2.0),(3.0,4.0))

simple Gis (path, line, polygon, box)

[1 0 0 0 2 63 -16 0 0 0 0 0 0 64 0 0 0 0 0 0 0 64 8 0 0 0 0 0 0 64 16 0 0 0 0 0 0]

wtf?
===

[closed?, N, double1, double2, double3, double4...]

[1                    bool    closed?
 0 0 0 2              int     N of points
 63 -16 0 0 0 0 0 0   double  x1
 64   0 0 0 0 0 0 0   double  y1
 64   8 0 0 0 0 0 0   double  x2
 64  16 0 0 0 0 0 0   double  y2
 ]

Если непонятно?

- pg_type
- смотреть исходник

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

pgvector

sparsevec

sparsevec_send

https://github.com/pgvector/pgvector/blob/5bc7937715c67add21c8bcc0d4284162c7a0174f/src/sparsevec.c#L546






** Сопоставление типов **
-------------------------

int4     Integer
int8     Long
text     String
bool     Boolean


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

jsonb           ?
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

[oid, java]     -> encode

[jsonb map]     -> json.encode(...)
[jsonb vector]  -> json.encode(...)
[jsonb bool]    -> json.encode(...)
[jsonb nil]     -> "null" -> nil
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

oid -> PGVectorProcessor

но какой oid?
pgvector создает свои типы

   prod 1001
staging 100123
 docker 514123

{"public.vector" Processor}

{:public/vector VectorProcessor
 :public/sparsevec SparseVectorProcessor}


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
----




# Enums

create schema foo;
create schema bar;

create type foo.color as enum (R, G, B);
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
 2  4 2
16  i v a n @ g r i s h a e v . m e

~~~java
RowDescription rd = conn.readRowDescription();
List<?> result = new ArrayList();

while (has_more) {
    row = conn.readDataRow()
    map = parseDataRow(rd, row)
    result.add(map)
}
~~~

[{:id 42, :email "ivan@grishaev.me", :name, :created_at, :gender:, ...}
 ...]

1. медленно
--

- не все поля нужны

~~~clojure
select * from users where ...

(println (:id user) (:email user))
~~~

2. задерживаем соединение
--


<- DataRow
<- DataRow
<- DataRow
...


<- DataRow
   parse + process...
<- DataRow
   parse + process...
<- DataRow
   parse + process...
<- DataRow



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
    ToC
    cache: {i -> value}

}


ToC

|   | start | end |
|---|-------|-----|
| 0 | 0     | 6   |
| 1 | 7     | 18  |
| 2 | 19    | 52  |
| 3 | 52    | ... |


  (get my-row 2)
# ^^^^^^^^^^^^^^

2 -> ToC -> [19 52]

DataRow [19 52] -> byte-array[...]

RowDescription -> 2 -> OID    = text (25)
RowDescription -> 2 -> format = 1 (binary)

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

listen/notify


КОНЕЦ
=====
