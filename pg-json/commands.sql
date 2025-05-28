
--
-- sample.json
--


--
-- prepare table
--

create table docs (
    id uuid primary key,
    doc jsonb compression lz4 not null,
--            ^^^^^^^^^^^^^^^
    created_at timestamp with time zone not null default current_timestamp,
    updated_at timestamp with time zone null
);



--
-- generate data
--

do $$

declare emails text[]; roles text[]; reviews text[]; curr text[];

begin

emails := '{ivan@acme.com,john@acme.com,marc@acme.com}';
roles := '{manager,agent,accounter,owner,reviewer}';
reviews := '{accept,reject,need-more-data,escalate}';
curr := '{usd,eur,rub,lir,tug}';

insert into docs (id, doc)
select
    gen_random_uuid() as id,
    jsonb_build_object(
      '__generated__', true, --!!!
      'inner-id', x,
      'requested-by', jsonb_build_object(
        'id', x % 1000,
        'short-name', format('Client %s Inc', x),
        'short-code', format('client-%s', x)
      ),
      'sum', jsonb_build_array(
        jsonb_build_object(
          'amount', round(random() * x),
          'currency', curr[1 + trunc(random() * array_length(curr, 1))],
          'period', format('%s years', x % 20)
        ),
        jsonb_build_object(
          'amount', round(random() * x),
          'currency', curr[1 + trunc(random() * array_length(curr, 1))],
          'period', format('%s years', x % 20)
        )
      ),
      'reviewed', jsonb_build_array(
        jsonb_build_object(
          'department', format('Department A %s', x % 200),
          'code', format('dep-a-%s', x % 200),
          'reviewers', jsonb_build_array(
            jsonb_build_object(
              'id', emails[1 + trunc(random() * array_length(emails, 1))],
              'role', roles[1 + trunc(random() * array_length(roles, 1))],
              'review', reviews[1 + trunc(random() * array_length(reviews, 1))],
              'created-at', current_timestamp::date + interval '1 day' * (x % 300)
            ),
            jsonb_build_object(
              'id', emails[1 + trunc(random() * array_length(emails, 1))],
              'role', roles[1 + trunc(random() * array_length(roles, 1))],
              'review', reviews[1 + trunc(random() * array_length(reviews, 1))],
              'created-at', current_timestamp::date + interval '1 day' * (x % 300)
            )
          )
        ),
        jsonb_build_object(
          'department', format('Department B %s', x % 200),
          'code', format('dep-b-%s', x % 200),
          'reviewers', jsonb_build_array(
            jsonb_build_object(
              'id', emails[1 + trunc(random() * array_length(emails, 1))],
              'role', roles[1 + trunc(random() * array_length(roles, 1))],
              'review', reviews[1 + trunc(random() * array_length(reviews, 1))],
              'created-at', current_timestamp::date + interval '1 day' * (x % 300)
            ),
            jsonb_build_object(
              'id', emails[1 + trunc(random() * array_length(emails, 1))],
              'role', roles[1 + trunc(random() * array_length(roles, 1))],
              'review', reviews[1 + trunc(random() * array_length(reviews, 1))],
              'created-at', current_timestamp::date + interval '1 day' * (x % 300)
            )
          )
        )
      )
    ) as doc
from
    generate_series(1, 1000000) as x;

end $$;

--  1M = 22 seconds
-- 20M =  6 minutes
-- 50M = 15 minutes

select count(*) from docs;
 count
--------
 1000000


select id from docs limit 100;

                  id
--------------------------------------
 34c5e3da-1279-47d7-ac33-60f7bf03997c
 f4df9aef-d14b-4c31-b4b1-03e06fee523d
 5a5d475a-41e1-4c9c-a702-a49e6d97e0c1
 8bf5f979-bdf8-4fd2-9cb4-9409f000f3c8
 cc8678a6-d6e7-4864-82c9-9b80b1d278fd
 03887643-a0b6-405f-a50e-696486855373
 6438c15c-69ae-4a38-87c4-fc58e041129f
 562fc544-7cf1-4e83-9c42-0ec737e28ee5
 d17a0ee1-e257-493e-8f25-04edececc3d2
 969fba47-28d0-48c1-87fa-4bbafe4f7d3f
 38990a30-1574-49d0-a382-998fefc99d27
 edf45386-32b3-4215-bc1e-be60145767d8
 19b2de46-0686-49c0-8157-c2819e31fc55
 07f68a03-ad1c-4fc4-a026-fa1b71808fad
 d9cb6ad6-8367-4667-89ba-4a2d36f89b64
 69c50dcd-7196-441d-9bd9-dd0a856b5959
 9aa34689-00dd-4e00-85ac-7f0f1b8d1750
 7ed74b0d-a48a-4ff1-a430-599306f82794
 431f0477-4343-4101-97fa-38acd9a268c1


-- get by id

select jsonb_pretty(doc) from docs
where id = '0001c6af-9c30-4c7b-b6b6-8d9d1e75e417'

                  jsonb_pretty
------------------------------------------------
 {                                             |
     "id": 71583,                              |
     "sum": [                                  |
         {                                     |
             "amount": 50501,                  |
             "period": "3 years",              |
             "currency": "rub"                 |
         },                                    |
         {                                     |
             "amount": 55639,                  |
             "period": "3 years",              |
             "currency": "lir"                 |
         }                                     |
     ],                                        |
     "reviewed": [                             |
         {                                     |
             "code": "dep-a-183",              |
             "reviewers": [                    |
                 {                             |
                     "id": null,               |
                     "role": "agent",          |
                     "review": "accept"        |
                 },                            |
                 {                             |
                     "id": "john@acme.com",    |
                     "role": "owner",          |
                     "review": "accept"        |



-- query fields

select
    id,

    doc #>> '{requested-by,id}'
    as requester_id,

    doc #>> '{requested-by,short-name}'
    as requester_name,

    doc #>> '{requested-by,short-code}'
    as requester_code,

    created_at

from
    docs

limit
    10;


                  id                  | requester_id | requester_name | requester_code |          created_at
--------------------------------------+--------------+----------------+----------------+-------------------------------
 34c5e3da-1279-47d7-ac33-60f7bf03997c | 1            | Client 1 Inc   | client-1       | 2025-05-24 17:15:32.249349+03
 f4df9aef-d14b-4c31-b4b1-03e06fee523d | 2            | Client 2 Inc   | client-2       | 2025-05-24 17:15:32.249349+03
 5a5d475a-41e1-4c9c-a702-a49e6d97e0c1 | 3            | Client 3 Inc   | client-3       | 2025-05-24 17:15:32.249349+03
 8bf5f979-bdf8-4fd2-9cb4-9409f000f3c8 | 4            | Client 4 Inc   | client-4       | 2025-05-24 17:15:32.249349+03
 cc8678a6-d6e7-4864-82c9-9b80b1d278fd | 5            | Client 5 Inc   | client-5       | 2025-05-24 17:15:32.249349+03
 03887643-a0b6-405f-a50e-696486855373 | 6            | Client 6 Inc   | client-6       | 2025-05-24 17:15:32.249349+03
 6438c15c-69ae-4a38-87c4-fc58e041129f | 7            | Client 7 Inc   | client-7       | 2025-05-24 17:15:32.249349+03
 562fc544-7cf1-4e83-9c42-0ec737e28ee5 | 8            | Client 8 Inc   | client-8       | 2025-05-24 17:15:32.249349+03
 d17a0ee1-e257-493e-8f25-04edececc3d2 | 9            | Client 9 Inc   | client-9       | 2025-05-24 17:15:32.249349+03
 969fba47-28d0-48c1-87fa-4bbafe4f7d3f | 10           | Client 10 Inc  | client-10      | 2025-05-24 17:15:32.249349+03




select
    id,

    doc #>> '{requested-by,id}'
    as requester_id,

    doc #>> '{requested-by,short-name}'
    as requester_name,

    doc #>> '{requested-by,short-code}'
    as requester_code,

    created_at

from
    docs

limit
    10

offset
    300000;


                  id                  | requester_id |  requester_name   | requester_code |          created_at
--------------------------------------+--------------+-------------------+----------------+-------------------------------
 bd38a686-5211-4f29-8df2-289397f51def | 0            | Client 300000 Inc | client-300000  | 2025-05-24 17:15:32.249349+03
 938d78fd-e302-424f-a8a7-06dd53ce90f0 | 1            | Client 300001 Inc | client-300001  | 2025-05-24 17:15:32.249349+03
 b1ab9fd8-cd94-4ac9-9504-98c5f1acccb5 | 2            | Client 300002 Inc | client-300002  | 2025-05-24 17:15:32.249349+03
 e6d95249-65aa-40b7-875f-83a8a3c26510 | 3            | Client 300003 Inc | client-300003  | 2025-05-24 17:15:32.249349+03
 5ada7a4a-8ab5-4394-bd6c-ca2d66ae5849 | 4            | Client 300004 Inc | client-300004  | 2025-05-24 17:15:32.249349+03
 dcc0f468-28a8-4abf-b4b4-29f2e97b305d | 5            | Client 300005 Inc | client-300005  | 2025-05-24 17:15:32.249349+03
 6ee9a84d-2e45-40de-8b99-f95e20b9e4df | 6            | Client 300006 Inc | client-300006  | 2025-05-24 17:15:32.249349+03
 5c282570-aa91-4d59-9408-abc0808d2514 | 7            | Client 300007 Inc | client-300007  | 2025-05-24 17:15:32.249349+03
 3558257a-7426-4c44-a2e9-9ea7e112a02e | 8            | Client 300008 Inc | client-300008  | 2025-05-24 17:15:32.249349+03
 5ce2b724-61d5-4ce7-9661-5163f067376d | 9            | Client 300009 Inc | client-300009  | 2025-05-24 17:15:32.249349+03


-- index: requested-by.short-code


create index if not exists idx_doc_requested_by_short_code_btree
    on docs using btree ((doc #>> '{requested-by,short-code}'));

explain analyze
select id
from docs
where doc #>> '{requested-by,short-code}' = 'client-300004';


 Bitmap Heap Scan on docs  (cost=59.80..8337.18 rows=2500 width=16) (actual time=0.100..0.101 rows=1 loops=1)
   Recheck Cond: ((doc #>> '{requested-by,short-code}'::text[]) = 'client-300004'::text)
   Heap Blocks: exact=1
   ->  Bitmap Index Scan on idx_doc_requested_by_short_code_btree  (cost=0.00..59.17 rows=2500 width=0) (actual time=0.091..0.091 rows=1 loops=1)
         Index Cond: ((doc #>> '{requested-by,short-code}'::text[]) = 'client-300004'::text)
 Planning Time: 2.588 ms
 Execution Time: 0.142 ms
(7 rows)


--
-- order by
-- btree < = >
--



select
    id,

    doc #>> '{requested-by,short-name}'
    as requester_name,

    doc #>> '{requested-by,short-code}'
    as requester_code

from docs
order by
    doc #>> '{requested-by,short-code}' desc
limit
    100;


                  id                  |  requester_name  | requester_code
--------------------------------------+------------------+----------------
 db5446dc-8ff7-41a5-a3a3-cc95b9a19d6f | Client 99999 Inc | client-99999
 cbd0223b-26e0-4bd4-9f6a-f84e2528bf4e | Client 99998 Inc | client-99998
 e9bc20ef-1a7c-45db-89b0-162673b2c4e0 | Client 99997 Inc | client-99997
 8442636f-9ac2-4589-b52f-9b4b19ac9512 | Client 99996 Inc | client-99996
 50cbaa1f-6bcc-4220-bb89-d4f4a91d6dbd | Client 99995 Inc | client-99995
 8bb19978-5662-4a94-b104-ddbe3706d367 | Client 99994 Inc | client-99994
 601f88b8-c14a-4830-83ad-ab907a6baadb | Client 99993 Inc | client-99993
 a47c4a24-bbcc-4c77-b380-d245160a9418 | Client 99992 Inc | client-99992

                                                                               QUERY PLAN
------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 Limit  (cost=0.42..48.33 rows=100 width=80) (actual time=0.036..0.152 rows=100 loops=1)
   ->  Index Scan Backward using idx_doc_requested_by_short_code_btree on docs  (cost=0.42..239548.42 rows=500000 width=80) (actual time=0.034..0.143 rows=100 loops=1)
 Planning Time: 0.128 ms
 Execution Time: 0.174 ms
(4 rows)


-- index with int

create index if not exists idx_doc_inner_id_btree
    on docs using btree (((doc #>> '{inner-id}')::int));




select
    (doc #>> '{inner-id}')::int
    as inner_id,

    doc #>> '{requested-by,short-name}'
    as requester_name,

    doc #>> '{requested-by,short-code}'
    as requester_code

from
    docs

order by
    (doc #>> '{inner-id}')::int desc

limit
    100;


 inner_id |  requester_name   | requester_code
----------+-------------------+----------------
   500000 | Client 500000 Inc | client-500000
   499999 | Client 499999 Inc | client-499999
   499998 | Client 499998 Inc | client-499998
   499997 | Client 499997 Inc | client-499997
   499996 | Client 499996 Inc | client-499996
   499995 | Client 499995 Inc | client-499995
   499994 | Client 499994 Inc | client-499994
   499993 | Client 499993 Inc | client-499993
   499992 | Client 499992 Inc | client-499992


                                                                       QUERY PLAN
---------------------------------------------------------------------------------------------------------------------------------------------------------
 Limit  (cost=0.42..48.64 rows=100 width=68) (actual time=0.041..0.208 rows=100 loops=1)
   ->  Index Scan Backward using idx_doc_inner_id_btree on docs  (cost=0.42..241082.42 rows=500000 width=68) (actual time=0.039..0.198 rows=100 loops=1)
 Planning Time: 0.162 ms
 Execution Time: 0.234 ms


--
-- list/map of indexed attributes
--


-- 1. support any path? (like OpenSearch)
-- 2. paths with arrays [{users: [{...}]}]


--
-- JSON path language! (like XPath)
-- before: jsQuery (Wargaming)
--



json @@ 'json path predicate'
json @? 'json path with subquery'



doc @@ '$.reviewed.reviewers.id == "ivan@acme.com"' -- lax

-- lax vs strict

doc @@ 'lax $.reviewed.reviewers.id == "ivan@acme.com"'

doc @@ 'strict $.reviewed[*].reviewers[*].id == "ivan@acme.com"'

-- doesn't work with nested arrays like [*][*]




explain analyze
select doc['reviewed']
from docs
where doc @@ '$.reviewed.reviewers.id == "ivan@acme.com"'


                                                  QUERY PLAN
---------------------------------------------------------------------------------------------------------------
 Seq Scan on docs  (cost=0.00..61709.00 rows=409091 width=32) (actual time=0.040..308.773 rows=400989 loops=1)
   Filter: (doc @@ '($."reviewed"."reviewers"."id" == "ivan@acme.com")'::jsonpath)
   Rows Removed by Filter: 99011
 Planning Time: 0.424 ms
 Execution Time: 315.248 ms





-- index jsonb_path_ops

create index if not exists idx_doc_gin_jsonb_path
    on docs using gin (doc jsonb_path_ops);


btree: < <= = >= >

$.reviewed.0.reviewers.0.id   ...
$.reviewed.0.reviewers.0.name ...
$.reviewed.0.reviewers.1.id   ...
$.reviewed.0.reviewers.1.name ...
$.reviewed.1.reviewers.0.id   ...
$.reviewed.1.reviewers.0.name ...
$.reviewed.1.reviewers.1.id   ...
$.reviewed.2.reviewers.1.name ...


-- heavy (large)
-- subset


create index if not exists idx_doc_gin_jsonb_path
    on docs using gin (doc['reviewed'] jsonb_path_ops);


--
-- subqueries
--


/*
    id = ivan@acme.com
    and
    role = 'agent'
*/

select doc
    from docs
where
        doc @@ '$.reviewed.reviewers.id == "ivan@acme.com"'
    and doc @@ '$.reviewed.reviewers.role == "agent"'

^^^^^^^^^^^^^^



$.reviewed[0].reviewers[0].id         -- ivan@acme.com     ok
$.reviewed[0].reviewers[1].id         -- john@acme.com
$.reviewed[1].reviewers[0].id         -- marc@acme.com
$.reviewed[1].reviewers[1].id         -- ivan@acme.com


$.reviewed[0].reviewers[0].role       -- manager
$.reviewed[0].reviewers[1].role       -- analytic
$.reviewed[1].reviewers[0].role       -- agent             ok
$.reviewed[1].reviewers[1].role       -- accounter


-- the same as OpenSearch


@? path exists
^^^^^^^^^^^^^^



select doc['reviewed']
from docs
where doc @? '$.reviewed.reviewers ? (@.id == "ivan@acme.com" && @.role == "agent")';
--        ^^

 [{"code": "dep-a-5", "reviewers":  [{"id": "john@acme.com", "role": null, "review": "need-more-data"}, {"id": "john@acme.com", "role": null, "review": "accept"}], "department": "Department A 5"}, {"code": "dep-b-5", "reviewers": [{"id": null, "role": "accounter", "review": null}, {"id": "ivan@acme.com", "role": "agent", "review": null}], "department": "Department B 5"}]
 [{"code": "dep-a-9", "reviewers":  [{"id": "ivan@acme.com", "role": "agent", "review": "need-more-data"}, {"id": "john@acme.com", "role": "agent", "review": "reject"}], "department": "Department A 9"}, {"code": "dep-b-9", "reviewers": [{"id": "ivan@acme.com", "role": "agent", "review": "need-more-data"}, {"id": null, "role": "accounter", "review": null}], "department": "Department B 9"}]
 [{"code": "dep-a-10", "reviewers": [{"id": "john@acme.com", "role": "accounter", "review": "accept"}, {"id": "ivan@acme.com", "role": "agent", "review": null}], "department": "Department A 10"}, {"code": "dep-b-10", "reviewers": [{"id": null, "role": "manager", "review": "need-more-data"}, {"id": null, "role": "accounter", "review": "need-more-data"}], "department": "Department B 10"}]
 [{"code": "dep-a-11", "reviewers": [{"id": "ivan@acme.com", "role": "agent", "review": "need-more-data"}, {"id": null, "role": "owner", "review": "need-more-data"}], "department": "Department A 11"}, {"code": "dep-b-11", "reviewers": [{"id": "ivan@acme.com", "role": "agent", "review": null}, {"id": null, "role": "manager", "review": "need-more-data"}], "department": "Department B 11"}]
 [{"code": "dep-a-13", "reviewers": [{"id": "ivan@acme.com", "role": "accounter", "review": null}, {"id": null, "role": null, "review": "need-more-data"}], "department": "Department A 13"}, {"code": "dep-b-13", "reviewers": [{"id": "ivan@acme.com", "role": "agent", "review": "reject"}, {"id": "john@acme.com", "role": "accounter", "review": "reject"}], "department": "Department B 13"}]
 [{"code": "dep-a-15", "reviewers": [{"id": "ivan@acme.com", "role": "owner", "review": "reject"}, {"id": "ivan@acme.com", "role": "agent", "review": "need-more-data"}], "department": "Department A 15"}, {"code": "dep-b-15", "reviewers": [{"id": "ivan@acme.com", "role": "owner", "review": "reject"}, {"id": "john@acme.com", "role": null, "review": "reject"}], "department": "Department B 15"}]
 [{"code": "dep-a-18", "reviewers": [{"id": "ivan@acme.com", "role": "agent", "review": "need-more-data"}, {"id": null, "role": null, "review": "accept"}], "department": "Department A 18"}, {"code": "dep-b-18", "reviewers": [{"id": null, "role": "agent", "review": "accept"}, {"id": "ivan@acme.com", "role": null, "review": null}], "department": "Department B 18"}]
 [{"code": "dep-a-19", "reviewers": [{"id": null, "role": "agent", "review": "accept"}, {"id": null, "role": "owner", "review": "reject"}], "department": "Department A 19"}, {"code": "dep-b-19", "reviewers": [{"id": null, "role": null, "review": "need-more-data"}, {"id": "ivan@acme.com", "role": "agent", "review": "need-more-data"}], "department": "Department B 19"}]


-- by department


select doc['reviewed']
from docs
where doc @? '$.reviewed ? (@.code == "dep-a-18").reviewers ? (@.id == "ivan@acme.com" && @.role == "agent")';


 [{"code": "dep-a-18", "reviewers": [{"id": "ivan@acme.com", "role": "agent", "review": "need-more-data"}, {"id": null, "role": null, "review": "accept"}], "department": "Department A 18"}, {"code": "dep-b-18", "reviewers": [{"id": null, "role": "agent", "review": "accept"}, {"id": "ivan@acme.com", "role": null, "review": null}], "department": "Department B 18"}]
 [{"code": "dep-a-18", "reviewers": [{"id": "ivan@acme.com", "role": "agent", "review": "accept"}, {"id": null, "role": "owner", "review": "need-more-data"}], "department": "Department A 18"}, {"code": "dep-b-18", "reviewers": [{"id": "john@acme.com", "role": "manager", "review": null}, {"id": "ivan@acme.com", "role": "manager", "review": "need-more-data"}], "department": "Department B 18"}]
 [{"code": "dep-a-18", "reviewers": [{"id": "ivan@acme.com", "role": "agent", "review": null}, {"id": "john@acme.com", "role": "owner", "review": "accept"}], "department": "Department A 18"}, {"code": "dep-b-18", "reviewers": [{"id": "ivan@acme.com", "role": "owner", "review": "accept"}, {"id": "ivan@acme.com", "role": null, "review": null}], "department": "Department B 18"}]
 [{"code": "dep-a-18", "reviewers": [{"id": "john@acme.com", "role": null, "review": "need-more-data"}, {"id": "ivan@acme.com", "role": "agent", "review": null}], "department": "Department A 18"}, {"code": "dep-b-18", "reviewers": [{"id": null, "role": "accounter", "review": "need-more-data"}, {"id": "john@acme.com", "role": "accounter", "review": "accept"}], "department": "Department B 18"}]



-- honeysql samples

(sql/register-op! :==)

[:== foo bar]
'foo == bar'

(into [:||]
      (for [v value]
        [:== [:raw "@"] [:raw (util/to-json v)]]))

'(@.foo == 1) || (@.bar == 2) || (@.lol == 3)'


'(@.foo == 1) && (@.bar == 2) && (@.lol == 3)'


(sql/register-fn!
 :json#>>
 (fn [_ [field path]]
   (let [array (->array path)]
     (sql/format-expr [:nest [:#>> field array]]))))


[:json#>> doc [:requested-by :id]]

'doc #>> {requested-by,id}}'



-- DLS b/w services

-- DSL -> OpenSearch
-- DSL -> Postgres


{:filter [:and
           [:= :attrs.user.id "john@test.com"]
           [:= :attrs.user.role "manager"]
           [:> :attrs.limit 999]
           [:in :attrs.type ["limit" "review"]]]
 :sort [:attrs.created-at :desc]
 :size 100
 :from 350}

-- parse, validate

{:select [:id :doc]
 :from [:docs]
 :where
 [:and
    [:json= :attrs.user.id "john@test.com"]
    [:json= :attrs.user.role "manager"]
    [:json> :attrs.limit 999]
    [:json-in :attrs.type ["limit" "review"]]]
 :order-by
 [[:json>> :attrs.created-at ] :desc]}


-- final SQL

select
    id, doc
from
    docs
where
        doc @@ 'lax $.attrs.user.id == "john@test.com"'
    and doc @@ 'lax $.attrs.user.role == "manager"'
    and doc @@ 'lax $.attrs.limit > 999'
    and doc @? 'lax $.attrs.type ? (@ == "limit" || @ == "review")'
order by
    doc #>> '{attrs,created-at}'
limit
    100
offset
    350



-- nested


{:filter [:reviewed.reviewers
           [:nested
             [:= :id "ivan@acme.com"]
             [:= :role "manager"]]]}

where doc @? '$.reviewed.reviewers ? (@.id == "ivan@acme.com" && @.role == "manager")'

--
-- wildcard (contains)
--

create extension if not exists pg_trgm;



-- it's integer but we need ilike!

create index if not exists idx_doc_inner_id_trgm on docs
using gin ((doc #>> '{inner-id}') gin_trgm_ops);



select id, doc #>> '{inner-id}'
from docs
where doc #>> '{inner-id}' ilike '%5555%'
limit 100;


                  id                  | ?column?
--------------------------------------+----------
 b4efffb8-18db-44f0-b486-ea3eb74b0ff5 | 5555
 bd19cb30-1246-41a3-a0df-d71777604221 | 15555
 d17ca3c1-4e8a-4973-8f24-c66013243e0b | 25555
 5e0b76a1-a157-48d6-8f12-8738564b64ea | 35555
 9de5cac9-10e1-4b56-b84e-b86cd497d988 | 45555
 90f93653-0a1d-47f9-8479-e27b5a38ffe0 | 55550
 1d3aac9f-6fdb-400a-8644-7368a7b32354 | 55551
 b1e69e59-0c5b-424a-9595-6f19a824b907 | 55552
 7909a19a-1b3f-4b8b-afe7-15807e8ede7f | 55553
 368df7dc-4376-4f45-a2f5-5e4a96bc6b82 | 55554
 907ab831-8058-47e8-b61e-262efcc6def3 | 55555
 192d5fcd-2188-4f53-8f24-e7bc59a11a6c | 55556
 1c8e901c-4413-4130-87b5-7dfcd526ac1d | 55557
 60c671bb-3ab2-4c82-9366-a871b7e4748a | 55558
 d2945a24-6a4c-46ed-b043-7383d967374d | 55559
 bb5d18b2-5f4a-476f-b176-7ac7b5b24c41 | 65555
 4f64a8cf-a363-4af3-bdf0-dcd3b08e4320 | 75555
 dba28834-512a-4ec7-8229-760a420d2280 | 85555
 8434b228-791d-4d6e-8d6c-cbb569151fe1 | 95555
 28adea61-b9ee-40fc-a380-b3dff72784a2 | 105555
 a39804d9-8f15-4750-8c7b-977b5c365982 | 115555
 2523a58c-6ab3-41a7-9796-e29c46f36757 | 125555
 1571666b-80ba-471f-86bf-a82d4a79b4cc | 135555
 db97bcfe-557f-4966-b882-0a7a9f2ec077 | 145555
 e4dc3c5d-501c-4fa6-9112-3c027672e01f | 155550
 214afd9d-938a-4eff-ba25-63d680387688 | 155551



                                                                QUERY PLAN
-------------------------------------------------------------------------------------------------------------------------------------------
 Limit  (cost=58.81..376.41 rows=100 width=48) (actual time=0.736..3.300 rows=100 loops=1)
   ->  Bitmap Heap Scan on docs  (cost=58.81..25466.92 rows=8000 width=48) (actual time=0.734..3.292 rows=100 loops=1)
         Recheck Cond: ((doc #>> '{inner-id}'::text[]) ~~* '%5555%'::text)
         Rows Removed by Index Recheck: 1387
         Heap Blocks: exact=665
         ->  Bitmap Index Scan on idx_doc_inner_id_trgm  (cost=0.00..56.81 rows=8000 width=0) (actual time=0.508..0.508 rows=3700 loops=1)
               Index Cond: ((doc #>> '{inner-id}'::text[]) ~~* '%5555%'::text)
 Planning Time: 0.206 ms
 Execution Time: 3.339 ms



-- search by many fields

doc #>> '{client.name}' ilike '%pattern%'
OR
doc #>> '{client,description}' ilike '%pattern%'
OR
doc #>> '{client,department}' ilike '%pattern%'


create index ... on docs
    (             coalesce(doc #>> '{client.name}', '')
        || ' ' || coalesce(doc #>> '{client.description}', '')
        || ' ' || coalesce(doc #>> '{client.department}', '')
    trgm_opt
    )

...

where
    (             coalesce(doc #>> '{client.name}', '')
        || ' ' || coalesce(doc #>> '{client.description}', '')
        || ' ' || coalesce(doc #>> '{client.department}', '')

    ) ilike '%pattern%'









--
-- search with scoring
--

-- 1: exact match
-- 2: contains
-- 3: fuzzy






               [part1]                            [part2]                             [part3]
┌───────────────┬──────┬────────────┐                                                    ┌───────────────────────┐
│               │  id  │   score    │                                                    │                       │
│exact match    ├──────┼────────────┤                                                    │                       │
│               │  id  │   score    │                                                    │                       │
│               ├──────┼────────────┤                                                    │                       │
│               │  id  │   score    │                                ┌──────┬────────────┤                       │
├───────────────┴──────┴────────────┤                                │  id  │   score    │                       │
│               UNION               │                                ├──────┼────────────┤                       │
├───────────────┬──────┬────────────┤    ┌───────────────────────┐   │  id  │   score    │inner JOIN docs        │
│               │  id  │   score    │    │select                 │   ├──────┼────────────┤  on part2.id = doc.id │
│   select by   ├──────┼────────────┤    │    id, min(score)     │   │  id  │   score    │order by               │
│  like         │  id  │   score    │───▶│from                   │───▶──────┼────────────┤  score asc            │
│               ├──────┼────────────┤    │    part1              │   │  id  │   score    │                       │
│               │  id  │   score    │    │group by id            │   ├──────┼────────────┤                       │
├───────────────┴──────┴────────────┤    └───────────────────────┘   │  id  │   score    │                       │
│               UNION               │                                ├──────┼────────────┤                       │
├───────────────┬──────┬────────────┤                                │  id  │   score    │                       │
│               │  id  │   score    │                                └──────┴────────────┤                       │
│similarity     ├──────┼────────────┤                                                    │                       │
│or tsvector    │  id  │   score    │                                                    │                       │
│               ├──────┼────────────┤                                                    │                       │
│               │  id  │   score    │                                                    │                       │
└───────────────┴──────┴────────────┘                                                    └───────────────────────┘


-- explain analyze
select
    sub.id,
    sub.score,
    docs

from (

    select id, min(score) as score
    from (

        select sub.*
        from (
            select
                id, 10 as score
            from
                docs
            where
                (doc #>> '{inner-id}') = '555'
            limit
                10
        ) as sub

    UNION

        select sub.*
        from (
            select
                id, 20 as score
            from
                docs
            where
                (doc #>> '{inner-id}') ilike '%555%'
        limit
            10
        ) as sub

    UNION

        select sub.*
        from (
            select
                id, 30 as score
            from
                docs
            where
                -- set pg_trgm.similarity_threshold=0.5;
                (doc #>> '{inner-id}') % '555'
        limit
            10
        ) as sub

    ) as sub

    group by id

) as sub

left join docs
    on sub.id = docs.id
order by
    sub.score
;


                  id                  | score
--------------------------------------+-------
 097cfa50-7baf-477e-8dd0-5c78a54bb116 |    20
 32031cd9-284a-4a33-8af8-f0eae7da63a6 |    20 -- duplicate
 32031cd9-284a-4a33-8af8-f0eae7da63a6 |    30 -- duplicate
 3ce9e657-9579-4c33-bbfb-62c2532e3068 |    30
 437dcd20-cb39-49e2-8e28-f4160a3fdfb5 |    10 -- exact
 437dcd20-cb39-49e2-8e28-f4160a3fdfb5 |    20
 437dcd20-cb39-49e2-8e28-f4160a3fdfb5 |    30
 6c9b89fd-4518-4445-b2b2-81ec4fda88b6 |    20
 6c9b89fd-4518-4445-b2b2-81ec4fda88b6 |    30
 7848ba20-160a-41f4-8087-6dbf998c17c2 |    30
 8ac6deda-27b8-431d-94d0-460d5220e214 |    20
 94143e2a-f41c-4df7-a26d-379ea0e7ef2f |    20
 980cd80b-a02d-4938-91c9-48114c82a285 |    20
 980cd80b-a02d-4938-91c9-48114c82a285 |    30
 9814293b-4e9e-4362-ad87-a5884fe62e52 |    20
 9814293b-4e9e-4362-ad87-a5884fe62e52 |    30
 9999e2b9-a5e2-4d9b-8929-8fdecc056f8c |    30
 9aa8ceba-858c-47d2-bf9b-d088e7ae2d1d |    20
 a76aa321-cba5-442a-a24c-301aba848eb6 |    20
 a76aa321-cba5-442a-a24c-301aba848eb6 |    30
 ab9ea9cd-6231-4405-96be-4a28faa8b490 |    30



                  id                  | score | doc
--------------------------------------+-------+------
 437dcd20-cb39-49e2-8e28-f4160a3fdfb5 |    10 | 555
 32031cd9-284a-4a33-8af8-f0eae7da63a6 |    20 | 5554
 097cfa50-7baf-477e-8dd0-5c78a54bb116 |    20 | 1555
 980cd80b-a02d-4938-91c9-48114c82a285 |    20 | 5551
 9814293b-4e9e-4362-ad87-a5884fe62e52 |    20 | 5550
 9aa8ceba-858c-47d2-bf9b-d088e7ae2d1d |    20 | 3555
 a76aa321-cba5-442a-a24c-301aba848eb6 |    20 | 5552
 6c9b89fd-4518-4445-b2b2-81ec4fda88b6 |    20 | 5553
 8ac6deda-27b8-431d-94d0-460d5220e214 |    20 | 4555
 94143e2a-f41c-4df7-a26d-379ea0e7ef2f |    20 | 2555
 3ce9e657-9579-4c33-bbfb-62c2532e3068 |    30 | 5556
 ab9ea9cd-6231-4405-96be-4a28faa8b490 |    30 | 5557
 7848ba20-160a-41f4-8087-6dbf998c17c2 |    30 | 55
 9999e2b9-a5e2-4d9b-8929-8fdecc056f8c |    30 | 5555



                                                                                  QUERY PLAN
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 Sort  (cost=368.37..368.42 rows=21 width=52) (actual time=10.561..10.566 rows=14 loops=1)
   Sort Key: (min((10)))
   Sort Method: quicksort  Memory: 25kB
   ->  Nested Loop Left Join  (cost=190.57..367.91 rows=21 width=52) (actual time=10.433..10.553 rows=14 loops=1)
         ->  GroupAggregate  (cost=190.14..190.62 rows=21 width=20) (actual time=10.404..10.427 rows=14 loops=1)
               Group Key: docs_1.id
               ->  Unique  (cost=190.14..190.30 rows=21 width=20) (actual time=10.392..10.407 rows=21 loops=1)
                     ->  Sort  (cost=190.14..190.20 rows=21 width=20) (actual time=10.391..10.396 rows=21 loops=1)
                           Sort Key: docs_1.id, (10)
                           Sort Method: quicksort  Memory: 25kB
                           ->  Append  (cost=46.61..189.68 rows=21 width=20) (actual time=2.961..10.336 rows=21 loops=1)
                                 ->  Limit  (cost=46.61..50.63 rows=1 width=20) (actual time=2.960..3.016 rows=1 loops=1)
                                       ->  Bitmap Heap Scan on docs docs_1  (cost=46.61..50.63 rows=1 width=20) (actual time=2.958..3.014 rows=1 loops=1)
                                             Recheck Cond: ((doc #>> '{inner-id}'::text[]) = '555'::text)
                                             Rows Removed by Index Recheck: 21
                                             Heap Blocks: exact=22
                                             ->  Bitmap Index Scan on idx_doc_inner_id_trgm  (cost=0.00..46.61 rows=1 width=0) (actual time=2.928..2.928 rows=22 loops=1)
                                                   Index Cond: ((doc #>> '{inner-id}'::text[]) = '555'::text)
                                 ->  Limit  (cost=13.21..52.51 rows=10 width=20) (actual time=1.158..1.209 rows=10 loops=1)
                                       ->  Bitmap Heap Scan on docs docs_2  (cost=13.21..406.28 rows=100 width=20) (actual time=1.158..1.208 rows=10 loops=1)
                                             Recheck Cond: ((doc #>> '{inner-id}'::text[]) ~~* '%555%'::text)
                                             Heap Blocks: exact=7
                                             ->  Bitmap Index Scan on idx_doc_inner_id_trgm  (cost=0.00..13.18 rows=100 width=0) (actual time=0.822..0.822 rows=3700 loops=1)
                                                   Index Cond: ((doc #>> '{inner-id}'::text[]) ~~* '%555%'::text)
                                 ->  Limit  (cost=47.13..86.44 rows=10 width=20) (actual time=5.958..6.105 rows=10 loops=1)
                                       ->  Bitmap Heap Scan on docs docs_3  (cost=47.13..440.20 rows=100 width=20) (actual time=5.957..6.103 rows=10 loops=1)
                                             Recheck Cond: ((doc #>> '{inner-id}'::text[]) % '555'::text)
                                             Rows Removed by Index Recheck: 68
                                             Heap Blocks: exact=20
                                             ->  Bitmap Index Scan on idx_doc_inner_id_trgm  (cost=0.00..47.11 rows=100 width=0) (actual time=5.089..5.089 rows=13079 loops=1)
                                                   Index Cond: ((doc #>> '{inner-id}'::text[]) % '555'::text)
         ->  Index Scan using docs_pkey on docs  (cost=0.42..8.44 rows=1 width=976) (actual time=0.008..0.008 rows=1 loops=14)
               Index Cond: (id = docs_1.id)
 Planning Time: 0.821 ms
 Execution Time: 10.657 ms
(35 rows)




   1. select exact     2. select ilike   3. select tsvector                         inner join docs by id

┌──────┬────────────┬ ─ ─ ─┌ ─ ─ ─ ─ ─ ─┌ ─ ─ ─┌ ─ ─ ─ ─ ─ ─        ┌──────┬────────────┐      ┌──────┬─────────────────────────┐
│  id  │   score    │      │            │      │            │       │  id  │   score    │      │  id  │        document         │
├──────┼────────────┼ ─ ─ ─├ ─ ─ ─ ─ ─ ─├──────┼────────────┐       ├──────┼────────────┤      ├──────┼─────────────────────────┤
│  id  │   score    │      │            │  id  │   score    │       │  id  │   score    │      │  id  │        document         │
├──────┼────────────┼──────┼────────────┼──────┼────────────┤       ├──────┼────────────┤      ├──────┼─────────────────────────┤
│  id  │   score    │  id  │   score    │  id  │   score    │ ─────▶│  id  │   score    │◀─────│  id  │        document         │
├──────┼────────────┼──────┼────────────┼──────┼────────────┤       ├──────┼────────────┤      ├──────┼─────────────────────────┤
│  id  │   score    │  id  │   score    │  id  │   score    │       │  id  │   score    │      │  id  │        document         │
├──────┼────────────┼──────┼────────────┼──────┼────────────┤       ├──────┼────────────┤      ├──────┼─────────────────────────┤
       │            │  id  │   score    │  id  │   score    │       │  id  │   score    │      │  id  │        document         │
├ ─ ─ ─├ ─ ─ ─ ─ ─ ─├──────┼────────────┼──────┼────────────┘       ├──────┼────────────┤      ├──────┼─────────────────────────┤
       │            │  id  │   score    │      │            │       │  id  │   score    │      │  id  │        document         │
└ ─ ─ ─└ ─ ─ ─ ─ ─ ─└──────┴────────────┴ ─ ─ ─└ ─ ─ ─ ─ ─ ─        └──────┴────────────┘      └──────┴─────────────────────────┘

                                                                                      order by score asc



--
-- reports (CSV/Excel)
--

select
    id,
    jsonb_array_elements(doc -> 'sum')
from
    docs
limit
    100;

                  id                  |                    jsonb_array_elements
--------------------------------------+-------------------------------------------------------------
 3558257a-7426-4c44-a2e9-9ea7e112a02e | {"amount": 260581, "period": "8 years", "currency": null}
 3558257a-7426-4c44-a2e9-9ea7e112a02e | {"amount": 140094, "period": "8 years", "currency": "eur"}
 5ce2b724-61d5-4ce7-9661-5163f067376d | {"amount": 137629, "period": "9 years", "currency": "usd"}
 5ce2b724-61d5-4ce7-9661-5163f067376d | {"amount": 231653, "period": "9 years", "currency": "eur"}
 12d4e215-ef56-4b1d-859e-9d438826e60b | {"amount": 246181, "period": "10 years", "currency": "usd"}
 12d4e215-ef56-4b1d-859e-9d438826e60b | {"amount": 132875, "period": "10 years", "currency": "lir"}
 bca04255-baca-4b07-b9e8-b4e1a00280a6 | {"amount": 234387, "period": "11 years", "currency": "rub"}


select
    sub.id,

    sub.sum ->> 'amount'
    as amount,

    sub.sum ->> 'currency'
    as currency,

    sub.sum ->> 'period'
    as period

from (
    select
        id,

        jsonb_array_elements(doc -> 'sum')
        as sum
    from
        docs
) as sub
limit 100;


                  id                  | amount | currency |  period
--------------------------------------+--------+----------+----------
 3558257a-7426-4c44-a2e9-9ea7e112a02e | 260581 | eur      |  8 years
 3558257a-7426-4c44-a2e9-9ea7e112a02e | 140094 | eur      |  8 years
 5ce2b724-61d5-4ce7-9661-5163f067376d | 137629 | usd      |  9 years
 5ce2b724-61d5-4ce7-9661-5163f067376d | 231653 | eur      |  9 years
 12d4e215-ef56-4b1d-859e-9d438826e60b | 246181 | usd      | 10 years
 12d4e215-ef56-4b1d-859e-9d438826e60b | 132875 | lir      | 10 years
 bca04255-baca-4b07-b9e8-b4e1a00280a6 | 234387 | rub      | 11 years
 bca04255-baca-4b07-b9e8-b4e1a00280a6 | 20731  | rub      | 11 years
 c699f764-51e7-440e-8104-d5450a9392ac | 274868 | lir      | 12 years
 c699f764-51e7-440e-8104-d5450a9392ac | 222567 | usd      | 12 years
 7009bcab-cf93-44e4-955b-003751282cbb | 107498 | lir      | 13 years
 7009bcab-cf93-44e4-955b-003751282cbb | 184200 | lir      | 13 years


-- one level at once
-- select from (select from (select from ...))


-- 17: json_table

select
    id,
    flatten.*
from
    docs,
    json_table(doc, '$' columns(
        inner_id             int  path '$."inner-id"',
        requested_id         int  path '$."requested-by".id',
        requested_short_name text path '$."requested-by"."short-name"',
        requested_short_code text path '$."requested-by"."short-code"',
        nested path '$.reviewed[*]' columns (             -- nested
            dep_id for ordinality,                        -- surrogate id
            dep_name text path '$.department',
            dep_code text path '$.code',
            nested path '$.reviewers[*]' columns(         -- nested
                review_id for ordinality,                 -- surrogate id
                user_id     text path '$.id',
                role text   path '$.role',
                review text path '$.review',
                review_date date path '$."created-at"'    -- date
            )
        )
    )) as flatten
limit
    1000;


-- out1.sql


create materialized view mv_docs_flatten as
select
    id,
    flatten.*
from
    docs,
    json_table(doc, '$' columns(
        inner_id int path '$."inner-id"',
        requested_id int path '$."requested-by".id',
        requested_short_name text path '$."requested-by"."short-name"',
        requested_short_code text path '$."requested-by"."short-code"',
        nested path '$.reviewed[*]' columns (
            dep_id for ordinality,
            dep_name text path '$.department',
            dep_code text path '$.code',
            nested path '$.reviewers[*]' columns(
                review_id for ordinality,
                user_id text path '$.id',
                role text path '$.role',
                review text path '$.review',
                review_date date path '$."created-at"'
            )
        )
    )) as flatten;


select * from mv_docs_flatten;

-- create index ... on mv_docs_flatten ...


refresh materialized view mv_docs_flatten;


--- pg_cron !!! AWS


select cron.schedule(
    'cron_job_refresh_mv_docs',
    '0 */6 * * *',
    'refresh materialized view mv_docs_flatten'
);


create extension pg_prewarm;


select cron.schedule(
    'cron_job_prewarn_docs_idx',
    '*/30 * * * *',
    'select pg_prewarm($$idx_doc_gin_jsonb_path$$);'
);
