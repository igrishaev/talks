
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


## Кто пользуется?

XTDB для тестов Wire Protocol (позже)
https://github.com/xtdb/xtdb/pull/3857


Sync data from any Postgres DB to another
https://schemamap.io/

и другие (но мало)

сам -- нет, но надеюсь


## О чем презентация














# PG2: A Fast PostgreSQL Driver For Clojure

https://github.com/igrishaev/pg2

https://github.com/igrishaev/pg


PG(one) на Clojure

# Драйвер или клиент?

 ┌────┐    ┌───────────┐    ┌─────┐
 │ Да │    │           │    │ Нет │
 └────┼────│   JDBC?   │────┼─────┘
      │    │           │    │
      │    └───────────┘    │
      ▼                     ▼
┌───────────┐         ┌───────────┐
│           │         │           │
│  Драйвер  │         │  Клиент   │
│           │         │           │
└───────────┘         └───────────┘


# О чем

 специфика (дата-время)
 сам -- нет (но надеюсь)

- Postgres Wire Protocol
- зачем (JDBC, next.jdbc)
- парсинг
- типы
- API и дизайн


Postgres Wire Protocol

Глава 55. Клиент-серверный протокол
https://postgrespro.ru/docs/postgresql/15/protocol




Общие сведения





Postgres Wire Protocol

Глава 55. Клиент-серверный протокол
https://postgrespro.ru/docs/postgresql/15/protocol




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
