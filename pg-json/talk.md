

PostgreSQL как эффективная база для документных данных
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^


# зачем JSON?

- вложенность
- разные типы
- наращивание
- модели и документы
-


# примеры

- характеристики товаров
- транзакции (PayPal, Apple)
- модели и стандарты



# характеристики товаров


| sku   | title     | description            | category | subcategory |
|-------|-----------|------------------------|----------|-------------|
| 51231 | cap       | Red Abibas Cap         | cloth    | Sport cloth |
| 62344 | tea spoon | Small silver tea spoon | kitchen  | dishes      |



(images)


# транзакции (PayPal, Apple)

- large
- s3?
- reports


# модели и стандарты

- fhir
- business
- legacy (mongo, open search)


# антипримеры

- data field


# раньше


JsonField (Django)

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


# json vs jsonb

операторы
модели


# Переезд

OpenSearch
30 services

# Почему

1. дорогой
^^^^^^^^^^
2. проекции
3. sql
4. протокол


1. уже был postgres; pg $>   opensearch $<<<
2. разработчик выполняет роль базы

entityA - get some-ids (1, 2, 3, 4, 5)
entityB - get other-ids (10, 20, 30, 40, 50)
entityC - get entities by ids (... .... ...)

3. дайте людям SQL (рыба/удочка)

4. opensearch: HTTP REST JSON
- фронтенд (нет)
- max 10.000 записей
- переполнение Integer/MAX_VALUE
- JSON (нет ленивости)

{result
  {entities
    [{}
     {}
     ...
     {}]}}


# Datomic

- сложен в развертке (postgres, memcache, s3)
- требует схему
- версии


v1
{:good/id 1
 :good/sku 52342
 :good/title "Red cap"}

:good/sku = :db.type/integer

v2
{:good/id 99
 :good/sku "abc123x"
 :good/title "T-shirt"}

:good/sku = :db.type/string


# Why Postgres

- бесплатно
- легкость в развертке
- скорее всего уже есть
- Postgres Pro
- https://postgrespro.ru/education/books
- документация
- SQL



# DEMO




# Summary

- no more "tables vs documents"
- Jsonb Postgres
- index (btree, trigram, ts_vector)
- complex search (no map/reduce)
- reports
- SQL




# Links

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
