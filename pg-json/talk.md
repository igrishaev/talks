


json


зачем JSON?

- вложенность
- разные типы
- наращивание
- модели и документы
-


примеры

- характеристики товаров
- транзакции (PayPal, Apple)
- модели и стандарты



# характеристики товаров


| sku   | title | description | category | subcategory |
|-------|-------|-------------|----------|-------------|
| 51231 |       |             |          |             |
| 62344 |       |             |          |             |


image






# транзакции (PayPal, Apple)





# модели и стандарты



антипримеры


раньше


JsonField (Django)

~~~python
class SomeModel:
    id = IntegerField()
    name = TextField()
    data = JsonField()

model = SomeModel.get_by_id(1)

model.data["field"] = 42
model.save()
~~~


json vs jsonb

операторы


модели


переезд

OpenSearch

про датомик

почему

дорогой
транзакции
проекции
sql

таблица

get-by-id

compression

запрос по полю
индекс
вывод типов

что искать
trigram

что угодно?
jsonpath
индексирование

подзапросы и пути

отчеты

утилиты и библиотеки






links

- https://grishaev.me/json-sql/
- https://www.timescale.com/blog/optimizing-postgresql-performance-compression-pglz-vs-lz4
