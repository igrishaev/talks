

PostgreSQL как документная база данных
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
















SQL: tables & relations

table -> ? -> table


 id       title       name           select id, name        where id in (10, 20)

┌────┬─────────────┬──────────┐      ┌────┬──────────┐     ┌ ─ ─┌ ─ ─ ─ ─ ─
│    │             │          │      │    │          │          │          │
├────┼─────────────┼──────────┤      ├────┼──────────┤     ├ ─ ─├ ─ ─ ─ ─ ─
│    │             │          │      │    │          │          │          │
├────┼─────────────┼──────────┤      ├────┼──────────┤     ├────┼──────────┐    ┌────┬──────────┐
│    │             │          │      │    │          │     │    │          │    │    │          │
├────┼─────────────┼──────────┤      ├────┼──────────┤     ├────┼──────────┤    ├────┼──────────┤
│    │             │          │      │    │          │     │    │          │    │    │          │
├────┼─────────────┼──────────┤      ├────┼──────────┤     ├────┼──────────┘    └────┴──────────┘
│    │             │          │      │    │          │          │          │
├────┼─────────────┼──────────┤      ├────┼──────────┤     ├ ─ ─├ ─ ─ ─ ─ ─
│    │             │          │      │    │          │          │          │
├────┼─────────────┼──────────┤      ├────┼──────────┤     ├ ─ ─├ ─ ─ ─ ─ ─
│    │             │          │      │    │          │          │          │
├────┼─────────────┼──────────┤      ├────┼──────────┤     ├ ─ ─├ ─ ─ ─ ─ ─
│    │             │          │      │    │          │          │          │
└────┴─────────────┴──────────┘      └────┴──────────┘     └ ─ ─└ ─ ─ ─ ─ ─



table1                           join  table3                join  table3


                                                            ┌ ─ ─┌ ─ ─ ─ ─ ─ ─ ┬ ─ ─ ─ ─ ─
                                                                 │                        │
                                                            ├ ─ ─├ ─ ─ ─ ─ ─ ─ ┼ ─ ─ ─ ─ ─
                                                                 │                        │
┌ ─ ─┌ ─ ─ ─ ─ ─ ─ ┬ ─ ─ ─ ─ ─                              ├ ─ ─├ ─ ─ ─ ─ ─ ─ ┼ ─ ─ ─ ─ ─
     │                        │                                  │                        │
├ ─ ─├ ─ ─ ─ ─ ─ ─ ┼ ─ ─ ─ ─ ─                              ├ ─ ─├ ─ ─ ─ ─ ─ ─ ┼ ─ ─ ─ ─ ─
     │                        │                                  │                        │
├ ─ ─├ ─ ─ ─ ─ ─ ─ ┼ ─ ─ ─ ─ ─                              ├ ─ ─├ ─ ─ ─ ─ ─ ─ ┼ ─ ─ ─ ─ ─
     │                        │                                  │                        │
├ ─ ─├ ─ ─ ─ ─ ─ ─ ┼ ─ ─ ─ ─ ─                              ├ ─ ─├ ─ ─ ─ ─ ─ ─ ┼ ─ ─ ─ ─ ─
     │                        │                                  │                        │
├────┼─────────────┼──────────┬────┬─────────────┬──────────┼────┼─────────────┼──────────┐
│████│█████████████│██████████│████│█████████████│██████████│████│█████████████│██████████│
├────┼─────────────┼──────────┼────┼─────────────┼──────────┼────┼─────────────┼──────────┤
│████│█████████████│██████████│████│█████████████│██████████│████│█████████████│██████████│
├────┼─────────────┼──────────┼────┼─────────────┼──────────┴────┴─────────────┴──────────┘
     │                        │    │                        │
├ ─ ─├ ─ ─ ─ ─ ─ ─ ┼ ─ ─ ─ ─ ─├ ─ ─├ ─ ─ ─ ─ ─ ─ ┼ ─ ─ ─ ─ ─
     │                        │    │                        │
└ ─ ─└ ─ ─ ─ ─ ─ ─ ┴ ─ ─ ─ ─ ─├ ─ ─├ ─ ─ ─ ─ ─ ─ ┼ ─ ─ ─ ─ ─
                                   │                        │
                              ├ ─ ─├ ─ ─ ─ ─ ─ ─ ┼ ─ ─ ─ ─ ─
                                   │                        │
                              ├ ─ ─├ ─ ─ ─ ─ ─ ─ ┼ ─ ─ ─ ─ ─
                                   │                        │
                              ├ ─ ─├ ─ ─ ─ ─ ─ ─ ┼ ─ ─ ─ ─ ─
                                   │                        │
                              └ ─ ─└ ─ ─ ─ ─ ─ ─ ┴ ─ ─ ─ ─ ─







noSQL

- whatever: k->v, documents
- id -> {...}
- 2010s
- mongodb (Node.js), couchdb (Erlang, map/reduce), cassandra (Java, replication)
- AWS: simpledb -> dynamodb, elastic -> opensearch
- tarantool, ydb (comp. with dynamodb)

sql -> noSQL


good
- easy to start (no schema)
- easy API (get by id, get-by-this, CRUD)


select * from users where id = 1
db.getById('users', 1)

update users set name = 'test', age = 30 where id = 1
db.updateAttrs('users', 1, {:name 'test', :age 30})




good -> bad
- no relations: user -> profile
  - select users where profile.open_to_work
- no joins -> need joins
- weak transactions
- pitfalls



cassandra: tombstone < 50K






postgres: json, jsonb


- documents
- query and index them
- subsets
- search (exact/ilike/fuzzy)

- transactions
- join & relation
- extensions, contrib




SQL -> noSQL -> SQL







# зачем json и документы?

- разные типы {:name "Test" :age 45}
- коллекции и вложенность
- наращивание



# примеры


# характеристики товаров


| sku   | title     | description            | category | subcategory |
|-------|-----------|------------------------|----------|-------------|
| 51231 | cap       | Red Abibas Cap         | cloth    | Sport cloth |
| 62344 | tea spoon | Small silver tea spoon | kitchen  | dishes      |



(images)


| sku   | property           | value     |
|-------|--------------------|-----------|
| 83453 | display.freq       | 60        |
| 83453 | display.diag       | 15.5      |
| 83453 | memory.freq        | 2666      |
| 83453 | core.label         | Kaby Lake |
| 83453 | display.freq       | 60        |
| 83453 | bluetooth.support  | true      |
| 83453 | bluetooth.versions | [4, 5, 6] |

                             ^^^^^^^^^^^^^



 SKU      PROPS (jsonb)

 83453  {
            display.freq       60
            display.diag       15.5
            memory.freq        2666
            core.label         "Kaby Lake"
            display.freq       60
            bluetooth.support  true
            bluetooth.versions [4 5 6]
        }

 23413  {
            calories    523
            box.width   25.3
            box.height  52
        }



# транзакции (PayPal, Apple, Stripe)

- very large!
- s3?
- reports


# модели и стандарты

- FHIR https://build.fhir.org/patient-example.json.html
- business (models for frontend, backend)
- legacy (mongo, open search)


# антипримеры

- data jsonb -> dump
- EntityA & EntityB


┌────┬─────────────┬──────────┬──────────┬────────────────────────────────────────────────┐
│ id │    type     │   name   │created-by│                  data (jsonb)                  │
├────┼─────────────┼──────────┼──────────┼────────────────────────────────────────────────┤
│ 1  │      A      │   foo    │   Ivan   │{:this "foo", items: [1, 2, 3]}                 │
├────┼─────────────┼──────────┼──────────┼────────────────────────────────────────────────┤
│ 1  │      B      │   bar    │   Petr   │{:state "inactive", "expires_in": 23423234234}  │
└────┴─────────────┴──────────┴──────────┴────────────────────────────────────────────────┘



# раньше


JsonField (Django / Alchemy)

~~~python
class JsonField(TextField)
  ...

class UserModel:
    id = IntegerField()
    name = TextField()
    data = JsonField()

user = UserModel.get_by_id(1)

user.data["field"] = 42
user.save()
~~~


- db: it's a string
- no bulk updates



# jsonb
- выбирать подмножество
- частично обновлять
- индексировать
- группировать
- json -> SQL -> json
- передача таблиц



Переезд с OpenSearch -> Postgres
- 30 сервисов
- 100K .. 5M
- DSL via HTTP/JSON




# Почему переехали с OpenSearch

1. дорогой
^^^^^^^^^^
уже был postgres; pg $>   opensearch $<<<


2. проекции (joins, tables)
^^^^^^^^^^^^^^^^^^^^^^^^^^^

entityA - get some-ids (1, 2, 3, 4, 5)
entityB - get other-ids (10, 20, 30, 40, 50)
entityC - get entities by ids (... .... ...)

разработчик выполняет роль базы



3. no SQL
^^^^^^^^^^^^^^^
дайте людям SQL (рыба/удочка)

busines -> SQL (ok)
busines -> mongo (not ok)



4. JSON-протокол
^^^^^^^^^^^^^^^^
opensearch: HTTP REST JSON
- фронтенд (нет)
- max 10.000 записей
- переполнение ByteArrayOutputStream Integer/MAX_VALUE
- JSON (нет ленивости)


{result
  {entities
    [{}
     {}
     ...
     {}]}}



# Версии документов и схема

Datomic

v1
{:good/id 1
 :good/sku 52342
 :good/title "Red cap"}

:good/sku = :db.type/Long

v2
{:good/id 99
 :good/sku "abc123x"
 :good/title "T-shirt"}

:good/sku = :db.type/String

- migrate v1 -> v2
- another name :good/sku-str or good/sku2


postgres:
- version
- data


(case version
    1
    (do-this model)

    2
    (do-that model)

    ...default)







# Why Postgres

- легкость в развертке (aws, neon.tech, supabase, ...)
- скорее всего уже есть
- Postgres Pro https://postgrespro.ru/education/books
- документация (рус)
- SQL (analytics)





# DEMO




# Summary

- no more "tables vs documents"
- Postgres + Jsonb
- index (btree, trigram, ts_vector)
- complex search (no map/reduce)
- reports
- SQL




# Links

Исходники
https://github.com/igrishaev/talks/tree/gh-pages/pg-json

Как наполнить базу сгенерированным JSON
https://grishaev.me/json-sql/

SQL posts
https://grishaev.me/tag/sql/

Postgres posts
https://grishaev.me/tag/postgres/

Optimizing PostgreSQL Performance & Compression: pglz vs. LZ4
https://www.timescale.com/blog/optimizing-postgresql-performance-compression-pglz-vs-lz4

Postgres как поисковый движок
https://habr.com/ru/companies/sravni/articles/888534/

Postgres as a search engine
https://anyblockers.com/posts/postgres-as-a-search-engine

Hybrid search
https://supabase.com/docs/guides/ai/hybrid-search
