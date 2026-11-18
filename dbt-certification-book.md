# The dbt Certification Book

*A study book for the dbt Analytics Engineering Certification Exam, built
from the official exam topic outline and the dbt material in this notes
archive.*

*First edition, November 2026: 8 exam chapters, 64 chapter drills, a 65-question
mock exam and 4 appendices.*

---

## About This Book

This book is laid out like the exam. There is **one chapter per exam topic**,
in the order the official study guide lists them. Every sub-topic in the
guide gets its own section. The content comes from two places:

1. **The official topic outline** in the dbt Labs study guide (V.6.0). It
   sets the scope: what goes in, what stays out, and how deep each topic goes.
2. **The dbt Agenda Book** (`dbt-agenda-book.md`) and the daily notes behind
   it. These supply the explanations, the code and the gotchas. Each section
   names the Agenda Book session it comes from, so you can read further there.

The Agenda Book tries to teach dbt in full. This book only teaches what the
exam tests. It cuts Part X (the dbt platform UI), Iceberg, the Semantic Layer
internals and the v2 migration, and it goes deeper on what the exam likes to
ask: selector syntax, test configs, `ref`/`source` resolution, state
selectors, and reading error messages.

### How each chapter is laid out

- **Exam objectives**: the sub-topics from the official guide, word for word.
- **Sections**: one per objective. Each has the mechanics, then **Exam
  traps**, which are the distinctions questions are written around.
- **Drill**: 8 practice questions in the exam's formats. Answers and
  explanations follow straight after.

### Version note

The V.6.0 study guide says the exam **supports dbt Core 1.7**. Newer versions
of the guide (2026) add topics that came after 1.7: **Python models,
snapshots configured in YAML, the `microbatch` incremental strategy, behaviour
change flags, `dbt clone` and `dbt retry`**. The book covers all of them.
Anything newer than 1.7 is tagged inline, for example `(1.8+)` or `(1.9+)`.
When the exam and the current dbt release disagree, the book gives the exam
answer and notes what changed.

> The dbt landscape in 2026 also includes **dbt Core v2 / Fusion**, the Rust
> engine (Agenda Book Session 1.2 and Part XII). The exam does not test it.
> Learn the Python-engine (`dbt-core` 1.x) behaviour for the exam.

---

## The Exam at a Glance

| Item | Value |
|---|---|
| Questions | 65 (plus an undisclosed number of unscored research items, indistinguishable from scored ones) |
| Time | 2 hours, which is about 110 seconds per question |
| Passing score | 65% or higher; you see your score straight away |
| Scoring | 1 point per correct answer, 0 per wrong answer, all weighted equally, **no partial credit** |
| Price | $200 per attempt (retakes are paid again) |
| Delivery | Online proctored (Talview), English only, Caveon-supported browsers |
| Validity | 2 years from the award date |
| Recommended experience | SQL proficiency plus 6 or more months of hands-on dbt (Core or Cloud) |
| Prerequisite SQL | Joins, aggregations, CTEs, window functions |
| Prerequisite git | Branching (development vs main), basic commands, pull requests |

### Question formats

| Format | What it looks like | How to approach it |
|---|---|---|
| Multiple choice | One correct option | Eliminate options first, then pick |
| Multiple select | "Choose two" or "choose all that apply" | Every choice must be right; one wrong pick loses the whole point |
| Fill-in-the-blank | Complete a command, config key or Jinja call | Exact syntax counts: `+materialized`, `--select`, `state:modified+` |
| Matching | Pair terms with definitions | Do the pairs you are sure of first, then match the rest by elimination |
| Hotspot | Click the wrong line in code or YAML, or the right node in a DAG | Read line by line; the fault is usually indentation, a missing `-`, or a hard-coded table name |
| Build list | Put steps in order | Think about what each step needs as input |
| **DOMC** (Discrete Option Multiple Choice) | Options appear **one at a time**. You answer Yes or No to each and can't go back | Judge each option on its own merits. The item can end early, so you will not always see the right option |

**DOMC is the format that catches people out.** You can't compare options
side by side. Before the first option appears, decide what a correct answer
would have to contain. Then test each option against that.

### Exam topics (official V.6.0 outline)

| # | Topic | Chapter |
|---|---|---|
| 1 | Developing dbt models | 1 |
| 2 | Understanding dbt model governance | 2 |
| 3 | Debugging data modeling errors | 3 |
| 4 | Managing data pipelines | 4 |
| 5 | Implementing dbt tests | 5 |
| 6 | Creating and maintaining dbt documentation | 6 |
| 7 | Implementing and maintaining external dependencies | 7 |
| 8 | Leveraging the dbt state | 8 |

The guide does not publish per-topic weightings. **Topic 1 is the largest by
a wide margin**: it has 12 sub-topics, while the others have 2 to 5 each.
Expect about a third of the exam to come from it.

---

## Study Plan

The plan takes 4 weeks at about 1 hour a day. Build a small dbt project
alongside it. The Jaffle Shop sample or any warehouse free tier works. The
exam expects hands-on experience, and many questions are easy only if you
have actually seen the error.

| Week | Read | Do in a real project |
|---|---|---|
| 1 | Chapter 1, sections 1.1 to 1.6 | Create a project from scratch: sources, staging, marts. Run `run`, `test`, `seed`, `docs generate` |
| 2 | Chapter 1, sections 1.7 to 1.12, plus Chapter 5 | Add packages, a Python model, grants and a snapshot. Write every kind of test |
| 3 | Chapters 2, 3, 4 | Add a contract, a version and access levels. Break things on purpose and read the errors. Use `dbt clone` |
| 4 | Chapters 6, 7, 8, then the mock exam | Exposures, freshness, `state:modified`, `dbt retry`. Take the mock under a 2-hour timer |

**Target score on the mock: 80% or more.** The real exam's DOMC format and
unfamiliar wording usually cost 10 to 15 points compared with a practice test.

---
# Chapter 1 — Developing dbt Models

*Exam Topic 1. This is the largest topic: 12 sub-topics, and it underlies
every other chapter.*

**Exam objectives**

- Identifying and verifying any raw object dependencies
- Understanding core dbt materializations
- Conceptualizing modularity and how to incorporate DRY principles
- Converting business logic into performant SQL queries
- Using commands such as run, test, docs and seed
- Creating a logical flow of models and building clean DAGs
- Defining configurations in `dbt_project.yml`
- Configuring sources in dbt
- Using dbt Packages
- Utilizing git functionality within the development lifecycle
- Creating Python models
- Providing access to users to models with the "grants" configuration

---

## 1.1 Raw Object Dependencies: `ref` and `source`

*Agenda Book: Sessions 1.1, 2.1*

dbt builds its DAG **only from `ref()` and `source()` calls**. A table name
written directly into SQL, such as `from analytics.orders`, is invisible to
dbt. The model will compile and may even run, but dbt will not order it after
its upstream model, and lineage will not show the dependency.

```sql
-- models/marts/accounts.sql
select
    c.customer_id,
    o.order_id
from {{ ref('stg_customers') }} as c            -- model -> model
join {{ ref('stg_orders') }}    as o using (customer_id)
```

```sql
-- models/staging/stg_orders.sql
select * from {{ source('shop', 'orders') }}    -- raw table -> model
```

| Function | Points to | Resolves to | Adds a DAG edge |
|---|---|---|---|
| `ref('model')` | Another dbt model, seed or snapshot | The relation in the **current target's** schema (or the deferred relation) | Yes |
| `ref('project', 'model')` | A model in another project (Mesh) | That project's relation | Yes |
| `ref('model', v=2)` | A specific model version | `model_v2` (or its alias) | Yes |
| `source('src', 'table')` | A raw table declared in YAML | `database.schema.identifier` from the source YAML | Yes (a source node) |

**Verifying dependencies**

- `dbt ls --select +my_model` lists everything upstream.
- `dbt compile --select my_model`, then open `target/compiled/...`. Every
  `ref`/`source` should have become a fully qualified name.
- In the docs site lineage graph, a model with no inbound edges that should
  have one means a hard-coded table name.

**Exam traps**

- *"Model C runs before model A finishes."* The cause is nearly always a
  hard-coded table name in C. The fix: replace **every** hard-coded reference
  with `ref`, in the `from` **and** in every `join`. This is official sample
  question 4.
- `ref` goes to models, seeds and snapshots. `source` goes to raw tables
  that dbt does not build. Never `ref` a raw table, and never `source` a model.
- A `ref` to a model that does not exist fails **at parse/compile time**
  (`Model 'model.x' depends on a node named 'y' which was not found`), not
  in the warehouse.
- Seeds and snapshots are `ref`'d, **not** `source`'d.

---

## 1.2 Core Materializations

*Agenda Book: Sessions 1.4, 3.1 to 3.4*

| Materialization | What dbt creates | Rebuild cost | Use when |
|---|---|---|---|
| `view` (default) | `create view as` | None at run time; the query runs on every read | Light transforms, staging models |
| `table` | `create table as` (full rebuild each run) | Full | Marts queried often, or slow views |
| `incremental` | Table on the first run; afterwards inserts or merges only new/changed rows | Small | Large, append-heavy tables (events, logs) |
| `ephemeral` | Nothing. Injected as a CTE into downstream models | None | Light reusable logic you don't want in the warehouse |
| `materialized_view` (1.6+) | Warehouse-managed MV / dynamic table | Warehouse-managed | Near-real-time on supported platforms |

Snapshots are not a materialization config; they are their own resource
type (section 1.2.3).

### 1.2.1 Incremental models

```sql
{{ config(
    materialized='incremental',
    unique_key='order_id',
    incremental_strategy='merge',
    on_schema_change='append_new_columns'
) }}

select * from {{ ref('stg_orders') }}

{% if is_incremental() %}
  where updated_at > (select max(updated_at) from {{ this }})
{% endif %}
```

- `is_incremental()` is **true only when** all of these hold: the target
  table already exists, it is a table (not a view), the model is
  `materialized='incremental'`, and `--full-refresh` was **not** passed.
- `{{ this }}` is the model's own existing relation in the warehouse.
- `unique_key` turns appends into upserts. Without it, `merge`/`append` just
  inserts, which can create duplicates.
- `dbt run --full-refresh -s my_model` drops and rebuilds from scratch.
- **`incremental_strategy`** values depend on the adapter: `append`, `merge`,
  `delete+insert`, `insert_overwrite`, and `microbatch` (1.9+).
- **`on_schema_change`** decides what happens when the model's columns change:
  `ignore` (the default: new columns are dropped silently), `fail`,
  `append_new_columns`, `sync_all_columns`.

**Microbatch (1.9+)**: `incremental_strategy='microbatch'` with an
`event_time` column, `batch_size` (`hour`/`day`/`month`/`year`), `begin` and
an optional `lookback`. dbt splits the work into time batches, which you can
backfill with `--event-time-start` / `--event-time-end` and retry one batch at
a time. You don't write an `is_incremental()` filter; dbt adds it.

### 1.2.2 Ephemeral models

- These are inlined as a CTE named `__dbt__cte__<model>` in every model that
  `ref`s them.
- **They can't be queried** directly, **can't** be the target of
  `dbt run-operation` queries, and **don't support** `grants` or contracts.
  Tests on them are limited.
- Heavy use makes compiled SQL hard to debug.

### 1.2.3 Snapshots (SCD Type 2)

```yaml
# snapshots/orders_snapshot.yml   (1.9+ YAML spec)
snapshots:
  - name: orders_snapshot
    relation: source('shop', 'orders')
    config:
      schema: snapshots
      unique_key: order_id
      strategy: timestamp          # or: check
      updated_at: updated_at       # timestamp strategy
      # check_cols: [status, amount]  # check strategy
      hard_deletes: invalidate     # ignore | invalidate | new_record (1.9+)
```

In 1.7 (the exam's base version) snapshots live in `.sql` files inside a
`{% snapshot %}` block, with `target_schema` and `target_database` set in the
config.

- `dbt snapshot` adds the columns `dbt_scd_id`, `dbt_updated_at`,
  `dbt_valid_from` and `dbt_valid_to`. The current row has
  `dbt_valid_to = null` (configurable in 1.9+ with `dbt_valid_to_current`).
- **`timestamp`** strategy: compares `updated_at`. It is reliable and preferred.
- **`check`** strategy: compares listed columns (or `all`). Use it when there
  is no trustworthy timestamp.
- Snapshots should select from **sources**, with as little transformation as
  possible, because history you didn't capture can't be recreated.

**Exam traps**

- "Millions of rows, new rows appended, old rows never updated" is the
  textbook case for `incremental` (official sample question 2).
- `view` is the default when nothing is configured.
- Changing a model from `view` to `table` needs no full refresh. Changing an
  incremental model's logic **does** need `--full-refresh` to backfill history.
- Ephemeral models don't exist in the warehouse, so a BI tool can't read them.

---

## 1.3 Modularity and DRY

*Agenda Book: Sessions 1.3, 5.1, 5.7*

**DRY (Don't Repeat Yourself)** in dbt means that each piece of logic lives in
one place and everything else refers to it.

| Repetition | DRY tool |
|---|---|
| The same cleaning/renaming of a raw table in several models | One **staging model**, `ref`'d everywhere |
| The same join or business rule in several marts | An **intermediate model** |
| The same SQL expression (cents to dollars, date spine) | A **macro** |
| A common pattern someone already wrote | A **package** macro (`dbt_utils.generate_surrogate_key`) |
| The same config on many models | **Folder-level config** in `dbt_project.yml` |
| The same YAML block | YAML anchors, or a generic test |

```sql
-- macros/cents_to_dollars.sql
{% macro cents_to_dollars(column_name, scale=2) %}
    round({{ column_name }} / 100.0, {{ scale }})
{% endmacro %}
```

```sql
select {{ cents_to_dollars('amount_cents') }} as amount from {{ ref('stg_payments') }}
```

**Jinja essentials the exam uses**

| Syntax | Meaning |
|---|---|
| `{{ ... }}` | Expression: print a value |
| `{% ... %}` | Statement: `if`, `for`, `set`, `macro` |
| `{# ... #}` | Comment, not rendered into SQL |
| `{%- ... -%}` | Strip whitespace |
| `{{ var('x') }}` / `{{ env_var('X') }}` | Project variable / environment variable |
| `{{ target.name }}` / `{{ target.schema }}` | The active target from `profiles.yml` |
| `{{ this }}` | The current model's relation |
| `{% if execute %}` | Guards code that needs query results (`run_query`) during parsing |

```sql
{% set payment_methods = ['credit_card', 'coupon', 'bank_transfer'] %}
select
    order_id,
    {% for m in payment_methods %}
    sum(case when payment_method = '{{ m }}' then amount end) as {{ m }}_amount
    {%- if not loop.last %},{% endif %}
    {% endfor %}
from {{ ref('stg_payments') }}
group by 1
```

**Exam traps**

- A `ref` inside a **macro** still creates a dependency, but only when the
  macro is called from a model. dbt parses models statically, so a `ref`
  built dynamically from a string may need a `-- depends_on: {{ ref('x') }}`
  hint.
- Too much abstraction is also wrong. The guide's DRY questions favour
  readable SQL, and a macro for a one-line expression used once is not "more
  correct".

---

## 1.4 Business Logic into Performant SQL

*Agenda Book: Sessions 1.3, 11.5*

The exam expects **CTE-structured models** in the dbt style:

```sql
with

orders as (
    select * from {{ ref('stg_orders') }}
),

payments as (
    select * from {{ ref('stg_payments') }}
),

order_payments as (
    select order_id, sum(amount) as amount
    from payments
    where status = 'success'
    group by 1
),

final as (
    select
        orders.order_id,
        orders.customer_id,
        orders.order_date,
        coalesce(order_payments.amount, 0) as amount
    from orders
    left join order_payments using (order_id)
)

select * from final
```

**Conventions**

- **Import CTEs** at the top: one `select * from {{ ref() }}` per input.
- **Logical CTEs** do one transformation each.
- A **`final` CTE** then `select * from final`.
- **Filter and aggregate early**: before joins, not after.
- **Join on keys at the same grain**. Joining two one-to-many tables fans
  out rows and inflates `sum()`.
- Use **window functions** (`row_number() over (partition by ... order by ...)`)
  for dedup, latest-record and running totals, not self-joins.

**Performance levers in dbt**

| Problem | Lever |
|---|---|
| A view is slow to query downstream | `table` |
| A table is slow to rebuild | `incremental` |
| A huge table scan | Warehouse configs: `cluster_by`, `partition_by`, `sort`/`dist` |
| An expensive CTE reused in several models | Promote it to its own model (table) |
| Too many threads or too few | `threads:` in `profiles.yml` |

**Exam traps**

- `select distinct` used to "fix" duplicates hides a fan-out join. The right
  answer is to fix the join grain.
- `union` removes duplicates and `union all` does not. Assume `union all`
  unless dedup is the goal.

---

## 1.5 Core Commands

*Agenda Book: Sessions 9.1, 9.3, Appendix A*

| Command | What it does | Note |
|---|---|---|
| `dbt init` | Scaffold a new project and profile | |
| `dbt debug` | Test the connection and profile | First command when "nothing works" |
| `dbt deps` | Install `packages.yml` packages into `dbt_packages/` | Run after any change to `packages.yml` |
| `dbt parse` | Parse the project and write `manifest.json` | Catches YAML/Jinja errors fast |
| `dbt compile` | Render Jinja to SQL in `target/compiled/` | Does **not** run anything (except introspective queries) |
| `dbt run` | Build models (views, tables, incremental) | Models only |
| `dbt test` | Run data tests (and unit tests, 1.8+) | |
| `dbt seed` | Load CSVs from `seeds/` into tables | |
| `dbt snapshot` | Run snapshots | |
| `dbt build` | **run + test + seed + snapshot** (and unit tests), in DAG order | Tests run straight after their parent; a failure **skips** downstream nodes |
| `dbt docs generate` | Write `catalog.json` + `manifest.json` + `index.html` | Queries the warehouse for column metadata |
| `dbt docs serve` | Serve the docs site locally | |
| `dbt source freshness` | Check `loaded_at_field` against thresholds | Writes `sources.json` |
| `dbt run-operation macro --args '{k: v}'` | Run a macro outside a model | Grants, cleanup, admin |
| `dbt show --select model` / `--inline "sql"` | Preview results | 1.5+ |
| `dbt ls` | List resources matching a selector | Doesn't run anything |
| `dbt clean` | Delete `clean-targets` (`target/`, `dbt_packages/`) | |
| `dbt retry` | Re-run from the point of failure of the last command | Chapter 8 |
| `dbt clone` | Zero-copy clone of nodes from a state | Chapter 4 |

**Common flags**

| Flag | Effect |
|---|---|
| `-s` / `--select` | Choose nodes |
| `--exclude` | Remove nodes |
| `--selector name` | Use a named selector from `selectors.yml` |
| `--full-refresh` | Rebuild incremental models and seeds from scratch |
| `-t` / `--target` | Choose a `profiles.yml` output |
| `--vars '{key: value}'` | Override `var()` |
| `--fail-fast` / `-x` | Stop at the first failure |
| `--threads N` | Parallelism |
| `--defer --state path` | Resolve unbuilt `ref`s to production (Chapter 8) |
| `--empty` (1.8+) | Build with zero rows (schema-only dry run) |

### Node selection syntax

| Syntax | Selects |
|---|---|
| `my_model` | That model |
| `+my_model` | It and **all ancestors** |
| `my_model+` | It and **all descendants** |
| `2+my_model` / `my_model+1` | Ancestors 2 levels up / descendants 1 level down |
| `@my_model` | It, its descendants, **and all ancestors of those descendants** |
| `path:models/staging` or `models/staging` | Everything in a folder |
| `tag:nightly` | Everything with the tag |
| `source:shop+` | Everything downstream of a source |
| `resource_type:snapshot` / `test_type:unit` | By type |
| `config.materialized:incremental` | By config |
| `package:dbt_utils` | By package |
| `state:modified` / `result:error` | Chapter 8 |
| `a b` (space) | **Union**: a OR b |
| `a,b` (comma) | **Intersection**: a AND b |

**Exam traps**

- `dbt run` builds **models only**. It doesn't load seeds, run snapshots or
  run tests. `dbt build` does all of them.
- In `dbt build`, a **failing test skips downstream models**. With
  `dbt run && dbt test`, the bad data has already reached downstream tables
  before any test runs.
- `dbt compile` does not create objects. `dbt docs generate` needs a
  connection, because it reads the warehouse catalog.
- `tag:a,tag:b` means **both** tags. `tag:a tag:b` means **either** tag.
- `dbt seed --full-refresh` drops and recreates seed tables. You need it when
  a seed's column types change.

---

## 1.6 Logical Flow and Clean DAGs

*Agenda Book: Session 1.3*

```
sources ──► staging (stg_) ──► intermediate (int_) ──► marts (fct_ / dim_) ──► exposures
             1:1 with source     joins, reshaping        business entities
             rename, cast        not exposed to users    what BI reads
             view                ephemeral/view          table/incremental
```

| Layer | Rule |
|---|---|
| Staging | **One staging model per source table.** The only layer that calls `source()`. Rename, cast, light cleaning; no joins, no aggregations |
| Intermediate | Join, pivot, re-grain. Named `int_<entity>_<verb>s`. Usually not exposed |
| Marts | `fct_` (events, facts) and `dim_` (entities). Wide, denormalised, what consumers query |

**DAG smells the exam asks about**

| Smell | Fix |
|---|---|
| A mart selects from `source()` directly | Route it through a staging model |
| Two models both clean the same source table | Merge them into one staging model |
| A "rejoin": a model joins A and also a descendant of A | Restructure so the path is linear |
| Bending lines: staging `ref`s a mart | Move the logic downstream; dependencies only flow forward |
| A circular `ref` | dbt refuses to run: `Found a cycle` |

**Exam traps**

- The DAG must be **acyclic**. A cycle is a **compile** error.
- "Only staging models reference sources" is the convention the exam
  assumes. The `dbt_project_evaluator` package enforces it.

---

## 1.7 Configuring in `dbt_project.yml`

*Agenda Book: Sessions 6.2, 6.3, Appendix B*

```yaml
name: jaffle_shop               # must match the key under models:
version: '1.0.0'
config-version: 2
profile: jaffle_shop            # which profiles.yml entry to use

model-paths: ["models"]
seed-paths: ["seeds"]
test-paths: ["tests"]
macro-paths: ["macros"]
snapshot-paths: ["snapshots"]
analysis-paths: ["analyses"]
target-path: "target"
clean-targets: ["target", "dbt_packages"]

vars:
  start_date: '2024-01-01'

models:
  jaffle_shop:                  # project name
    +materialized: view         # applies to all models
    staging:
      +schema: staging
    marts:
      +materialized: table
      finance:
        +tags: ['finance']
        +grants:
          select: ['reporter']

seeds:
  jaffle_shop:
    +schema: seeds
    country_codes:
      +column_types:
        code: varchar(2)
```

**Config precedence** (most specific wins):

1. `{{ config() }}` in the model file
2. The model's YAML `config:` block (properties file)
3. The `dbt_project.yml` folder path, most specific folder first
4. The `dbt_project.yml` project level
5. dbt defaults

The **`+` prefix** marks a key as a config and not a sub-folder name. You
always need it for configs whose names could clash with folder names, and it
is good practice everywhere.

**Custom schemas.** `+schema: staging` produces `<target_schema>_staging`,
not `staging`. The default `generate_schema_name` macro **concatenates**.
Override that macro to change the behaviour (for example, a bare `staging` in
prod).

| Config | Default behaviour |
|---|---|
| `schema` | `target.schema` + `_` + custom |
| `database` | `target.database` unless set |
| `alias` | The file name unless set |

**Exam traps**

- The key under `models:` must be the **project name**, not a folder.
  Otherwise the config silently does nothing.
- Configs such as `tags` and `meta` are **additive** across levels. Most
  others **override**.
- `vars` set in `dbt_project.yml` are overridden by `--vars` on the CLI.
- `profile:` names a block in `profiles.yml`. The profile holds credentials,
  `dbt_project.yml` never does.

---

## 1.8 Configuring Sources

*Agenda Book: Session 2.1*

```yaml
# models/staging/shop/_shop__sources.yml
version: 2

sources:
  - name: shop                  # the name used in source('shop', ...)
    database: raw               # optional; defaults to target.database
    schema: shopify             # defaults to the source name
    loader: fivetran
    loaded_at_field: _synced_at # (1.9+: also settable under config:)
    freshness:
      warn_after: {count: 12, period: hour}
      error_after: {count: 24, period: hour}
    tables:
      - name: orders
        identifier: shopify_orders_v2   # real table name, if different
        description: One row per order.
        columns:
          - name: id
            data_tests: [unique, not_null]
      - name: customers
        freshness: null         # opt this table out
```

- **One source = one database + schema.** The tables sit under it.
- `name` is the logical name and `identifier` is the physical table name.
- Freshness, tests and descriptions can be set at the source or table level.
  The table level overrides.

**Exam traps**

- Official sample question 5: queries reference `sample_data.public.customers`,
  `orders`, `nations` and `regions`. That is **one source** with **four
  tables**, because they all share one database and schema.
- `source()` takes **two** arguments: the source name, then the table name.
- Moving a raw table to a new schema means editing **one line of YAML**.
  That is the point of sources.

---

## 1.9 dbt Packages

*Agenda Book: Session 5.7*

```yaml
# packages.yml  (or dependencies.yml, 1.6+)
packages:
  - package: dbt-labs/dbt_utils        # dbt Hub
    version: [">=1.1.0", "<2.0.0"]
  - git: "https://github.com/org/internal-macros.git"
    revision: v0.4.2                   # tag, branch or commit SHA
  - local: ../shared_macros            # path on disk
```

- Run **`dbt deps`** to install into `dbt_packages/`. Do this after every
  change, and in every fresh CI or prod environment.
- Use package macros with a namespace: `{{ dbt_utils.star(ref('x')) }}`.
- Package models build as part of your project. Disable them with
  `models: { package_name: { +enabled: false } }`.
- `package-lock.yml` (1.7+) pins resolved versions; commit it.
- **`dependencies.yml`** can hold `projects:` (Mesh cross-project refs) as
  well as packages. `packages.yml` cannot hold `projects:`.

| Package | Known for |
|---|---|
| `dbt_utils` | `generate_surrogate_key`, `star`, `date_spine`, `pivot`, `union_relations`, tests such as `expression_is_true`, `accepted_range`, `unique_combination_of_columns` |
| `dbt_expectations` | Great-Expectations-style tests |
| `codegen` | Generates source YAML and base models |
| `audit_helper` | Compares relations when refactoring |
| `dbt_project_evaluator` | Lints the DAG against best practices |

**Exam traps**

- `dbt_packages/` should be in `.gitignore`. It is a build artefact.
- "Macro not found" after adding a package means `dbt deps` wasn't run.
- Git packages need `revision:`. Hub packages use `version:`.

---

## 1.10 Git in the Development Lifecycle

*Agenda Book: Session 9.10*

```
main (protected) ──────────────●──────────────●────► deployed to prod
                     \        / merge PR      /
feature/add-orders    ●──●──●                /
                             \ CI: dbt build state:modified+ against a PR schema
```

| Command | Does |
|---|---|
| `git clone <url>` | Copy the remote repo locally |
| `git checkout -b feature/x` | Create and switch to a branch |
| `git status` / `git diff` | What changed |
| `git add` / `git commit -m` | Stage / record changes |
| `git push origin feature/x` | Publish the branch |
| `git fetch` | Download remote changes **without** merging |
| **`git pull`** | **`fetch` + `merge`**: bring remote changes into the current branch |
| `git merge main` | Merge main into your branch to resolve conflicts locally |

**Workflow**: branch from `main`, develop in your **dev target/schema**, open
a **pull request**, CI builds and tests the changed models in a temporary
schema, review, merge, and the prod job runs from `main`.

**Exam traps**

- Official sample question 3: "get your colleague's pushed changes into your
  local branch" is answered by **`git pull`**.
- Every developer has their **own dev schema** (`dbt_<name>`) so they don't
  overwrite each other's work. That is set by `target.schema`.
- Never develop directly on `main`. dbt Cloud's IDE blocks commits to a
  protected `main`.

---

## 1.11 Python Models

*Agenda Book: Session 11.1*

```python
# models/marts/customer_clusters.py
def model(dbt, session):
    dbt.config(materialized="table", packages=["scikit-learn"])

    customers = dbt.ref("dim_customers").to_pandas()   # Snowflake: Snowpark DF
    # src = dbt.source("shop", "orders")

    from sklearn.cluster import KMeans
    customers["cluster"] = KMeans(n_clusters=4).fit_predict(
        customers[["lifetime_value", "order_count"]]
    )
    return customers                                  # must return a DataFrame
```

- A Python model is a file defining **`def model(dbt, session):`** that
  **returns a DataFrame**.
- It uses `dbt.ref()`, `dbt.source()` and `dbt.config()`, the Python
  versions of the Jinja calls.
- It is supported on **Snowflake (Snowpark), Databricks (PySpark) and
  BigQuery (Dataproc/BigFrames)**. Postgres and Redshift are not supported.
- Materializations: **`table` or `incremental` only**. No views, no ephemeral.
- **No Jinja** in `.py` models. Use `dbt.config.get()` and `dbt.this`.
- `dbt.is_incremental` is a property, not a function.

**Exam traps**

- Python models are for what SQL can't do well: ML, statistics, complex
  parsing. Don't use them for plain joins.
- Python models can be `ref`'d by SQL models and the other way round. They
  sit in the same DAG.

---

## 1.12 Grants

*Agenda Book: Session 6.5*

```yaml
# dbt_project.yml
models:
  jaffle_shop:
    marts:
      +grants:
        select: ['reporter', 'bi_user']
```

```sql
{{ config(grants = {'select': ['data_science']}) }}
```

- dbt applies grants **after** building the object, on every run.
- The config is a mapping of `privilege: [grantees]`.
- **Most specific wins, and grants replace**: a model-level `grants`
  replaces a project-level one. To **add** to it, use the `+` prefix inside
  the value: `grants: {'+select': ['extra_role']}`.
- dbt **revokes** grants it previously gave that are no longer in config,
  but leaves grants it didn't manage. Behaviour differs slightly by adapter.
- Grants work on **seeds, snapshots and models**. They don't work on
  ephemeral models, because there is no object to grant on.

**Exam traps**

- Use `grants`, not a `post-hook` with `grant select ...`. The hook is the
  old pattern and doesn't revoke.
- `copy_grants` (Snowflake) keeps grants across `create or replace`. It is a
  different config.

---

## Chapter 1 Drill

**Q1.1 (Multiple choice).** `fct_revenue` sometimes runs before `int_payments`
finishes, and reads stale data. What is the most likely cause?

A. `int_payments` is materialized as ephemeral
B. `fct_revenue` references `analytics.int_payments` directly instead of `ref('int_payments')`
C. `threads` is set too high
D. `int_payments` has no tests

**Q1.2 (Multiple select, choose two).** Which statements about `is_incremental()` are true?

A. It returns true on the first run of an incremental model
B. It returns false when `--full-refresh` is passed
C. It returns false if the existing relation is a view
D. It returns true for any model with `unique_key` set

**Q1.3 (Fill in the blank).** To build `stg_orders` and everything downstream
of it, run: `dbt build --select ________`.

**Q1.4 (Multiple choice).** With `+schema: marketing` set and a target schema
of `dbt_alice`, where does the model build by default?

A. `marketing`
B. `dbt_alice`
C. `dbt_alice_marketing`
D. `marketing_dbt_alice`

**Q1.5 (DOMC).** Is this a valid way to make a Python model's output available? *"Return a pandas or Snowpark DataFrame from `def model(dbt, session)`."* Yes or No?

**Q1.6 (Multiple choice).** A teammate pushed a fix to the remote `feature/x`
branch you are both working on. What brings it into your local copy?

A. `git fetch`
B. `git push`
C. `git pull`
D. `git clone`

**Q1.7 (Matching).** Match each selector to what it selects.

| Selector | | Meaning |
|---|---|---|
| 1. `tag:a,tag:b` | | W. Models with tag a or tag b |
| 2. `tag:a tag:b` | | X. Models with both tag a and tag b |
| 3. `@m` | | Y. m, its descendants, and the ancestors of those descendants |
| 4. `+m` | | Z. m and its ancestors |

**Q1.8 (Multiple choice).** A project-level config grants `select` to
`reporter`. One model sets `grants: {'select': ['finance']}`. Who gets `select`
on that model?

A. `reporter` and `finance`
B. `finance` only
C. `reporter` only
D. Nobody; the configs conflict and dbt errors

### Answers

| Q | Answer | Why |
|---|---|---|
| 1.1 | **B** | dbt only knows the dependency through `ref`. A hard-coded name has no DAG edge, so ordering isn't guaranteed |
| 1.2 | **B, C** | It is false on the first run (the table doesn't exist yet), false with `--full-refresh`, and false when the existing relation is a view. `unique_key` has nothing to do with it |
| 1.3 | **`stg_orders+`** | A trailing `+` means descendants |
| 1.4 | **C** | The default `generate_schema_name` concatenates the target schema and the custom schema |
| 1.5 | **Yes** | A Python model must return a DataFrame |
| 1.6 | **C** | `pull` = `fetch` + `merge`. `fetch` alone doesn't update your working branch |
| 1.7 | **1-X, 2-W, 3-Y, 4-Z** | A comma is an intersection and a space is a union |
| 1.8 | **B** | The more specific `grants` **replaces**. To add to it, use `'+select'` |

---
# Chapter 2 — Model Governance

*Exam Topic 2. There are only three sub-topics, but questions on them are
precise about syntax and behaviour.*

**Exam objectives**

- Adding contracts to models to ensure the shape of models
- Creating different versions of our models and deprecating the old ones
- Configuring model access

Newer versions of the guide also list **behaviour change flags** under
governance. They are covered in section 2.4.

---

## 2.1 Model Contracts

*Agenda Book: Session 7.1. The archive covers this most heavily (46 notes).*

A contract is a **promise about a model's shape**: which columns, in what
data types, under what constraints. dbt checks the promise **before** the
model is built. If the SQL doesn't return exactly those columns and types,
the build fails and the existing table is left untouched.

```yaml
# models/marts/_marts__models.yml
models:
  - name: dim_customers
    config:
      contract:
        enforced: true
    columns:
      - name: customer_id
        data_type: int
        constraints:
          - type: not_null
          - type: primary_key
      - name: email
        data_type: varchar
      - name: lifetime_value
        data_type: numeric(38, 2)
```

**What enforcement checks**

| Check | When | Result if broken |
|---|---|---|
| Column **names** match the YAML (all of them, no extras, none missing) | Before the build (pre-flight) | `Contract Error ... missing / extra columns` |
| Column **data types** match | Before the build | `Contract Error ... data type mismatch` |
| **Constraints** (`not_null`, `primary_key`, `foreign_key`, `unique`, `check`) | Created as DDL; **enforced by the warehouse** at insert time | Depends on the platform |

**Constraints and platforms.** dbt puts constraints into the DDL. Whether the
warehouse *enforces* them is up to the warehouse:

| Platform | `not_null` | `primary_key` / `unique` / `foreign_key` |
|---|---|---|
| Postgres | Enforced | Enforced |
| Snowflake | Enforced | **Defined but not enforced** |
| BigQuery | Enforced | Not enforced |
| Redshift | Enforced | Not enforced |
| Databricks | Enforced | Informational (`check` is enforced) |

**Requirements and limits**

- **Every column** must be listed with a `data_type`.
- Works with `table`, `incremental` and `view` materializations (views check
  names and types only; constraints don't apply to them). **Not supported:
  `ephemeral` and Python models.**
- For incremental models, set **`on_schema_change: append_new_columns`**
  or **`fail`**. The default, `ignore`, conflicts with a contract, because
  it would let the table drift from the declared shape.
- A contract checks **shape, not content**. Use data tests for content such
  as values, ranges and uniqueness of real data.

**Contracts vs tests**

| | Contract | Data test |
|---|---|---|
| Runs | **Before** the build | **After** the build |
| Checks | Schema (names, types) + DDL constraints | Data values |
| On failure | The model isn't built; bad data never lands | Data is already in the table; the test reports it |
| Use for | Public/stable interfaces | Data quality |

**Exam traps**

- Official sample question 1: you can avoid re-testing a large incremental
  model for nulls after every run by **(a) a `where` config on the test** to
  limit it to recent data, **or (b) a contract with a `not_null` constraint**,
  so the warehouse rejects nulls on insert.
- A contract **doesn't** check uniqueness on Snowflake or BigQuery. Pair it
  with a `unique` test.
- Removing or retyping a column, or removing a constraint, on a contracted
  model is a **breaking change**. When dbt compares against prod state
  (`state:modified`), it flags the change and tells you to **create a new
  version** (section 2.2). Adding a column is not breaking.

---

## 2.2 Model Versions

*Agenda Book: Session 7.2*

Versions let you ship a **breaking change** to a model without breaking its
consumers on the day you merge. The old and new shapes live side by side, and
consumers migrate on their own schedule.

```yaml
models:
  - name: dim_customers
    latest_version: 2                # what an unpinned ref() resolves to
    config:
      contract: {enforced: true}
    columns:
      - name: customer_id
        data_type: int
      - name: full_name
        data_type: varchar
      - name: country_code
        data_type: varchar
    versions:
      - v: 2                         # inherits all top-level columns
      - v: 1
        deprecation_date: 2026-12-31
        columns:
          - include: all
            exclude: [full_name]
          - name: first_name
            data_type: varchar
          - name: last_name
            data_type: varchar
```

**Files and relations**

| Version | Default file | Default relation name |
|---|---|---|
| v1 | `dim_customers_v1.sql` | `dim_customers_v1` |
| v2 | `dim_customers_v2.sql` | `dim_customers_v2` |

Override a file with `defined_in: <file>`. Use `alias:` (for example
`alias: dim_customers` on the latest version) so the newest version also
appears under the unversioned name.

**Referencing**

| Call | Resolves to |
|---|---|
| `ref('dim_customers')` | **`latest_version`** (v2 above) |
| `ref('dim_customers', v=1)` | v1, pinned |
| `ref('dim_customers', version=1)` | Same as above |

**Selecting**: `dbt build -s dim_customers` builds **all versions**.
`dim_customers.v1` builds one. `version:latest`, `version:prerelease` and
`version:old` select by version state.

**Deprecation**

- `deprecation_date` marks a version for retirement. dbt **warns** when a
  model `ref`s a version past or near that date. It **does not** drop the
  version automatically; you delete it.
- If `latest_version` is lower than the highest `v`, the higher versions are
  **pre-release**. Unpinned refs don't get them until you move
  `latest_version`.

**Workflow for a breaking change**

1. Add `v: 2` with the new shape, and keep `v: 1`.
2. Leave `latest_version: 1` while consumers test `ref(..., v=2)` (pre-release).
3. Bump `latest_version: 2` and set `deprecation_date` on v1.
4. Tell consumers. The warnings point them at their pinned refs.
5. After the date, delete v1.

**Exam traps**

- Versions are for **breaking changes** to models others depend on, not for
  every edit. Adding a column is non-breaking.
- `ref()` without `v` follows `latest_version`, **not** the highest number.
- Versions are only enforced against breaking changes when the model also has
  a **contract**.

---

## 2.3 Model Access and Groups

*Agenda Book: Session 7.3*

```yaml
# models/_groups.yml
groups:
  - name: finance
    owner:
      name: Finance Data Team
      email: finance-data@company.com

# models/finance/_finance__models.yml
models:
  - name: int_ledger_entries
    config:
      group: finance
      access: private        # only refable from inside the finance group
  - name: fct_revenue
    config:
      group: finance
      access: public         # refable from anywhere, including other projects
```

| Access | Who can `ref` it |
|---|---|
| **`private`** | Only models in the **same group** |
| **`protected`** (the default) | Any model in the **same project** (and installed packages) |
| **`public`** | Any model in any project, including **cross-project refs** (dbt Mesh) |

- A **group** is a named set of models with **one owner**. Every model belongs
  to at most one group.
- `private` **requires** the model to be in a group.
- Referencing a private model from outside its group fails **at parse time**:
  `Node model.x attempted to reference node model.y, which is not allowed
  because the referenced node is private to the 'finance' group.`
- You can set access at folder level: `+access: private` together with
  `+group: finance` in `dbt_project.yml`.
- `restrict-access: true` on a package controls whether its `protected`
  models can be `ref`'d by the root project (1.7+ behaviour).

**dbt Mesh**: `ref('finance_project', 'fct_revenue')`. This needs the
upstream project listed under `projects:` in **`dependencies.yml`**, and the
model must be **`public`**. Cross-project refs are a dbt Cloud (platform)
feature.

**Exam traps**

- The default access is **protected**, not public and not private.
- Access controls who can `ref` a model. It does **not** grant warehouse
  permissions; that is `grants`.
- `private` without a `group` is a configuration error.

---

## 2.4 Behaviour Change Flags (2026 guide addition)

*Agenda Book: Session 6.6*

When dbt changes a default in a way that could break existing projects, it
ships the new behaviour behind a **flag** in `dbt_project.yml`. The flag is
off at first. Later the default flips to on, and eventually the flag is
removed.

```yaml
# dbt_project.yml
flags:
  require_explicit_package_overrides_for_builtin_materializations: true
  source_freshness_run_project_hooks: true
  restrict_direct_pg_catalog_access: true
```

- The flags are set under **`flags:`** in `dbt_project.yml`. This replaced
  `config:` in `profiles.yml` for project behaviour (1.8+).
- You get **deprecation warnings** while you are on the old behaviour.
- `--warn-error-options '{"error": ["Deprecations"]}'` turns them into
  errors in CI.

**Exam traps**

- Flags let you **opt in early** or **opt out temporarily**. They are not
  feature toggles for your own models.

---

## Chapter 2 Drill

**Q2.1 (Multiple choice).** A contracted model's SQL returns an extra column
`_loaded_at` that isn't in the YAML. What happens on `dbt run`?

A. The column is dropped silently
B. The build fails before the table is replaced
C. The build succeeds with a warning
D. The table is built, then a test fails

**Q2.2 (Multiple select, choose two).** Which are required for contract enforcement?

A. `data_type` for every column
B. At least one constraint per column
C. `contract: {enforced: true}` in config
D. The model is materialized as `table`

**Q2.3 (Fill in the blank).** To pin a reference to version 1 of `dim_customers`: `{{ ref('dim_customers', ____) }}`.

**Q2.4 (DOMC).** `latest_version: 2` is set and versions 1, 2 and 3 exist. Does
an unpinned `ref('dim_customers')` resolve to version 3? Yes or No?

**Q2.5 (Multiple choice).** What is the default access level of a model?

A. public
B. protected
C. private
D. None; access must be set

**Q2.6 (Multiple choice).** `int_ledger` is `access: private` in group
`finance`. `fct_marketing_spend` (group `marketing`) `ref`s it. When does
this fail?

A. At warehouse execution
B. When `dbt test` runs
C. At parse/compile time
D. It doesn't fail; access is advisory

**Q2.7 (Multiple choice).** On Snowflake, a contracted model declares a
`primary_key` constraint on `order_id`. A duplicate `order_id` is inserted.
What happens?

A. Snowflake rejects the insert
B. dbt rejects the build
C. The row is inserted; Snowflake doesn't enforce primary keys
D. dbt deletes the duplicate

**Q2.8 (Build list).** Put the steps of a safe breaking change in order:
(a) set `deprecation_date` on v1; (b) add v2 with the new shape;
(c) delete v1; (d) bump `latest_version` to 2; (e) consumers test against `v=2`.

### Answers

| Q | Answer | Why |
|---|---|---|
| 2.1 | **B** | The pre-flight check needs an exact column match. Extra columns fail it |
| 2.2 | **A, C** | Constraints are optional. Views and incremental models support contracts too |
| 2.3 | **`v=1`** (or `version=1`) | |
| 2.4 | **No** | Unpinned refs follow `latest_version`. v3 is pre-release |
| 2.5 | **B** | `protected` lets any model in the same project ref it |
| 2.6 | **C** | Access is checked when dbt builds the graph |
| 2.7 | **C** | Snowflake only enforces `not_null`. Add a `unique` test |
| 2.8 | **b, e, d, a, c** | Ship, test, promote, deprecate, remove |

---
# Chapter 3 — Debugging Data Modeling Errors

*Exam Topic 3. Expect hotspot questions here: an error message, a YAML
file or some compiled SQL, and you click the line at fault.*

**Exam objectives**

- Understanding logged error messages
- Troubleshooting using compiled code
- Troubleshooting `.yml` compilation errors
- Distinguishing between a pure SQL and a dbt issue that presents itself as a SQL issue
- Developing and implementing a fix and testing it prior to merging

---

## 3.1 Reading Logged Error Messages

*Agenda Book: Session 11.4*

Every dbt error belongs to a **class**, and the class tells you which stage
failed:

| Stage | Error class | Typical cause | Where to look |
|---|---|---|---|
| Install/connect | `Runtime Error ... Could not find profile` / `Database Error ... connection` | `profiles.yml`, credentials, network | `dbt debug` |
| Parse | **`Parsing Error`** | Bad YAML: indentation, a missing `-`, a wrong key, a duplicate name | The `.yml` file named in the message |
| Compile | **`Compilation Error`** | Jinja: unknown macro, `ref` to a missing node, unclosed `{% %}`, a cycle | The model + `target/compiled/` |
| Execute | **`Database Error`** | The warehouse rejected the SQL: syntax, missing object, permissions, types | `target/run/` SQL, warehouse query history |
| Test | `Failure in test ...` / `Warning in test ...` | Data didn't meet the assertion | Test compiled SQL, `store_failures` |
| Contract | `Contract Error` | Columns/types don't match the YAML | Model SQL vs YAML |

**Where the logs live**

- **`logs/dbt.log`**: the full debug log of every run, including every SQL
  statement sent to the warehouse.
- **`target/run_results.json`**: the status, timing and message of every node.
- **Console**: a summary. Add `--debug` (or `--log-level debug`) for detail.

```
Database Error in model fct_orders (models/marts/fct_orders.sql)
  001003 (42000): SQL compilation error:
  syntax error line 14 at position 4 unexpected 'from'.
  compiled code at target/run/jaffle_shop/models/marts/fct_orders.sql
```

How to read it: the **class** (Database Error) says the warehouse rejected
the SQL. The **node and path** say which model. The **warehouse message**
gives the line number, and that line number refers to the **compiled** file,
not your source file. The last line gives the **compiled path**.

**Exam traps**

- A `Compilation Error` means **no SQL reached the warehouse**. Fixing
  warehouse permissions won't help.
- Line numbers in a Database Error refer to the **compiled** SQL. Jinja
  expansion shifts them away from your source.
- `Found a cycle: model.a --> model.b --> model.a` is a compile-time DAG
  error.

---

## 3.2 Troubleshooting with Compiled Code

*Agenda Book: Sessions 5.1, 11.4*

| Folder | Contains |
|---|---|
| `target/compiled/<project>/models/...sql` | The `select` statement after Jinja rendering, which is what you'd paste into a SQL editor |
| `target/run/<project>/models/...sql` | The **full DDL/DML** dbt actually ran (`create table as ...`, `merge into ...`) |

**Workflow**

1. `dbt compile -s my_model` (or open the "Compiled code" tab in the IDE).
2. Open `target/compiled/.../my_model.sql`.
3. Check every `ref`/`source` became the expected `db.schema.table`, every
   loop produced valid SQL (look for trailing commas), and every `if` took
   the branch you expected.
4. Paste it into the warehouse and run it. If it fails there, the problem is
   SQL. If it runs there but fails in dbt, look at `target/run/` (the
   wrapping DDL, the materialization).

**Typical issues in compiled code**

| You see | Cause |
|---|---|
| `amount_credit_card, amount_coupon, from` | A Jinja loop with no `loop.last` guard, leaving a trailing comma |
| `from dbt_alice.stg_orders` when prod was expected | Wrong `--target`, or no `--defer` |
| `where updated_at > (select max(...) from ...)` on the first run | Incremental logic outside the `is_incremental()` guard |
| `None` or an empty string in SQL | `var()` or `env_var()` not set, or a macro returned nothing |
| A query result is `None` at parse time | `run_query` without `{% if execute %}` |

---

## 3.3 Troubleshooting YAML Compilation Errors

*Agenda Book: Session 11.4*

YAML errors are **parse errors**: dbt stops before compiling anything.
These are the faults the exam's hotspots like to hide:

```yaml
version: 2

models:
  - name: dim_customers
    description: One row per customer
    columns:
      - name: customer_id
        data_tests:
          - unique
          - not_null
      - name: status
        data_tests:
          - accepted_values:
              values: ['active', 'churned']     # values: is nested under the test name
```

| Fault | Example | Symptom |
|---|---|---|
| Wrong indentation | `columns:` at the same level as `- name:` | `Parsing Error ... mapping values are not allowed` or properties silently ignored |
| Missing list dash | `models:` followed by `name: x` | `... is not of type 'array'` |
| Tab characters | | YAML scanner error |
| Wrong key name | `test:` instead of `tests:`/`data_tests:`; `column:` | `Additional properties are not allowed` |
| Test args at the wrong level | `values:` beside `accepted_values` instead of under it | Test gets no arguments: `missing 1 required argument` |
| Duplicate model entry | `dim_customers` described in two `.yml` files | `Compilation Error ... dbt found two schema.yml entries for the same resource` |
| Name mismatch | YAML `name: dim_customer` but the file is `dim_customers.sql` | Warning: patch for a model that doesn't exist; docs and tests missing |
| Unquoted special values | `values: [yes, no]` | YAML reads them as booleans `true`/`false` |
| Jinja in YAML unquoted | `description: {{ doc('x') }}` | Must be quoted: `"{{ doc('x') }}"` |

**Exam traps**

- `tests:` was renamed **`data_tests:`** in 1.8. Both still parse. For a
  1.7-based exam, `tests:` is what you will see.
- A model can be described in **only one** properties file.
- YAML is **case- and whitespace-sensitive**. Two-space indentation is the
  convention.

---

## 3.4 Pure SQL Issue or dbt Issue?

*Agenda Book: Session 11.4*

The question to ask is: **does the compiled SQL run on its own in the
warehouse?**

```
             error in dbt
                  │
     does the compiled SQL run in the warehouse?
           ┌──────┴──────┐
          no             yes
           │              │
     SQL issue        dbt issue
     (logic, syntax,  (materialization, config, target,
      types, perms)    ref resolution, Jinja, hooks, contract)
```

| Looks like a SQL error, but it's dbt | Real cause |
|---|---|
| `Object 'DBT_ALICE.STG_ORDERS' does not exist` | The upstream model was never built in this target. Run `+model`, use `--defer`, or check `ref` spelling |
| `Object does not exist` on a source | Wrong `database`/`schema`/`identifier` in the source YAML |
| Syntax error near `,` | Rendered Jinja loop (trailing comma) |
| Insufficient privileges on `create schema` | A custom schema (`+schema`) the role can't create |
| Column mismatch on insert in an incremental model | `on_schema_change: ignore` with a new column, or the table needs `--full-refresh` |
| Duplicate rows after `merge` | `unique_key` isn't actually unique in the source batch |

| A real SQL issue | Example |
|---|---|
| Logic | A wrong join condition fans out rows |
| Types | Comparing `varchar` to `date` |
| Grain | `group by` missing a non-aggregated column |
| Division by zero, null handling | |

---

## 3.5 Fix and Test Before Merging

*Agenda Book: Sessions 9.7, 9.10*

1. **Reproduce** in your dev target: `dbt build -s my_model`.
2. **Isolate**: compile, run the compiled SQL by hand, narrow it down.
3. **Fix** on a **feature branch**.
4. **Add a test** that would have caught it: a generic test, a singular
   test or a unit test (1.8+).
5. **Build the change and its downstream**: `dbt build -s my_model+`, or in
   CI `dbt build -s state:modified+ --defer --state prod/`.
6. **Open a PR**. CI runs the same build in a temporary schema, a reviewer
   approves, then you merge.

**Exam traps**

- "Test it prior to merging" means a **CI job on the PR** (Slim CI). It does
  not mean "run in prod and watch".
- Run the fix with **`+`** downstream, because a fix can break consumers.
- `dbt build` is better than `run` then `test`, because of the skip-on-failure
  behaviour.

---

## Chapter 3 Drill

**Q3.1 (Multiple choice).** `Compilation Error in model fct_orders: 'cents_to_dolars' is undefined`. What is the cause?

A. The warehouse lacks a function
B. A misspelt or missing macro
C. A wrong data type
D. A broken profile

**Q3.2 (Multiple choice).** Which file shows the exact `create table as` statement dbt sent to the warehouse?

A. `target/compiled/.../fct_orders.sql`
B. `target/run/.../fct_orders.sql`
C. `target/manifest.json`
D. `models/marts/fct_orders.sql`

**Q3.3 (Hotspot).** Which line breaks this YAML?

```yaml
1  models:
2    - name: stg_orders
3      columns:
4        - name: status
5          tests:
6            - accepted_values:
7            values: ['placed', 'shipped']
```

**Q3.4 (DOMC).** A model fails with `Object 'DBT_ALICE.STG_PAYMENTS' does not exist`. Is the fix to grant the dbt role select on `DBT_ALICE.STG_PAYMENTS`? Yes or No?

**Q3.5 (Multiple choice).** The compiled SQL from `target/compiled` runs fine in the warehouse console, but `dbt run` fails. Where should you look next?

A. The model's Jinja
B. The materialization and DDL in `target/run`, hooks and configs
C. The source YAML
D. `packages.yml`

**Q3.6 (Multiple select, choose two).** Which are **parse-time** failures?

A. `Additional properties are not allowed ('tset' was unexpected)`
B. `syntax error line 3 at position 7`
C. A model described in two `.yml` files
D. `Insufficient privileges to operate on schema`

**Q3.7 (Build list).** Order the steps: (a) open a PR; (b) add a test that
captures the bug; (c) reproduce with `dbt build -s model`; (d) CI runs
`state:modified+`; (e) fix on a feature branch.

**Q3.8 (Multiple choice).** `values: [yes, no]` in an `accepted_values` test fails against string data `'yes'`/`'no'`. Why?

A. `accepted_values` doesn't take lists
B. YAML reads unquoted `yes`/`no` as booleans
C. The test needs `quote: false`
D. The column must be a boolean

### Answers

| Q | Answer | Why |
|---|---|---|
| 3.1 | **B** | Compilation errors are Jinja. An undefined name means the macro doesn't exist (a typo, or `dbt deps` not run) |
| 3.2 | **B** | `compiled` has the bare select. `run` has the full DDL |
| 3.3 | **Line 7** | `values:` must be indented under `accepted_values:` |
| 3.4 | **No** | The dev upstream was never built. Build `+model` or defer to prod |
| 3.5 | **B** | The SQL is fine, so the problem is how dbt wraps or executes it |
| 3.6 | **A, C** | B and D come back from the warehouse at execution |
| 3.7 | **c, e, b, a, d** | |
| 3.8 | **B** | Quote them: `['yes', 'no']` |

---
# Chapter 4 — Managing Data Pipelines

*Exam Topic 4. This chapter is about what happens after development: failure
points, cloning and integrations.*

**Exam objectives**

- Troubleshooting and managing failure points in the DAG
- Using dbt clone
- Troubleshooting errors from integrated tools

---

## 4.1 Failure Points in the DAG

*Agenda Book: Sessions 9.3, 4.3, 11.4*

**Node statuses** (in `run_results.json` and the console):

| Status | Meaning |
|---|---|
| `success` | Model built |
| `error` | Model failed, **or** a test errored at runtime (bad SQL) |
| `fail` | A test ran and found rows that break the assertion (severity `error`) |
| `warn` | A test found failing rows, but the severity is `warn` (or below the `error_if` threshold) |
| `skipped` | Not run, because an **upstream node failed** (in `build`) or `--fail-fast` stopped the run |
| `pass` | A test found 0 failing rows |

**How failures spread**

- In `dbt run`, a failed model **skips every downstream model**. Independent
  branches keep running.
- In `dbt build`, a **failed test** on model A also **skips** A's
  downstream nodes. That is the main reason to use `build`.
- A test with **`severity: warn`** does **not** skip anything.
- `--fail-fast` (`-x`) stops the whole run at the first failure.

**Managing failure points**

| Tool | Use |
|---|---|
| `severity: warn` / `error_if` / `warn_if` | Choose which tests block the pipeline |
| `dbt retry` | Resume from the failure without re-running successes (Chapter 8) |
| `--select result:error+ --state target/` | Rebuild failures and their downstream |
| `store_failures: true` | Keep failing rows in a table for diagnosis |
| Source freshness **before** the build | Fail fast if upstream data is late |
| `--exclude` / `--select` for a known-bad branch | Ship the healthy part of the DAG |
| Hooks (`on-run-end`) | Alerting, audit logging |

**Exam traps**

- **`fail` and `error` are different.** `fail` means the test ran and found
  bad data. `error` means something broke (bad SQL, a missing relation).
- Skipped nodes are **not** failures. After the fix they need to run, and
  `dbt retry` re-runs them.
- In `build`, tests on a model run **right after** that model, before its
  children.

---

## 4.2 `dbt clone`

*Agenda Book: Session 9.5*

`dbt clone` creates **copies of nodes from a state manifest** (usually prod)
in your **target** schema.

```bash
# clone prod objects for every node into my target schema
dbt clone --state prod-artifacts/

# just what CI needs: incremental models that changed
dbt clone --select state:modified+,config.materialized:incremental --state prod-artifacts/
```

| Platform | `clone` creates |
|---|---|
| Snowflake, Databricks, BigQuery | **Zero-copy clone**: metadata only, no data copied |
| Others (Postgres, Redshift) | A **view** pointing at the prod relation (`select * from prod.x`) |

- It **skips** objects that already exist in the target unless you pass
  `--full-refresh`.
- It needs **`--state`** (a `manifest.json` from the environment to copy from).

**`clone` vs `defer`**

| | `--defer` | `dbt clone` |
|---|---|---|
| Creates objects in your schema | No | Yes |
| Visible to BI tools and SQL clients | No | Yes |
| Incremental models in CI | Built from scratch (full refresh) | Build **incrementally on top of the clone**, as prod does |
| Typical use | Everyday development | CI for incremental models, blue/green deploys, a dev sandbox for BI testing |

**Exam traps**

- The textbook clone question: "CI must test an **incremental** model's merge
  logic, not a full rebuild". Clone the prod table first, then build the
  modified model incrementally.
- Clone **doesn't copy data** on zero-copy platforms. It is cheap and fast.
- Clone works on models, seeds and snapshots. It doesn't run your SQL.

---

## 4.3 Errors from Integrated Tools

*Agenda Book: Sessions 9.10, 10.2, 11.4*

dbt sits between a **warehouse**, a **git provider**, an **orchestrator** and
**BI tools**. The exam asks you to work out which one broke.

| Symptom | Integrated tool | Fix |
|---|---|---|
| `Database Error ... authentication failed` / `could not connect` | Warehouse credentials, expired key, network policy | `dbt debug`, then rotate the credential in the profile or environment |
| `Insufficient privileges` | The warehouse role | Grant the dbt role the needed rights (create schema, usage on the source) |
| Job can't clone the repo / `Permission denied (publickey)` | Git provider | Deploy key, OAuth, repo permissions |
| PR has no CI run | Git integration / webhook | Check the CI job trigger and repo connection |
| Orchestrator (Airflow) task fails, dbt log is clean | The orchestrator | Exit code, environment, `dbt deps` not run in the container |
| Dashboard broke after a deploy | BI tool consuming a model | A renamed or removed column. Prevent it with contracts + versions + **exposures** |
| `Package not found` in prod but fine locally | The environment | `dbt deps` missing from the job steps |
| Source freshness errors | Upstream EL tool (Fivetran, Airbyte) | Sync paused or failing. dbt is the messenger here |

**dbt exit codes** (what orchestrators see):

| Code | Meaning |
|---|---|
| `0` | Success (warnings included) |
| `1` | A handled error: a model or test failed |
| `2` | An unhandled error: a bad CLI argument, a crash |

**Exam traps**

- Source freshness failing is usually an **EL/loader** problem, not a dbt
  model problem.
- A job that works in the IDE but fails in a deploy job usually has an
  **environment** difference: target, credentials, the `dbt deps` step, or
  env vars.

---

## Chapter 4 Drill

**Q4.1 (Multiple choice).** In `dbt build`, a `unique` test on `stg_orders`
fails with severity `error`. What happens to `fct_orders` (downstream)?

A. It builds normally
B. It builds, then its tests are skipped
C. It is skipped
D. The whole run aborts immediately

**Q4.2 (Matching).** Match each status to its meaning.

| Status | | Meaning |
|---|---|---|
| 1. `fail` | | W. Not run because of an upstream failure |
| 2. `error` | | X. A test found violating rows |
| 3. `skipped` | | Y. Something broke during execution |
| 4. `warn` | | Z. Violating rows, but non-blocking |

**Q4.3 (Multiple choice).** On Postgres, what does `dbt clone` create?

A. A zero-copy clone
B. A full physical copy
C. A view pointing at the source relation
D. Nothing; clone isn't supported

**Q4.4 (DOMC).** Does `dbt clone` overwrite objects that already exist in the target schema by default? Yes or No?

**Q4.5 (Multiple choice).** The Airflow task running `dbt build` exits with code 1. What does this mean?

A. dbt crashed on bad arguments
B. A model or test failed
C. Everything succeeded with warnings
D. The connection failed before parsing

**Q4.6 (Multiple choice).** CI needs to check that an incremental model's
`merge` logic works on the PR. What is the best approach?

A. `dbt build --full-refresh -s state:modified+`
B. `dbt clone` the prod relations, then `dbt build -s state:modified+`
C. Run in prod and roll back
D. Use `--empty`

**Q4.7 (Multiple select, choose two).** Which keep a non-critical test from blocking downstream models in `dbt build`?

A. `severity: warn`
B. `store_failures: true`
C. `error_if: ">100"` when only a few rows fail
D. `limit: 10`

**Q4.8 (Multiple choice).** A deploy job fails with `dbt_utils.generate_surrogate_key is undefined`, but the same code runs in the IDE. What is the most likely fix?

A. Upgrade the warehouse
B. Add `dbt deps` to the job's commands
C. Change the target
D. Reinstall Python

### Answers

| Q | Answer | Why |
|---|---|---|
| 4.1 | **C** | In `build`, a failed test skips downstream nodes |
| 4.2 | **1-X, 2-Y, 3-W, 4-Z** | |
| 4.3 | **C** | Platforms without zero-copy clones get pointer views |
| 4.4 | **No** | It needs `--full-refresh` to replace existing objects |
| 4.5 | **B** | 1 = handled failure; 2 = unhandled error |
| 4.6 | **B** | Clone gives the incremental model a real prior state to merge into |
| 4.7 | **A, C** | `store_failures` and `limit` don't change the status |
| 4.8 | **B** | Packages aren't installed in the job's environment |

---
# Chapter 5 — Implementing dbt Tests

*Exam Topic 5. This chapter carries a lot of syntax: test configs and custom
generic tests are frequent hotspot and fill-in-the-blank items.*

**Exam objectives**

- Using generic, singular, custom, and custom generic tests on a wide variety of models and sources
- Testing assumptions for dbt models and sources
- Implementing various testing steps in the workflow

---

## 5.1 The Test Types

*Agenda Book: Sessions 4.1, 4.2*

**A dbt data test is a `select` that returns failing rows. Zero rows means
it passes.**

| Type | Where it lives | Reusable | Example |
|---|---|---|---|
| **Generic (built-in)** | YAML under a column/model | Yes | `unique`, `not_null`, `accepted_values`, `relationships` |
| **Generic (package)** | YAML, from a package | Yes | `dbt_utils.expression_is_true`, `dbt_utils.unique_combination_of_columns` |
| **Custom generic** | `tests/generic/*.sql` or `macros/` as `{% test %}` | Yes | `is_positive`, `valid_email` |
| **Singular** | `tests/*.sql`: one query | No (one-off) | `assert_total_payment_matches_orders.sql` |
| **Unit test** (1.8+) | YAML `unit_tests:` | n/a | Mock inputs, check the logic's output |

### Built-in generic tests

```yaml
models:
  - name: fct_orders
    columns:
      - name: order_id
        data_tests:
          - unique
          - not_null
      - name: status
        data_tests:
          - accepted_values:
              values: ['placed', 'shipped', 'completed', 'returned']
      - name: customer_id
        data_tests:
          - relationships:
              to: ref('dim_customers')
              field: customer_id
```

| Test | Fails on |
|---|---|
| `unique` | Any value that appears more than once |
| `not_null` | Any null |
| `accepted_values` | Any value not in the list (nulls are **not** flagged) |
| `relationships` | Any child value with no matching parent (referential integrity) |

### Singular tests

```sql
-- tests/assert_no_negative_payments.sql
select order_id, sum(amount) as total
from {{ ref('fct_payments') }}
group by 1
having total < 0
```

The file sits in `tests/`. It is any select that returns the "bad" rows. Its
`ref`s create DAG edges.

### Custom generic tests

```sql
-- tests/generic/is_positive.sql
{% test is_positive(model, column_name) %}
select *
from {{ model }}
where {{ column_name }} <= 0
{% endtest %}
```

```yaml
      - name: amount
        data_tests:
          - is_positive
```

- It is defined with **`{% test name(model, column_name, ...) %}`** and
  closed with `{% endtest %}`.
- `model` and `column_name` are **injected automatically** from where the
  test is attached. Extra arguments come from YAML:

```sql
{% test greater_than(model, column_name, value) %}
select * from {{ model }} where {{ column_name }} <= {{ value }}
{% endtest %}
```
```yaml
          - greater_than:
              value: 0
```

- A model-level generic test (not on a column) takes only `model`.
- You can override a built-in by defining a test with the same name, such as
  `{% test unique(model, column_name) %}`.

### Unit tests (1.8+)

```yaml
unit_tests:
  - name: test_order_status_mapping
    model: fct_orders
    given:
      - input: ref('stg_orders')
        rows:
          - {order_id: 1, status_code: 'P'}
          - {order_id: 2, status_code: 'S'}
    expect:
      rows:
        - {order_id: 1, status: 'placed'}
        - {order_id: 2, status: 'shipped'}
```

Unit tests check **logic** against fixed inputs before the model is built.
Data tests check **real data** after it is built. Run unit tests in
development and CI. Production doesn't need them, because the logic hasn't
changed.

**Exam traps**

- A test **passes when it returns zero rows**. A singular test must select
  the *bad* rows.
- `accepted_values` ignores nulls. Pair it with `not_null`.
- `relationships` is defined on the **child** column and points at the
  parent with `to:` and `field:`.
- Generic tests go in `tests/generic/` (or `macros/`). Singular tests go in
  `tests/`.

---

## 5.2 Test Configurations

*Agenda Book: Sessions 4.1, 4.3*

```yaml
      - name: order_id
        data_tests:
          - unique:
              config:
                severity: error        # error (default) | warn
                error_if: ">100"       # threshold on the number of failing rows
                warn_if: ">10"
                where: "order_date >= current_date - 3"   # limit the rows tested
                limit: 1000            # cap the failing rows returned
                store_failures: true   # keep failing rows in a table
                tags: ['critical']
                enabled: true
```

| Config | Effect |
|---|---|
| `severity` | `error` makes the test fail; `warn` only warns |
| `error_if` / `warn_if` | Thresholds on the failure count (defaults: `!=0`) |
| **`where`** | Filters the **model** before testing. This is how you test only recent data on huge tables |
| `limit` | Caps the failing rows returned |
| **`store_failures`** | Writes failing rows to `<target_schema>_dbt_test__audit.<test_name>` |
| `store_failures_as` (1.7+) | `table`, `view` or `ephemeral` |
| `fail_calc` | How failures are counted (default `count(*)`) |

Set them project-wide too:

```yaml
# dbt_project.yml
data_tests:              # `tests:` before 1.8
  +store_failures: true
  +severity: warn
```

**How severity and thresholds combine**: dbt checks `error_if` first. If the
failure count matches it **and** the severity is `error`, the status is
`fail`. Otherwise, if `warn_if` matches, the status is `warn`. Otherwise
`pass`.

**Exam traps**

- `where` reduces the cost of tests on big incremental models (official
  sample question 1).
- `severity: warn` never blocks `build`.
- `store_failures` changes **nothing** about pass or fail. It only keeps the
  evidence.

---

## 5.3 Testing Assumptions on Models and Sources

*Agenda Book: Sessions 2.1, 4.1*

**Test the source to protect everything downstream.** Assumptions about raw
data (keys are unique, statuses are from a known list) belong on the source.
If they break, you learn about it before the models do.

```yaml
sources:
  - name: shop
    tables:
      - name: orders
        columns:
          - name: id
            data_tests: [unique, not_null]
```

```bash
dbt test --select source:shop          # every test on the shop source
dbt test --select source:shop.orders   # one table
```

**What to test where**

| Layer | Test |
|---|---|
| Sources | Primary key `unique` + `not_null`, freshness, `accepted_values` on enums |
| Staging | Primary key (after renaming), types |
| Intermediate | Grain after joins (fan-out): `unique` on the expected key |
| Marts | Primary key, `relationships` to dimensions, business rules (singular / `expression_is_true`), row-count expectations |

**The minimum standard**: every model has a primary key with **`unique` +
`not_null`**.

| Assumption | Test |
|---|---|
| "One row per order" | `unique` + `not_null` on `order_id` |
| "One row per order per day" | `dbt_utils.unique_combination_of_columns` |
| "Every order has a customer" | `relationships` |
| "Amount is never negative" | Custom generic `is_positive` / `dbt_utils.accepted_range` |
| "Revenue equals payments total" | Singular test |
| "Data arrives daily" | Source freshness |

---

## 5.4 Testing Steps in the Workflow

*Agenda Book: Sessions 9.3, 9.7, 9.10*

| Stage | What runs | Command |
|---|---|---|
| Development | Unit tests + data tests on what you touched | `dbt build -s my_model+` |
| CI (pull request) | Changed models and their downstream, against a PR schema | `dbt build -s state:modified+ --defer --state prod/` |
| Production | Freshness, then build with tests | `dbt source freshness` then `dbt build` |
| Post-run | Alerts on `warn`/`fail`; inspect `store_failures` tables | |

**Selecting tests**

| Command | Runs |
|---|---|
| `dbt test -s my_model` | Tests **on** `my_model` |
| `dbt test -s test_type:generic` / `test_type:singular` / `test_type:unit` | By type |
| `dbt test -s tag:critical` | Tagged tests |
| `dbt test -s source:*` | All source tests |
| `dbt build -s my_model --exclude-resource-type unit_test` | Build without unit tests (1.8+) |

**Indirect selection.** A test that `ref`s two models (`relationships`) runs
when **either** parent is selected (the default `eager` mode). Use
`--indirect-selection cautious` to run it only when **all** its parents are
selected. `buildable` and `empty` are the other modes.

**Exam traps**

- `dbt test -s my_model` also runs tests on other models that **reference**
  `my_model` through `relationships` (eager mode).
- `dbt run` never runs tests.

---

## Chapter 5 Drill

**Q5.1 (Fill in the blank).** A custom generic test is defined with `{% ____ is_positive(model, column_name) %}`.

**Q5.2 (Multiple choice).** A singular test file returns 3 rows. What is the result?

A. Pass, since rows were returned
B. Fail (or warn per severity); 3 failing records
C. Error
D. Skipped

**Q5.3 (Multiple choice).** Which config lets a `not_null` test check only the last 3 days of a 2-billion-row incremental table?

A. `limit`
B. `where`
C. `store_failures`
D. `fail_calc`

**Q5.4 (DOMC).** Does `accepted_values` fail when the column contains nulls? Yes or No?

**Q5.5 (Multiple select, choose two).** Where can a custom generic test be defined?

A. `tests/generic/`
B. `macros/`
C. `models/`
D. `seeds/`

**Q5.6 (Hotspot).** Which line is wrong?

```yaml
1      - name: customer_id
2        data_tests:
3          - relationships:
4              to: dim_customers
5              field: customer_id
```

**Q5.7 (Multiple choice).** A test has `severity: error`, `error_if: ">50"`, `warn_if: ">0"`. It finds 12 failing rows. What is the status?

A. pass
B. warn
C. fail
D. error

**Q5.8 (Multiple choice).** What does `store_failures: true` change?

A. Failures become warnings
B. Failing rows are saved to an audit table; the status is unchanged
C. The test runs before the model
D. Failing rows are deleted from the model

### Answers

| Q | Answer | Why |
|---|---|---|
| 5.1 | **`test`** | Closed with `{% endtest %}` |
| 5.2 | **B** | Any returned row is a failure |
| 5.3 | **B** | `where` filters the model before testing |
| 5.4 | **No** | Nulls aren't checked; add `not_null` |
| 5.5 | **A, B** | Both are scanned for `{% test %}` blocks |
| 5.6 | **Line 4** | Must be `to: ref('dim_customers')` |
| 5.7 | **B** | 12 doesn't meet `>50`, but it does meet `>0` |
| 5.8 | **B** | |

---
# Chapter 6 — Creating and Maintaining Documentation

*Exam Topic 6.*

**Exam objectives**

- Updating dbt docs
- Implementing source, table, and column descriptions in `.yml` files
- Using macros to show model and data lineage on the DAG

---

## 6.1 Generating and Updating Docs

*Agenda Book: Session 8.1*

```bash
dbt docs generate     # builds target/index.html, manifest.json, catalog.json
dbt docs serve        # local web server, default port 8080
```

| Artefact | Contains | Comes from |
|---|---|---|
| `manifest.json` | Every node, its config, descriptions, `depends_on` (lineage) | The project files (parse) |
| `catalog.json` | Column names, **data types**, row counts, table sizes | **The warehouse** (information schema) |
| `index.html` | The single-page docs app | dbt |

- Docs are **static**. Update them by **re-running `dbt docs generate`**
  after changes, usually as a step in the production job.
- dbt Cloud hosts docs from the job with "Generate docs on run" switched on.
  Catalog (formerly Explorer) is the newer UI.
- `--no-compile` (1.7+) skips compiling. `--empty-catalog` skips querying
  the warehouse.
- `persist_docs` writes descriptions **into the warehouse** as table and
  column comments:

```yaml
models:
  jaffle_shop:
    +persist_docs:
      relation: true
      columns: true
```

**Exam traps**

- Descriptions come from the manifest; **column types come from the
  catalog**. If the model was never built, the catalog has no types for it.
- `dbt docs generate` needs a warehouse connection. `docs serve` doesn't
  build anything.

---

## 6.2 Descriptions in YAML

*Agenda Book: Session 8.1*

```yaml
version: 2

sources:
  - name: shop
    description: Raw Shopify data loaded by Fivetran.
    tables:
      - name: orders
        description: One row per order placed in the store.
        columns:
          - name: id
            description: Primary key.

models:
  - name: fct_orders
    description: '{{ doc("fct_orders") }}'
    columns:
      - name: status
        description: '{{ doc("order_status") }}'
```

### Doc blocks

```markdown
<!-- models/docs.md -->
{% docs order_status %}
| status    | meaning                       |
|-----------|-------------------------------|
| placed    | Order placed, not yet shipped |
| shipped   | Left the warehouse            |
| returned  | Customer returned the item    |
{% enddocs %}
```

- They sit in any **`.md` file** in a resource path, defined with
  `{% docs name %}` … `{% enddocs %}`.
- They are referenced with **`{{ doc('name') }}`**, quoted in YAML.
- Use them for long or reused descriptions (one definition for many columns).
- **`__overview__`** is a special doc block name that replaces the docs
  site's home page.

**What can be described**: models, sources, source tables, columns, seeds,
snapshots, tests, macros (in YAML `macros:`), exposures, analyses.

**Exam traps**

- `{{ doc() }}` goes in the **YAML**. `{% docs %}` goes in the **`.md`**.
  Don't swap them.
- Descriptions support Markdown.
- `meta:` holds arbitrary key-value metadata (owner, PII flag) and shows in
  the docs. It is a dictionary, not a description.

---

## 6.3 Lineage on the DAG

*Agenda Book: Sessions 7.5, 8.1*

The lineage graph in the docs site comes **entirely from `ref()` and
`source()`** (the same `depends_on` in `manifest.json`). The guide's phrase
"using macros to show lineage" means exactly this: **the `ref` and `source`
macros** are what draw the edges.

| Lineage element | Created by |
|---|---|
| Green source nodes | `source()` and source YAML |
| Model nodes | `ref()` |
| Orange exposure nodes at the end | `exposures:` YAML with `depends_on` |
| Seeds, snapshots | `ref()` |
| Missing edge | Hard-coded table name |

**The lineage panel** in the docs site:

- Click the icon at the bottom right of a model page to open the DAG.
- The `--select` box accepts the **same selector syntax** as the CLI
  (`+fct_orders+`, `tag:finance`).
- Right-click a node to focus on it or hide its parents or children.

**Exam traps**

- Lineage edges in docs = `ref`/`source`. Nothing else draws them.
- `-- depends_on: {{ ref('x') }}` in a SQL comment forces an edge when a ref
  sits inside conditional Jinja that the parser can't see.

---

## Chapter 6 Drill

**Q6.1 (Multiple choice).** Where does `dbt docs` get column **data types** from?

A. `manifest.json`
B. `catalog.json`, read from the warehouse
C. The YAML `data_type`
D. `run_results.json`

**Q6.2 (Fill in the blank).** A column description reuses a doc block: `description: '{{ ____("order_status") }}'`.

**Q6.3 (Multiple choice).** What is the purpose of the special doc block `__overview__`?

A. Documents every model
B. Replaces the docs site home page
C. Lists sources
D. Documents macros

**Q6.4 (DOMC).** Does `persist_docs` write model descriptions to the warehouse as comments? Yes or No?

**Q6.5 (Multiple choice).** A model shows no upstream edges in lineage, but it reads three tables. Why?

A. Docs weren't served
B. It uses hard-coded table names
C. It's ephemeral
D. It has no description

**Q6.6 (Build list).** Order the steps to publish updated docs: (a) `dbt docs serve`; (b) edit YAML descriptions; (c) `dbt docs generate`; (d) build the models.

**Q6.7 (Multiple select, choose two).** Which files does `dbt docs generate` produce?

A. `catalog.json`
B. `index.html`
C. `sources.json`
D. `profiles.yml`

**Q6.8 (Multiple choice).** Where must a `{% docs %}` block live?

A. Any `.md` file in the project's resource paths
B. Only `README.md`
C. `dbt_project.yml`
D. A `.sql` file

### Answers

| Q | Answer | Why |
|---|---|---|
| 6.1 | **B** | The catalog queries the information schema |
| 6.2 | **`doc`** | |
| 6.3 | **B** | |
| 6.4 | **Yes** | With `relation: true` / `columns: true` |
| 6.5 | **B** | Only `ref`/`source` create edges |
| 6.6 | **b, d, c, a** | Build so the catalog has the objects, then generate, then serve |
| 6.7 | **A, B** | `sources.json` comes from `source freshness` |
| 6.8 | **A** | |

---
# Chapter 7 — External Dependencies

*Exam Topic 7. External dependencies are the edges of your DAG: what feeds
it (sources, with freshness) and what consumes it (exposures).*

**Exam objectives**

- Implementing dbt exposures
- Implementing source freshness

---

## 7.1 Exposures

*Agenda Book: Session 7.5*

An exposure declares a **downstream consumer** outside dbt, such as a
dashboard, an ML pipeline or an app, and the models it depends on.

```yaml
# models/marts/_exposures.yml
exposures:
  - name: weekly_revenue_dashboard
    label: Weekly Revenue           # display name (1.3+)
    type: dashboard                 # dashboard | notebook | analysis | ml | application
    maturity: high                  # high | medium | low
    url: https://bi.company.com/dashboards/42
    description: Exec revenue review, every Monday.
    depends_on:
      - ref('fct_orders')
      - ref('dim_customers')
      - source('stripe', 'payments')
    owner:                          # required
      name: Finance Analytics
      email: finance-analytics@company.com
```

| Field | Required |
|---|---|
| `name` | Yes (snake_case, no spaces) |
| `type` | **Yes**: `dashboard`, `notebook`, `analysis`, `ml`, `application` |
| `owner` | **Yes**: `name` and/or `email` |
| `depends_on` | Strongly recommended: `ref()`, `source()`, `metric()` |
| `url`, `maturity`, `description`, `label`, `tags`, `meta` | Optional |

**What exposures do**

- They appear as **nodes in the lineage graph** and in the docs, so you can
  see the impact of a change.
- They are **selectable**: `dbt build -s +exposure:weekly_revenue_dashboard`
  builds and tests everything that feeds the dashboard.
- They **are not run**. `dbt run` doesn't execute an exposure, and an
  exposure has no SQL.

**Exam traps**

- `exposure:name` on its own selects nothing buildable. Use
  **`+exposure:name`** to get its upstream.
- `type` and `owner` are **required**. A missing `owner` is a parse error.
- Exposures live in properties `.yml` files in model paths. They are
  **not** defined in `dbt_project.yml`.

---

## 7.2 Source Freshness

*Agenda Book: Session 2.1*

```yaml
sources:
  - name: shop
    loaded_at_field: _etl_loaded_at
    freshness:
      warn_after: {count: 6, period: hour}
      error_after: {count: 24, period: hour}
    tables:
      - name: orders                     # inherits the source-level freshness
      - name: refunds
        freshness:
          error_after: {count: 3, period: day}   # table-level override
      - name: country_codes
        freshness: null                  # disables freshness for this table
      - name: events
        loaded_at_field: "convert_timezone('UTC', event_ts)"   # an expression works
```

```bash
dbt source freshness                      # all sources
dbt source freshness --select source:shop # one source
```

**How it works**: dbt runs `select max(<loaded_at_field>) from <table>`,
compares the result with the current time, and returns `pass`, `warn` or
`error`. Results go to **`target/sources.json`**.

| Element | Rule |
|---|---|
| `loaded_at_field` | A timestamp column (or SQL expression) that says when the row **arrived** |
| `period` | `minute`, `hour`, `day` |
| Without `loaded_at_field` | Freshness is skipped (some adapters can use warehouse metadata instead, 1.7+) |
| `filter` | Adds a `where` to the max query, to limit the scan on big tables |
| Inheritance | Table-level settings override source-level settings |

**Workflow**

- Run `dbt source freshness` as the **first step** of a production job. If
  data is stale, stop before building on it.
- **`source_status:fresher`** selects models whose sources got new data since
  the last state. It needs `sources.json` in `--state` (Chapter 8).

**Exam traps**

- Freshness is **not** a test. `dbt test` and `dbt build` don't run it.
  Run `dbt source freshness` yourself.
- A freshness error is an **upstream loader** problem. dbt only reports it.
- `warn_after` and `error_after` take `{count, period}`. Both are optional;
  you need at least one.

---

## Chapter 7 Drill

**Q7.1 (Multiple select, choose two).** Which exposure properties are required?

A. `type`
B. `owner`
C. `url`
D. `maturity`

**Q7.2 (Fill in the blank).** Build everything feeding the dashboard exposure `exec_kpis`: `dbt build -s ________`.

**Q7.3 (DOMC).** Does `dbt run` execute exposures? Yes or No?

**Q7.4 (Multiple choice).** Where are source freshness results written?

A. `run_results.json`
B. `sources.json`
C. `catalog.json`
D. `freshness.json`

**Q7.5 (Multiple choice).** A source sets `error_after: 24 hours`. One table sets `freshness: null`. What happens to that table?

A. It inherits 24 hours
B. Freshness isn't checked for it
C. It errors immediately
D. It warns

**Q7.6 (Multiple choice).** Which command runs freshness checks?

A. `dbt test --freshness`
B. `dbt build`
C. `dbt source freshness`
D. `dbt run-operation freshness`

**Q7.7 (Matching).** Match each exposure type to its use.

| Type | | Use |
|---|---|---|
| 1. `dashboard` | | W. Jupyter/Hex exploration |
| 2. `ml` | | X. Looker/Tableau report |
| 3. `notebook` | | Y. Training pipeline |
| 4. `application` | | Z. Product feature reading from the warehouse |

**Q7.8 (Multiple choice).** What should `loaded_at_field` point to?

A. The business event timestamp only
B. When the row landed in the warehouse (or an expression for it)
C. The primary key
D. The dbt run timestamp

### Answers

| Q | Answer | Why |
|---|---|---|
| 7.1 | **A, B** | |
| 7.2 | **`+exposure:exec_kpis`** | The leading `+` selects its upstream |
| 7.3 | **No** | Exposures are metadata, with no SQL |
| 7.4 | **B** | |
| 7.5 | **B** | `null` opts the table out |
| 7.6 | **C** | |
| 7.7 | **1-X, 2-Y, 3-W, 4-Z** | |
| 7.8 | **B** | Freshness is about loading lag |

---
# Chapter 8 — Leveraging dbt State

*Exam Topic 8. This chapter is about selector syntax and artifacts. Learn
the exact names of every selector method.*

**Exam objectives**

- Understanding state
- Using dbt retry
- Combining state and result selectors

---

## 8.1 Understanding State

*Agenda Book: Sessions 9.4, 9.7, 9.11*

**State is a set of artifacts from a previous run.** dbt compares your
current project against them.

| Artifact | Written by | Used for |
|---|---|---|
| **`manifest.json`** | Every command that parses | `state:` selectors, `--defer`, `dbt clone` |
| **`run_results.json`** | `run`, `test`, `build`, `seed`, `snapshot`, `compile`… | `result:` selectors, `dbt retry` |
| **`sources.json`** | `dbt source freshness` | `source_status:` selectors |
| `catalog.json` | `dbt docs generate` | Docs only |

```bash
dbt build --select state:modified+ --state path/to/prod-artifacts
```

### `state:` selector methods

| Selector | Selects |
|---|---|
| **`state:new`** | Nodes that don't exist in the comparison manifest |
| **`state:modified`** | New nodes **plus** changed ones |
| `state:modified.body` | Changed SQL/Python |
| `state:modified.configs` | Changed configs |
| `state:modified.relation` | Changed database/schema/alias |
| `state:modified.persisted_descriptions` | Changed descriptions (with `persist_docs`) |
| `state:modified.macros` | Upstream macros changed |
| `state:modified.contract` | Contract changed |
| `state:unmodified` / `state:old` | The reverse sets (newer versions) |

**Slim CI** = `state:modified+` + `--defer` + `--state`:

```bash
dbt build --select state:modified+ --defer --state prod-artifacts/
```

- **`state:modified+`**: build what changed **and everything downstream**.
- **`--defer`**: resolve `ref`s to **unbuilt, unmodified** upstream models
  to their **production** relations instead of the CI schema.
- `--favor-state`: defer even when the node exists in the current target.

### `--defer`

- Needs **`--state`** with a `manifest.json` from the environment to defer to.
- Affects **only upstream refs that weren't selected**. Selected nodes still
  build in your target.
- If the upstream **exists in your target**, dbt uses yours, unless you pass
  `--favor-state`.

**Exam traps**

- `state:modified` without `+` skips downstream models that could break.
- `state:modified` **includes new** nodes.
- A changed **var or env var** that alters compiled SQL can show up as
  modified. Changes to `profiles.yml` don't.
- `--state` points at a **directory**, not a file.

---

## 8.2 `dbt retry`

*Agenda Book: Session 9.3, Appendix A*

```bash
dbt build             # 200 nodes: 3 error, 12 skipped, 185 success
# fix the cause…
dbt retry             # re-runs only the 3 errors + 12 skipped
```

- `dbt retry` reads **`target/run_results.json`** from the **last run** and
  re-executes **from the point of failure**: errored nodes and the nodes
  skipped because of them.
- It reuses the **same command and flags** as the previous run (same
  `--select`, `--target` and so on).
- If the last run fully succeeded, `retry` does nothing.
- It works with `build`, `run`, `test`, `seed`, `snapshot`, `compile`,
  `docs generate`, `source freshness`, `clone` and `run-operation`.

**Exam traps**

- `dbt retry` doesn't re-run successful nodes. That is why it is cheaper than
  re-running the whole command.
- You can't add new selectors to `retry`. It replays the previous
  invocation's scope.
- Another dbt command run in between overwrites `run_results.json`, and
  retry then replays *that* command.

---

## 8.3 Combining State and Result Selectors

*Agenda Book: Sessions 9.1, 9.7*

### `result:` selectors (need `run_results.json` in `--state`)

| Selector | Selects |
|---|---|
| `result:error` | Nodes that errored last time |
| `result:fail` | Tests that failed |
| `result:warn` | Tests that warned |
| `result:success` / `result:pass` | Successful models / passing tests |
| `result:skipped` | Skipped nodes |

### `source_status:` (needs `sources.json` from two freshness runs)

| Selector | Selects |
|---|---|
| `source_status:fresher` | Sources with newer data than the state's run |
| `source_status:fresher+` | Those sources **and everything downstream** |

### Combinations the exam likes

```bash
# re-run models that errored, plus their children
dbt build --select result:error+ --state target/

# re-run the models whose tests failed (+ downstream)
dbt build --select 1+result:fail+ --state target/

# only models that are BOTH modified AND previously errored (intersection)
dbt build --select state:modified,result:error+ --state target/

# modified models OR previously failed ones (union)
dbt build --select state:modified+ result:error+ --state target/

# build only what new source data affects
dbt source freshness            # writes target/sources.json
dbt build --select source_status:fresher+ --state prod-artifacts/
```

| Goal | Selector |
|---|---|
| Rebuild what failed last time | `result:error+` (or just `dbt retry`) |
| CI on changed code | `state:modified+` |
| Changed **and** failing | `state:modified,result:error` (comma = AND) |
| Changed **or** failing | `state:modified result:error` (space = OR) |
| Only new data | `source_status:fresher+` |

**Exam traps**

- `result:fail` matches **tests**. To rebuild the model *under* a failed
  test, add `1+` (one parent up): `1+result:fail`.
- `result:` and `state:` both need `--state`. `result:` reads
  `run_results.json` from that path, so pointing at `target/` reuses the last
  local run. Copy it elsewhere first, because the next run overwrites `target/`.
- `dbt retry` vs `result:error+`: both resume after a failure, but `retry`
  needs no `--state` and replays the exact previous command.

---

## Chapter 8 Drill

**Q8.1 (Multiple choice).** Which artifact does `dbt retry` read?

A. `manifest.json`
B. `run_results.json`
C. `sources.json`
D. `catalog.json`

**Q8.2 (Fill in the blank).** Slim CI: `dbt build --select ________ --defer --state prod/` (changed models and everything downstream).

**Q8.3 (DOMC).** Does `state:modified` include brand-new models? Yes or No?

**Q8.4 (Multiple choice).** Select only nodes that are both modified and errored last run:

A. `state:modified result:error`
B. `state:modified,result:error`
C. `state:modified+result:error`
D. `state:modified&result:error`

**Q8.5 (Multiple choice).** What does `--defer` do for an unselected upstream model that isn't built in the CI schema?

A. Builds it
B. Fails the run
C. Resolves the `ref` to the relation in the state manifest (prod)
D. Skips the downstream model

**Q8.6 (Multiple choice).** After `dbt build` with 2 errors and 10 skipped nodes, you fix the bug and run `dbt retry`. What runs?

A. Everything
B. The 2 errored nodes only
C. The 2 errored nodes and 10 skipped nodes
D. Nothing; retry needs `--state`

**Q8.7 (Multiple choice).** Which selector requires `sources.json`?

A. `state:modified`
B. `result:error`
C. `source_status:fresher`
D. `source:shop`

**Q8.8 (Multiple choice).** A test on `fct_orders` failed. Which selector rebuilds `fct_orders` and reruns its tests?

A. `result:fail`
B. `1+result:fail`
C. `result:fail+`
D. `state:modified`

### Answers

| Q | Answer | Why |
|---|---|---|
| 8.1 | **B** | |
| 8.2 | **`state:modified+`** | |
| 8.3 | **Yes** | modified = new + changed |
| 8.4 | **B** | A comma is an intersection |
| 8.5 | **C** | |
| 8.6 | **C** | Retry resumes from the point of failure |
| 8.7 | **C** | `source:shop` is a plain graph selector |
| 8.8 | **B** | `1+` adds the failed test's parent model |

---
# Mock Exam — 65 Questions

*Set a timer for **2 hours**. Don't look anything up. The pass mark is
**43/65** (65%); aim for **52** (80%) before you book the real exam. The
answer key and explanations follow the questions.*

*The mix of topics mirrors the outline: Topic 1 has 22 questions, Topic 2 has
7, Topic 3 has 8, Topic 4 has 6, Topic 5 has 9, Topic 6 has 5, Topic 7 has 4
and Topic 8 has 4.*

---

### Part A — Developing dbt Models

**1.** Which materialization creates no object in the warehouse?
A. view  B. table  C. ephemeral  D. incremental

**2.** A model has no `materialized` config anywhere. What does dbt build?
A. table  B. view  C. ephemeral  D. Nothing; it errors

**3.** Which two conditions make `is_incremental()` return **false**? (Choose two.)
A. The target table doesn't exist yet
B. `unique_key` is not set
C. `--full-refresh` is passed
D. `on_schema_change` is `fail`

**4.** What does `{{ this }}` refer to inside an incremental model?
A. The upstream model
B. The model's existing relation in the warehouse
C. The source table
D. The compiled SQL file

**5.** An incremental model gets a new column. You want it added to the table
automatically without a full refresh. Which setting do you use?
A. `on_schema_change: ignore`
B. `on_schema_change: append_new_columns`
C. `on_schema_change: fail`
D. `full_refresh: false`

**6.** Which snapshot strategy should you use when the source has **no reliable
updated-at column**?
A. timestamp  B. check  C. merge  D. append

**7.** In a snapshot table, how is the **current** version of a record identified by default?
A. `dbt_valid_from` is null
B. `dbt_valid_to` is null
C. `dbt_scd_id` is null
D. `is_current = true`

**8.** Which statement about staging models is a dbt best practice?
A. They join several sources together
B. They map one-to-one to a source table and do light renaming and casting
C. They are materialized as tables with aggregations
D. They are referenced only by exposures

**9.** Fill in the blank: run `my_model` and **all of its ancestors**: `dbt run -s ____my_model`.

**10.** What does `dbt run -s tag:daily,path:models/marts` select?
A. Models tagged daily or in marts
B. Models tagged daily **and** in marts
C. Only models in marts
D. A syntax error

**11.** Which command loads CSV files into the warehouse?
A. `dbt load`  B. `dbt seed`  C. `dbt run`  D. `dbt snapshot`

**12.** Which command runs models, tests, seeds and snapshots in DAG order?
A. `dbt run`  B. `dbt build`  C. `dbt compile`  D. `dbt test`

**13.** Queries reference `raw.stripe.payments`, `raw.stripe.customers` and
`raw.hubspot.contacts`. What is the minimum number of sources you need?
A. 1  B. 2  C. 3  D. 4

**14.** A raw table is named `ORDERS_V2_FINAL`, but you want to call it `orders`
in `source()`. Which property maps it?
A. `alias`  B. `identifier`  C. `schema`  D. `name`

**15.** After adding `dbt_utils` to `packages.yml`, which command must you run before using it?
A. `dbt compile`  B. `dbt deps`  C. `dbt install`  D. `dbt clean`

**16.** In `dbt_project.yml`, which level of `models:` must match the `name:` of the project?
A. The first key under `models:`
B. Any folder key
C. A key under `vars:`
D. None; it's free-form

**17.** A model sets `{{ config(materialized='table') }}`. Its folder in
`dbt_project.yml` sets `+materialized: view`. What is built?
A. view  B. table  C. error  D. ephemeral

**18.** Which statement about Python models is **true**?
A. They can be materialized as views
B. They define `def model(dbt, session)` and return a DataFrame
C. They support Jinja
D. They run on every adapter

**19.** You want BI users in role `reporter` to be able to query all mart models.
What is the best approach?
A. A `post-hook` with `grant select`
B. `+grants: {select: ['reporter']}` on the marts folder
C. A `run-operation` after every run
D. `persist_docs`

**20.** A teammate merged into `main`. You are on `feature/x` and want their
changes. Starting from your branch, which command fetches and merges the
remote `main`?
A. `git push origin main`
B. `git pull origin main`
C. `git fetch` only
D. `git checkout main`

**21.** Which practice keeps developers from overwriting each other's tables?
A. A shared `analytics` schema
B. A separate dev target schema per developer
C. Running only in prod
D. Ephemeral models

**22.** Joining `orders` (one row per order) to `payments` (many per order) and
then summing `orders.shipping_cost` overstates shipping. What is the best fix?
A. `select distinct`
B. Aggregate payments to order grain in a CTE before the join
C. Use a `full outer join`
D. Materialize as a table

### Part B — Model Governance

**23.** When does an enforced contract check column names and types?
A. After the build, as a test
B. Before the build (pre-flight)
C. Only in CI
D. Only on `dbt docs generate`

**24.** Which materialization **cannot** have an enforced contract?
A. table  B. incremental  C. ephemeral  D. view

**25.** `latest_version: 1` is set, with versions 1 and 2 defined. What is version 2?
A. Deprecated  B. Pre-release  C. Invalid  D. Latest

**26.** What happens when a model `ref`s a version past its `deprecation_date`?
A. dbt drops the version
B. dbt warns
C. The build fails
D. Nothing

**27.** Which access level lets models in **other projects** `ref` this model?
A. private  B. protected  C. public  D. shared

**28.** `access: private` requires which additional config?
A. `contract`  B. `group`  C. `version`  D. `owner` on the model

**29.** Which is a **breaking** change for a contracted public model?
A. Adding a new column
B. Removing a column
C. Updating the description
D. Adding a test

### Part C — Debugging

**30.** `Parsing Error: ... mapping values are not allowed here` points at
`schema.yml` line 12. What is the most likely cause?
A. Bad SQL
B. Indentation
C. A missing package
D. Wrong credentials

**31.** Where would you check whether a Jinja `for` loop rendered a trailing comma?
A. `logs/dbt.log` only
B. `target/compiled/`
C. `manifest.json`
D. `profiles.yml`

**32.** `Database Error: relation "dbt_bob.stg_customers" does not exist` while
building `dim_customers` in dev. What is the most likely fix?
A. `dbt build -s +dim_customers` (or defer to prod)
B. Grant permissions on prod
C. Edit `profiles.yml`
D. Change `stg_customers` to ephemeral

**33.** Which error class means the SQL **never reached** the warehouse?
A. Database Error  B. Compilation Error  C. Failure in test  D. Warning

**34.** `Compilation Error: dbt found two schema.yml entries for the same resource named orders`. What is the fix?
A. Rename the SQL file
B. Remove one of the duplicate YAML entries
C. Run `dbt clean`
D. Add a version

**35.** The compiled SQL runs fine in the warehouse console, but the dbt run of
the same incremental model fails on `merge`. Where is the issue most likely?
A. Business logic
B. The incremental config or materialization (for example `unique_key` or a schema change)
C. The YAML description
D. The git branch

**36.** A Database Error reports line 48, but the model file has 30 lines. Why?
A. The warehouse is wrong
B. Line numbers refer to the compiled or run SQL
C. Logs are stale
D. The file wasn't saved

**37.** Before merging a fix to `main`, the recommended verification is:
A. Run it in prod
B. A CI job building `state:modified+` in a temporary schema
C. `dbt compile` only
D. A manual review only

### Part D — Managing Pipelines

**38.** In `dbt run`, model B fails. Models C and D are downstream of B, and E
is independent. What is the result?
A. All four stop
B. C and D are skipped; E runs
C. C, D and E are skipped
D. C and D run on stale data

**39.** What does `--fail-fast` do?
A. Retries failures quickly
B. Stops the run at the first failure
C. Skips tests
D. Sets the threads to 1

**40.** On Snowflake, `dbt clone --state prod/` creates:
A. Views pointing at prod
B. Zero-copy clones
C. Full copies of the data
D. Empty tables

**41.** Which flag makes `dbt clone` replace objects that already exist in the target?
A. `--force`  B. `--full-refresh`  C. `--replace`  D. `--favor-state`

**42.** Freshness checks fail every morning for `source:salesforce`. The dbt models
haven't changed. Where should you investigate first?
A. The dbt model SQL
B. The EL loader syncing Salesforce
C. `packages.yml`
D. The docs site

**43.** Which exit code does dbt return when a model fails during an orchestrated run?
A. 0  B. 1  C. 2  D. 127

### Part E — Tests

**44.** When does a data test pass?
A. It returns at least one row
B. It returns zero rows
C. It returns `true`
D. It doesn't error

**45.** Where do singular tests live?
A. `tests/`  B. `macros/`  C. `models/`  D. `analyses/`

**46.** Fill in the blank: arguments the framework automatically injects into a
column-level custom generic test are `model` and `________`.

**47.** Which built-in test checks that every `orders.customer_id` exists in `customers.customer_id`?
A. unique  B. not_null  C. accepted_values  D. relationships

**48.** You want a test to report problems without stopping downstream models in `dbt build`. Which config?
A. `severity: warn`  B. `store_failures: true`  C. `enabled: false`  D. `limit: 0`

**49.** Where does `store_failures` write failing rows by default?
A. `target/failures/`
B. A schema named `<target_schema>_dbt_test__audit`
C. `logs/`
D. The model's own table

**50.** Which test checks uniqueness across `order_id` + `line_number` together?
A. `unique` on each column
B. `dbt_utils.unique_combination_of_columns`
C. `relationships`
D. `accepted_values`

**51.** `dbt test -s stg_orders` also runs a `relationships` test defined on
`fct_returns.order_id` that points to `stg_orders`. Why?
A. A bug
B. Eager indirect selection: the test has `stg_orders` as a parent
C. Tags
D. `store_failures`

**52.** Which test type checks transformation logic with **mocked inputs** before the model is built? (1.8+)
A. Singular  B. Generic  C. Unit  D. Freshness

### Part F — Documentation

**53.** Which command must you re-run to update the hosted or served docs after editing descriptions?
A. `dbt docs serve`  B. `dbt docs generate`  C. `dbt parse`  D. `dbt run`

**54.** Fill in the blank: a doc block starts with `{% ____ order_status %}`.

**55.** Which config writes YAML descriptions to the warehouse as comments?
A. `persist_docs`  B. `docs: show`  C. `meta`  D. `comment`

**56.** What draws the edges in the docs lineage graph?
A. Folder structure
B. `ref()` and `source()` calls
C. Tags
D. Model names

**57.** You want a model hidden from the docs site. Which config?
A. `docs: {show: false}`  B. `enabled: false`  C. `access: private`  D. `meta: {hidden: true}`

### Part G — External Dependencies

**58.** Which `type` is **not** valid for an exposure?
A. dashboard  B. ml  C. application  D. report

**59.** Where are exposures defined?
A. `dbt_project.yml`
B. A `.yml` properties file under a model path
C. `profiles.yml`
D. `packages.yml`

**60.** `warn_after: {count: 12, period: hour}` and the latest `loaded_at_field`
value is 15 hours old. There is no `error_after`. What is the result?
A. pass  B. warn  C. error  D. skipped

**61.** Which column should `loaded_at_field` reference?
A. When the record was loaded into the warehouse
B. The primary key
C. A random sample timestamp
D. `dbt_updated_at`

### Part H — dbt State

**62.** Which selector builds new and changed models plus everything downstream?
A. `state:new`  B. `state:modified`  C. `state:modified+`  D. `+state:modified`

**63.** What does `dbt retry` require?
A. `--state prod/`
B. The previous invocation's `run_results.json` in `target/`
C. `sources.json`
D. A git diff

**64.** `dbt build --select result:error+ --state target/` selects:
A. Only errored nodes
B. Errored nodes and their descendants
C. Only skipped nodes
D. All nodes

**65.** In Slim CI, why add `--defer`?
A. To skip tests
B. To resolve unbuilt, unmodified upstream refs to production relations
C. To deploy to prod
D. To clone tables

---

## Answer Key

| # | Ans | Explanation |
|---|---|---|
| 1 | C | Ephemeral models are inlined as CTEs |
| 2 | B | `view` is the default |
| 3 | A, C | Also false when the relation is a view; `unique_key` is irrelevant |
| 4 | B | |
| 5 | B | `ignore` drops it silently; `fail` stops the run |
| 6 | B | `check` compares column values |
| 7 | B | `dbt_valid_to` is null on the current row |
| 8 | B | |
| 9 | `+` | `+my_model` |
| 10 | B | A comma is an intersection |
| 11 | B | |
| 12 | B | |
| 13 | B | `raw.stripe` and `raw.hubspot`: one source per database + schema |
| 14 | B | `identifier` is the physical name; `name` is the logical one |
| 15 | B | |
| 16 | A | Otherwise the configs never apply |
| 17 | B | In-file `config()` beats `dbt_project.yml` |
| 18 | B | `table`/`incremental` only, no Jinja, limited adapters |
| 19 | B | `grants` is declarative and revokes too |
| 20 | B | `pull` = fetch + merge |
| 21 | B | |
| 22 | B | Fix the grain; `distinct` hides the fan-out |
| 23 | B | |
| 24 | C | Python models aren't supported either |
| 25 | B | Above `latest_version` means pre-release |
| 26 | B | You remove deprecated versions yourself |
| 27 | C | |
| 28 | B | Private means private to a group |
| 29 | B | Removing or retyping columns is breaking; adding is not |
| 30 | B | YAML parse errors are structural |
| 31 | B | |
| 32 | A | The upstream isn't in the dev schema |
| 33 | B | |
| 34 | B | One properties entry per resource |
| 35 | B | The SQL is fine, so suspect the dbt wrapper |
| 36 | B | |
| 37 | B | |
| 38 | B | Independent branches continue |
| 39 | B | |
| 40 | B | |
| 41 | B | |
| 42 | B | Freshness reports loader lag |
| 43 | B | 2 is an unhandled error |
| 44 | B | |
| 45 | A | |
| 46 | `column_name` | |
| 47 | D | |
| 48 | A | |
| 49 | B | |
| 50 | B | |
| 51 | B | Use `--indirect-selection cautious` to change this |
| 52 | C | |
| 53 | B | `serve` only hosts what `generate` built |
| 54 | `docs` | Closed with `{% enddocs %}` |
| 55 | A | |
| 56 | B | |
| 57 | A | `docs: {show: false}` hides the node in the docs |
| 58 | D | Valid types: dashboard, notebook, analysis, ml, application |
| 59 | B | |
| 60 | B | Only `warn_after` is set |
| 61 | A | |
| 62 | C | `state:modified` includes new nodes; `+` adds descendants |
| 63 | B | Retry replays the last invocation from `run_results.json` |
| 64 | B | |
| 65 | B | |

**Scoring by topic.** Mark which part each miss came from. Any part where
you got **less than 70%** right is the chapter to re-read before booking.

| Part | Questions | Chapter |
|---|---|---|
| A | 1 to 22 | 1 |
| B | 23 to 29 | 2 |
| C | 30 to 37 | 3 |
| D | 38 to 43 | 4 |
| E | 44 to 52 | 5 |
| F | 53 to 57 | 6 |
| G | 58 to 61 | 7 |
| H | 62 to 65 | 8 |

---
# Appendices

## Appendix A — Last-Night Cheat Sheet

**Commands**

```
dbt debug | deps | parse | compile | run | test | seed | snapshot | build
dbt docs generate | docs serve | source freshness | run-operation | show | ls
dbt retry | clone --state DIR | clean
```

**Selectors**

```
m+  +m  2+m  m+1  @m          graph operators
a b = OR      a,b = AND        --exclude x
tag:  path:  source:  exposure:  package:  config.materialized:
resource_type:  test_type:generic|singular|unit
state:new  state:modified[.body|.configs|.relation|.macros|.contract]
result:error|fail|warn|success|skipped   source_status:fresher
```

**Materialization defaults**: `view`. `incremental` needs `is_incremental()`
plus `{{ this }}`. `ephemeral` means a CTE and no object. Python models are
`table` or `incremental` only.

**Schema naming**: `<target_schema>_<custom_schema>` unless you override
`generate_schema_name`.

**Config precedence**: `config()` in the file > YAML `config:` > the
`dbt_project.yml` folder > the project > the default.

**Tests**: zero rows = pass. Severity is `error`/`warn`. Configs: `where`,
`limit`, `error_if`, `warn_if`, `store_failures`, `fail_calc`.

**Governance**: contracts are checked pre-flight on names and types, and
constraints depend on the platform. `ref` without `v` follows
`latest_version`. Access: `private` (group), `protected` (project, the
default), `public` (everywhere).

**Artifacts**: `manifest.json` → `state:`/`defer`/`clone`.
`run_results.json` → `result:`/`retry`. `sources.json` → `source_status:`.
`catalog.json` → docs column types.

**Statuses**: `fail` = a test found rows. `error` = something broke.
`skipped` = upstream failed. `warn` = non-blocking.

---

## Appendix B — Commonly Confused Pairs

| A | vs | B | The difference |
|---|---|---|---|
| `ref()` | | `source()` | Models/seeds/snapshots vs raw tables declared in YAML |
| `dbt run` | | `dbt build` | Models only vs everything, with skip-on-test-failure |
| `target/compiled` | | `target/run` | The bare select vs the full DDL |
| Contract | | Data test | Before the build, shape vs after the build, values |
| `fail` | | `error` | Bad data vs broken execution |
| `--defer` | | `dbt clone` | A pointer inside dbt vs real objects in the warehouse |
| `dbt retry` | | `result:error+` | Replays the last command vs a selector you compose (needs `--state`) |
| `state:new` | | `state:modified` | Only new vs new + changed |
| `a,b` | | `a b` | AND vs OR |
| `+m` | | `m+` | Ancestors vs descendants |
| `{% docs %}` | | `{{ doc() }}` | Define (in `.md`) vs reference (in `.yml`) |
| `name` | | `identifier` (sources) | Logical vs physical table name |
| `git fetch` | | `git pull` | Download vs download + merge |
| `grants` | | `access` | Warehouse permissions vs who can `ref` it in dbt |
| `protected` | | `private` | Project-wide vs group-only |
| `timestamp` | | `check` (snapshots) | Compares `updated_at` vs compares column values |
| `persist_docs` | | `docs generate` | Comments in the warehouse vs the docs site |
| Freshness | | Tests | `dbt source freshness` only vs run by `test`/`build` |

---

## Appendix C — Where This Book Maps to the Agenda Book

For deeper reading, here is each section of this book with its source
session in `dbt-agenda-book.md`.

| This book | Agenda Book session(s) |
|---|---|
| 1.1 Dependencies | 1.1, 2.1 |
| 1.2 Materializations | 1.4, 3.1, 3.2, 3.3, 3.4, 3.6 |
| 1.3 Modularity / DRY | 1.3, 5.1, 5.7 |
| 1.4 Performant SQL | 1.3, 11.5 |
| 1.5 Commands | 9.1, 9.3, Appendix A |
| 1.6 DAG flow | 1.3 |
| 1.7 `dbt_project.yml` | 6.2, 6.3, Appendix B |
| 1.8 Sources | 2.1 |
| 1.9 Packages | 5.7 |
| 1.10 Git | 9.10 |
| 1.11 Python models | 11.1 |
| 1.12 Grants | 6.5 |
| 2.1 Contracts | 7.1 |
| 2.2 Versions | 7.2 |
| 2.3 Access, groups | 7.3, 7.4 |
| 2.4 Behaviour flags | 6.6 |
| 3.x Debugging | 11.4, 5.1, 9.7 |
| 4.1 Failure points | 9.3, 4.3 |
| 4.2 `dbt clone` | 9.5 |
| 4.3 Integrated tools | 9.10, 10.2 |
| 5.x Tests | 4.1, 4.2, 4.3 |
| 6.x Docs | 8.1, 7.5 |
| 7.1 Exposures | 7.5 |
| 7.2 Freshness | 2.1 |
| 8.x State, retry | 9.4, 9.7, 9.11 |

**What the Agenda Book covers that this book leaves out** (not on the exam):
the Semantic Layer and MetricFlow (8.2), dbt Mesh internals (7.4),
materialized views in depth (3.5), UDFs and custom materializations (5.5,
5.6), linting (4.4), Advanced CI and state-aware orchestration (9.8, 9.9),
the dbt platform UI (Part X), Iceberg (11.3) and the road to v2 (Part XII).

---

## Appendix D — Exam-Day Checklist

**The day before**

- [ ] Run the Caveon browser check on the machine you'll use
- [ ] Prepare a quiet room, clear desk, photo ID and webcam
- [ ] Re-read Appendices A and B, and nothing else

**During the exam**

- [ ] About 110 seconds per question. Flag anything over 2 minutes and move on (except DOMC, where you can't go back)
- [ ] On **DOMC** items, decide what the right answer must contain before the first option appears
- [ ] On "choose two" items, check that you picked exactly two
- [ ] On hotspots, read **every** line. Look for indentation, missing `ref`, and wrong nesting
- [ ] When an answer depends on the version, assume the guide's supported version (1.7 for V.6.0)

**After the exam**

- [ ] You get your score straight away. A pass is valid for **2 years**
- [ ] A fail: note the weak topics from the score report, re-read those chapters, and retake (a new fee applies)
