

create table docs (
    id uuid primary key,
    doc jsonb compression lz4 not null,
    created_at timestamp with time zone not null default current_timestamp,
    updated_at timestamp with time zone null
);

-- pglz
-- https://www.timescale.com/blog/optimizing-postgresql-performance-compression-pglz-vs-lz4



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

-- 1M = 22 seconds


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



select
    id,

    doc #>> '{requested-by,id}'
    as requester_id,

    doc #>> '{requested-by,short-name}'
    as requester_name,

    doc #>> '{requested-by,short-code}'
    as requester_code,

    created_at

    from docs

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

    from docs

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


select
    id,

    doc #>> '{requested-by,short-name}'
    as requester_name,

    doc #>> '{requested-by,short-code}'
    as requester_code

from docs
order by doc #>> '{requested-by,short-code}' desc
limit 100;


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


create index if not exists idx_doc_inner_id_btree
    on docs using btree (((doc #>> '{inner-id}')::int));




select
    (doc #>> '{inner-id}')::int
    as inner_id,

    doc #>> '{requested-by,short-name}'
    as requester_name,

    doc #>> '{requested-by,short-code}'
    as requester_code

from docs
order by (doc #>> '{inner-id}')::int desc
limit 100;


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


-- JSON path


json @@ 'special language'


doc @@ '$.reviewed.reviewers.id == "ivan@acme.com"'


explain analyze
select doc['reviewed']
from docs
where doc @@ '$.reviewed.reviewers.id == "ivan@acme.com"'
limit 100;


                                                   QUERY PLAN
----------------------------------------------------------------------------------------------------------------
 Limit  (cost=0.00..15.08 rows=100 width=32) (actual time=0.036..0.278 rows=100 loops=1)
   ->  Seq Scan on docs  (cost=0.00..61709.00 rows=409091 width=32) (actual time=0.035..0.267 rows=100 loops=1)
         Filter: (doc @@ '($."reviewed"."reviewers"."id" == "ivan@acme.com")'::jsonpath)
         Rows Removed by Filter: 20
 Planning Time: 0.449 ms
 Execution Time: 0.302 ms


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


create index if not exists idx_doc_gin_jsonb_path
    on docs using gin (doc jsonb_path_ops);


-- slow
-- subset


create index if not exists idx_doc_gin_jsonb_path
    on docs using gin (doc['some']['attr'] jsonb_path_ops);



select doc['reviewed']
from docs
where doc @? '$.reviewed.reviewers ? (@.id == "ivan@acme.com" && @.role == "agent")';


 [{"code": "dep-a-5", "reviewers":  [{"id": "john@acme.com", "role": null, "review": "need-more-data"}, {"id": "john@acme.com", "role": null, "review": "accept"}], "department": "Department A 5"}, {"code": "dep-b-5", "reviewers": [{"id": null, "role": "accounter", "review": null}, {"id": "ivan@acme.com", "role": "agent", "review": null}], "department": "Department B 5"}]
 [{"code": "dep-a-9", "reviewers":  [{"id": "ivan@acme.com", "role": "agent", "review": "need-more-data"}, {"id": "john@acme.com", "role": "agent", "review": "reject"}], "department": "Department A 9"}, {"code": "dep-b-9", "reviewers": [{"id": "ivan@acme.com", "role": "agent", "review": "need-more-data"}, {"id": null, "role": "accounter", "review": null}], "department": "Department B 9"}]
 [{"code": "dep-a-10", "reviewers": [{"id": "john@acme.com", "role": "accounter", "review": "accept"}, {"id": "ivan@acme.com", "role": "agent", "review": null}], "department": "Department A 10"}, {"code": "dep-b-10", "reviewers": [{"id": null, "role": "manager", "review": "need-more-data"}, {"id": null, "role": "accounter", "review": "need-more-data"}], "department": "Department B 10"}]
 [{"code": "dep-a-11", "reviewers": [{"id": "ivan@acme.com", "role": "agent", "review": "need-more-data"}, {"id": null, "role": "owner", "review": "need-more-data"}], "department": "Department A 11"}, {"code": "dep-b-11", "reviewers": [{"id": "ivan@acme.com", "role": "agent", "review": null}, {"id": null, "role": "manager", "review": "need-more-data"}], "department": "Department B 11"}]
 [{"code": "dep-a-13", "reviewers": [{"id": "ivan@acme.com", "role": "accounter", "review": null}, {"id": null, "role": null, "review": "need-more-data"}], "department": "Department A 13"}, {"code": "dep-b-13", "reviewers": [{"id": "ivan@acme.com", "role": "agent", "review": "reject"}, {"id": "john@acme.com", "role": "accounter", "review": "reject"}], "department": "Department B 13"}]
 [{"code": "dep-a-15", "reviewers": [{"id": "ivan@acme.com", "role": "owner", "review": "reject"}, {"id": "ivan@acme.com", "role": "agent", "review": "need-more-data"}], "department": "Department A 15"}, {"code": "dep-b-15", "reviewers": [{"id": "ivan@acme.com", "role": "owner", "review": "reject"}, {"id": "john@acme.com", "role": null, "review": "reject"}], "department": "Department B 15"}]
 [{"code": "dep-a-18", "reviewers": [{"id": "ivan@acme.com", "role": "agent", "review": "need-more-data"}, {"id": null, "role": null, "review": "accept"}], "department": "Department A 18"}, {"code": "dep-b-18", "reviewers": [{"id": null, "role": "agent", "review": "accept"}, {"id": "ivan@acme.com", "role": null, "review": null}], "department": "Department B 18"}]
 [{"code": "dep-a-19", "reviewers": [{"id": null, "role": "agent", "review": "accept"}, {"id": null, "role": "owner", "review": "reject"}], "department": "Department A 19"}, {"code": "dep-b-19", "reviewers": [{"id": null, "role": null, "review": "need-more-data"}, {"id": "ivan@acme.com", "role": "agent", "review": "need-more-data"}], "department": "Department B 19"}]



select doc['reviewed']
from docs
where doc @? '$.reviewed ? (@.code == "dep-a-18").reviewers ? (@.id == "ivan@acme.com" && @.role == "agent")';


 [{"code": "dep-a-18", "reviewers": [{"id": "ivan@acme.com", "role": "agent", "review": "need-more-data"}, {"id": null, "role": null, "review": "accept"}], "department": "Department A 18"}, {"code": "dep-b-18", "reviewers": [{"id": null, "role": "agent", "review": "accept"}, {"id": "ivan@acme.com", "role": null, "review": null}], "department": "Department B 18"}]
 [{"code": "dep-a-18", "reviewers": [{"id": "ivan@acme.com", "role": "agent", "review": "accept"}, {"id": null, "role": "owner", "review": "need-more-data"}], "department": "Department A 18"}, {"code": "dep-b-18", "reviewers": [{"id": "john@acme.com", "role": "manager", "review": null}, {"id": "ivan@acme.com", "role": "manager", "review": "need-more-data"}], "department": "Department B 18"}]
 [{"code": "dep-a-18", "reviewers": [{"id": "ivan@acme.com", "role": "agent", "review": null}, {"id": "john@acme.com", "role": "owner", "review": "accept"}], "department": "Department A 18"}, {"code": "dep-b-18", "reviewers": [{"id": "ivan@acme.com", "role": "owner", "review": "accept"}, {"id": "ivan@acme.com", "role": null, "review": null}], "department": "Department B 18"}]
 [{"code": "dep-a-18", "reviewers": [{"id": "john@acme.com", "role": null, "review": "need-more-data"}, {"id": "ivan@acme.com", "role": "agent", "review": null}], "department": "Department A 18"}, {"code": "dep-b-18", "reviewers": [{"id": null, "role": "accounter", "review": "need-more-data"}, {"id": "john@acme.com", "role": "accounter", "review": "accept"}], "department": "Department B 18"}]



-- honeysql samples

(sql/register-op! :==)  -- ==
[:== foo bar] -> 'foo == bar'

(into [:||]
      (for [v value]
        [:== [:raw "@"] [:raw (util/to-json v)]]))

'@.foo == 1 || @.bar == 2 || @.lol == 3'


'@.foo == 1 && @.bar == 2 && @.lol == 3'


(sql/register-fn!
 :json#>>
 (fn [_ [field path]]
   (let [array (->array path)]
     (sql/format-expr [:nest [:#>> field array]]))))


[:json#>> field [:requested-by :id]]

'field #>> {requested-by,id}}'




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


-- map of index


-- reports
-- jsonb_query_elements

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
 3558257a-7426-4c44-a2e9-9ea7e112a02e | 260581 | eur      | 8 years
 3558257a-7426-4c44-a2e9-9ea7e112a02e | 140094 | eur      | 8 years
 5ce2b724-61d5-4ce7-9661-5163f067376d | 137629 | usd      | 9 years
 5ce2b724-61d5-4ce7-9661-5163f067376d | 231653 | eur      | 9 years
 12d4e215-ef56-4b1d-859e-9d438826e60b | 246181 | usd      | 10 years
 12d4e215-ef56-4b1d-859e-9d438826e60b | 132875 | lir      | 10 years
 bca04255-baca-4b07-b9e8-b4e1a00280a6 | 234387 | rub      | 11 years
 bca04255-baca-4b07-b9e8-b4e1a00280a6 | 20731  | rub      | 11 years
 c699f764-51e7-440e-8104-d5450a9392ac | 274868 | lir      | 12 years
 c699f764-51e7-440e-8104-d5450a9392ac | 222567 | usd      | 12 years
 7009bcab-cf93-44e4-955b-003751282cbb | 107498 | lir      | 13 years
 7009bcab-cf93-44e4-955b-003751282cbb | 184200 | lir      | 13 years


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
                review_date date path '$."created-at"' -- !!!
            )
        )
    )) as flatten
limit
    1000;


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
                review_date date path '$."created-at"' -- !!!
            )
        )
    )) as flatten;


select * from mv_docs_flatten;

-- create index ... on mv_docs_flatten ...


refresh materialized view mv_docs_flatten;


pg_cron !!!


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
