

create table docs (
    id uuid primary key,
    doc jsonb not null compression lz4,
    created_at timestamp with time zone not null default current_timestamp,
    updated_at timestamp with time zone null
);

-- pglz
-- https://www.timescale.com/blog/optimizing-postgresql-performance-compression-pglz-vs-lz4



do $$

declare emails text[]; roles text[]; reviews text[];

begin

emails := array['ivan@acme.com', 'john@acme.com', 'marc@acme.com'];

select
jsonb_build_object(
  '__generated__', true, --!!!
  'id', x,
  'requested-at', jsonb_build_object(
    'id', x % 1000,
    'short-name', 'Mars Inc',
    'short-code', 'mars-inc'
  ),
  'sum', jsonb_build_array(
    jsonb_build_object(
      'amount', round(random() * x),
      'currency', 'usd',
      'period', '10 years'
    ),
    jsonb_build_object(
      'amount', round(random() * x),
      'currency', 'eur',
      'period', '15 years'
    )
  ),
  'reviewed', jsonb_build_array(
    jsonb_build_object(
      'department', 'Some Dep A',
      'code', 'dep-a',
      'reviewers', jsonb_build_array(
        jsonb_build_object(
          'id', emails[x % 3],
          'role', 'manager',
          'review', 'approve'
        ),
        jsonb_build_object(
          'id', 'john@acme.com',
          'role', 'analytic',
          'review', 'reject'
        )
      )
    ),
    jsonb_build_object(
      'department', 'Some Dep B',
      'code', 'dep-b',
      'reviewers', jsonb_build_array(
        jsonb_build_object(
          'id', 'marc@acme.com',
          'role', 'manager',
          'review', 'need-more-info'
        ),
        jsonb_build_object(
          'id', 'ivan@acme.com',
          'role', 'accounter',
          'review', 'approve'
        )
      )
    )
  )
) as doc
from
    generate_series(1, 5) as x;

end $$;
