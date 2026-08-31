# The dbt Agenda Book

*A structured curriculum assembled from the dbt material in this daily-notes
archive, brought current to August 2026.*

*Second edition — 59 sessions across 12 Parts, 7 appendices.*

---

## About This Book

This book reorganises every dbt-related entry in this repository into a
teaching order, then brings it up to date with what dbt has become by
**August 2026**.

The raw notes are chronological — dbt topics appear scattered across 90 days,
revisited many times in random order. This book restores the dependency order:
each session assumes only what came before it.

**Corpus covered**

| Metric | Value |
|---|---|
| Notes scanned | 91 daily files (`2026-05-30` → `2026-08-27`) |
| dbt-focused sections found | 335 |
| Distinct topics | 40 |
| Date range of dbt material | 2026-05-31 → 2026-08-20 |

The notes are heavily repetitive by design (spaced repetition): Model Contracts
appears 46 times, Snapshots 42, Incremental Models 26, Macros 24. This book
collapses each topic into **one canonical session**, keeping the sharpest
explanation and the union of the gotchas, and records which dates covered it so
you can go back to the primary source.

### The 2026 update

The first edition covered the archive faithfully and listed, in its closing
appendix, everything the archive never mentioned. This edition closes that list
and adds what shipped since.

**New sessions** — 18 of them, marked in the text as not sourced from the
archive: the engine landscape (1.2), microbatch (3.3), materialized views and
dynamic tables (3.5), linting (4.4), UDFs (5.5), custom materializations (5.6),
behaviour change flags (6.6), `dbt clone` (9.5), sample mode (9.6), Advanced CI
(9.8), state-aware orchestration (9.9), the whole of Part X (the dbt platform),
Iceberg and `catalogs.yml` (11.3), and the whole of Part XII (upgrading and the
road to v2).

**Substantially revised** — Snapshots for the 1.9 YAML spec, `hard_deletes` and
`dbt_valid_to_current`; Sources for `loaded_at_query` and the `config:` nesting;
the Semantic Layer for the embedded 1.12 specification; Documentation for
Catalog and Docs v2; Slim CI for the `state:modified` flags; Materializations,
Profiles, Tests, Unit Tests, Artifacts, and Performance Tuning throughout.

**Version anchor.** Written against `dbt-core 1.12.3` (current stable) with
`dbt-core 2.0.0b2` in beta. Everything in Parts I–IX works on dbt Core 1.8+
unless a session says otherwise; version-gated features are flagged inline as
`(1.9+)`, `(1.11+)`, or `(Fusion / v2)`.

**How each session is laid out**

- **Covered on** — the source dates in this archive, and how many notes.
  New sessions say so explicitly.
- **Why it matters** — the problem the feature exists to solve.
- **Mechanics** — the config, the code, the commands.
- **Gotchas** — the failure modes the notes kept flagging.
- **Checklist** — what "you know this" looks like.

---

## Reading Paths

| If you are… | Read |
|---|---|
| New to dbt | 1.1 → 1.2 → the rest of Part I → II → III → IV, then stop and build something |
| Already shipping models, want rigour | Part IV → V → VI |
| Scaling to multiple teams | Part VII → VIII |
| Fixing slow/expensive builds | Part IX → Sessions 11.5, 9.9, 10.1 |
| On call for a dbt pipeline | Sessions 4.1, 9.3, 11.4, 11.6 |
| Running dbt Cloud (now "the dbt platform") | Sessions 1.2 → Part X |
| Stuck on an old version, or eyeing Fusion | Sessions 1.2 → 6.6 → Part XII |
| Catching up after a year away | Sessions 1.2, 3.3, 5.5, 9.9, 12.1 — then Part XII |

**Suggested pace:** one Part per week, building a real project alongside.
Parts I–IV are the load-bearing 80%; Parts V–IX are what separates a working
project from a maintainable one. Part X applies only if you are on the
commercial platform; Part XII applies to everyone eventually.

**Book map**

```
I    Foundations              what dbt is, which dbt, layout, materializations
II   Getting Data In          sources, freshness, seeds
III  Building at Scale        incremental, microbatch, MVs, snapshots
IV   Data Quality             data tests, unit tests, store_failures, linting
V    Programmability          Jinja, macros, UDFs, materializations, packages
VI   Config & Environments    profiles, vars, schemas, hooks, grants, flags
VII  Interfaces & Governance  contracts, versions, access, Mesh, exposures
VIII Documentation & Semantics docs, Catalog, Semantic Layer
IX   Running dbt              selection, build, defer, clone, CI, state
X    The dbt Platform         Studio, Catalog, Insights, jobs, AI
XI   Advanced & Operations    Python, Iceberg, debugging, performance, observability
XII  Upgrading                version strategy, deprecations, the road to v2
```

---

# Part I — Foundations

*The four ideas everything else rests on: what dbt is, which dbt you are running, how a project is laid out, and how a model becomes an object in the warehouse.*

---

## Session 1.1 — What dbt Actually Is

**Covered on:** 2026-06-02, 06-03, 06-06, 06-08, 06-09, 06-16 *(6 notes)*

### Why it matters

Before dbt, analytics logic lived in stored procedures, ad-hoc scripts, and BI
tool "calculated fields" — no version control, no tests, no documentation, and
no clear owner. dbt's contribution is as much cultural as technical: it makes
SQL transformations reviewable, testable, and documented code.

### Mechanics

dbt is the **T** in ELT. It does not move data. Ingestion tools (Fivetran,
Airbyte, custom pipelines) land raw data in the warehouse; dbt defines a DAG of
SQL transformations on top of it.

Every model is one `.sql` file containing one `SELECT`. dbt wraps it in
`CREATE TABLE AS` / `CREATE VIEW AS` and runs it against your warehouse
(Snowflake, BigQuery, Redshift, Databricks, Postgres, DuckDB).

```sql
-- models/marts/finance/fct_orders.sql
with orders as (
    select * from {{ ref('stg_orders') }}
),
customers as (
    select * from {{ ref('stg_customers') }}
)
select
    o.order_id,
    o.ordered_at,
    c.customer_name,
    o.total_amount
from orders o
join customers c on o.customer_id = c.customer_id
```

**`ref()` is the whole trick.** Instead of hardcoding `analytics.staging.stg_orders`,
you write `{{ ref('stg_orders') }}`. From that, dbt:

1. resolves the correct schema-qualified name for the current environment,
2. infers the dependency graph automatically,
3. builds models in topological order.

Your DAG is *declared implicitly by your SQL*, never maintained by hand.

The same idea applies to raw tables via `{{ source('shopify', 'orders') }}` —
see Session 2.1.

### The payoff

When the business redefines "active user" or "recognised revenue", you change
one upstream model and run:

```bash
dbt run --select +downstream_model+
```

The change propagates through the entire dependency chain consistently. That
single property is why dbt won.

None of that changed when the engine was rewritten in Rust in 2026. The graph,
`ref()`, and the compile-and-run model are the stable core; Session 1.2 covers
what did change.

### Checklist

- [ ] I can explain why `ref()` exists rather than hardcoded table names
- [ ] I know dbt does not extract or load — only transform
- [ ] I can name the five materializations without looking (Session 1.4)
- [ ] I know which engine my project runs on (Session 1.2)

---

## Session 1.2 — The 2026 Landscape: Which dbt Are You Running?

**Covered on:** *New in the 2026 update — not in the note archive.*

### Why it matters

Between 2025 and 2026 dbt stopped being one program. There is now a Python
engine and a Rust engine, an open-source distribution and a commercial one, and
a hosted platform that renamed most of its surface area. Almost every "why
doesn't this work for me?" question in 2026 resolves to *which dbt are you
running*. Answer that before reading anything else in this book.

### The two engines

| | **dbt Core v1.x** | **dbt Core v2 / Fusion** |
|---|---|---|
| Language | Python | Rust |
| Latest | `1.12.3` on PyPI | `2.0.0b2` (beta, Aug 2026) |
| Install | `pip install dbt-core dbt-<adapter>` | standalone binary, no venv |
| Parsing | Jinja-first; SQL is an opaque string | Full SQL parse and type-check before execution |
| Speed | Baseline | Order-of-magnitude faster parse on large projects |
| Status | Maintained, backward compatible across all 1.x | Beta, converging on GA |

The Rust engine is the same codebase in both places. That is the key fact of
2026: dbt Labs open-sourced the Fusion runtime as **dbt Core v2 under Apache
2.0**, ending the split where the fast engine was source-available (ELv2) and
the open one was Python-only.

### The two distributions

```
dbt-core   →  Apache 2.0, fully open source, the Rust engine
dbt        →  "Fusion" — the same engine plus proprietary extensions
              (free to use; more capable out of the box)
```

Business logic is portable in both directions. Code contributed to `dbt-core`
flows into Fusion.

### What the engine changes for you

Fusion / v2 unlock capabilities the Python engine structurally cannot offer,
because they all depend on dbt *understanding* your SQL rather than just
templating it:

- **Static analysis** — column-level type and reference errors caught before a
  single query reaches the warehouse.
- **Column-level lineage** — not just model-to-model edges.
- **`dbt lint`** — a built-in SQLFluff-compatible linter, 40×–250× faster
  (Session 4.4).
- **dbt State / state-aware orchestration** — skip rebuilds when neither code
  nor data changed (Session 9.9).
- **A language spec** — YAML keys are validated, so `desciptin:` is an error
  instead of a silently ignored key.

### The platform, renamed

dbt Cloud is now **the dbt platform**. If you are reading documentation or blog
posts written before mid-2025, translate:

| Old name | Current name |
|---|---|
| dbt Cloud | dbt platform |
| Cloud IDE | **Studio IDE** |
| dbt Explorer | **Catalog** |
| — (new) | **Insights** — exploratory analysis + Semantic Layer querying |
| — (new) | **Canvas** — drag-and-drop visual model building |
| dbt Copilot | **dbt Wizard** / agents (Developer, Analyst) |

Part X covers the platform surface in detail.

### Release tracks: you no longer pick a version number

On the platform you pick a *cadence*, not a version. dbt upgrades you.

| Core tracks (platform v1) | Cadence | Fusion tracks (platform v2) | Cadence |
|---|---|---|---|
| `latest` | Continuous | `fusion-nightly` | Daily |
| `compatible` | Monthly, matches OSS releases | `fusion-stable` *(default)* | Weekly |
| `extended` | Monthly, one release behind | `fusion-extended` | Monthly |
| `fallback` | Emergency rollback (Enterprise+) | `fusion-fallback` | Emergency rollback |

New platform projects on Snowflake, BigQuery, Databricks and Redshift default
to **Fusion Stable**.

### The corporate context

Fivetran and dbt Labs completed an all-stock merger on **2026-06-01** — George
Fraser as CEO, Tristan Handy as President, roughly $600M combined ARR. For
practitioners the near-term impact is small: both products continue
independently and dbt Core stayed open source (and got *more* open, via v2).
The medium-term thing to watch is that ingestion and transformation now share a
roadmap and a pricing surface.

### Working out what you're on

```bash
dbt --version              # engine and adapter versions
dbt debug                  # connection, profile, and project sanity check
```

In the platform: **Environment settings → dbt version** shows the release
track. The Fusion status endpoint reports it programmatically:

```
GET /api/ide/v3/{environment_id}/status   →  { "dbt_version": ..., "is_fusion": true }
```

### How this book handles versions

Everything in Parts I–IX works on dbt Core 1.8+ unless a session says
otherwise. Version-gated features are flagged inline — `(1.9+)`, `(1.11+)`,
`(Fusion / v2)`. Part XII covers upgrading and migration.

### Checklist

- [ ] I know whether my project runs the Python or the Rust engine
- [ ] I know my release track, or my pinned `dbt-core` version
- [ ] I can translate the old dbt Cloud names to the current ones
- [ ] I know that `dbt-core` (OSS) and `dbt` (Fusion) share one engine

---

## Session 1.3 — Project Structure: Staging → Intermediate → Marts

**Covered on:** 2026-06-21, 07-06, 07-07, 08-11 *(4 notes)*

### Why it matters

A dbt project without layering degenerates into a tangle where mart models read
raw sources directly, and a single upstream column rename requires edits in
twenty files.

### Mechanics

```
models/
├── staging/          # One-to-one with raw sources
│   ├── stripe/
│   │   ├── _stripe__sources.yml
│   │   ├── stg_stripe__customers.sql
│   │   └── stg_stripe__invoices.sql
│   └── salesforce/
│       ├── _salesforce__sources.yml
│       └── stg_salesforce__accounts.sql
├── intermediate/     # Business logic, joins, aggregations
│   └── int_revenue_by_customer.sql
└── marts/            # Audience-facing, wide, denormalized
    ├── finance/
    │   └── fct_monthly_revenue.sql
    └── core/
        └── dim_customers.sql
```

**Staging** — one model per source table. Rename, cast, light cleaning only.
No joins, no business logic.

```sql
-- models/staging/stripe/stg_stripe__customers.sql
with source as (
    select * from {{ source('stripe', 'customers') }}
),
renamed as (
    select
        id                          as customer_id,
        email                       as email_address,
        created                     as created_at,
        metadata:company_name::text as company_name
    from source
)
select * from renamed
```

Conventions: prefix `stg_`, name as `source__entity`, cast types, snake_case
everything, filter soft-deletes.

**Intermediate** — reusable business logic that several marts share. Keeps
complexity out of the mart layer.

**Marts** — denormalised, organised by business domain (`finance/`,
`marketing/`, `core/`), prefixed `fct_` / `dim_`.

| Layer | Materialization | Reads from | Purpose |
|-------|----------------|---------|---------|
| Staging | `view` / `ephemeral` | `source()` only | Clean & rename raw data |
| Intermediate | `ephemeral` / `view` | `ref()` staging | Reusable logic |
| Marts | `table` / `incremental` | `ref()` only | Business-ready outputs |

### The golden rule

**A model only ever `ref()`s its immediate upstream layer. Marts never read raw
sources.** Change a source column name once, in staging, and every downstream
model inherits the fix.

### Checklist

- [ ] Every `source()` call in my project lives in a `stg_` model
- [ ] Marts are organised by business domain, not by source system
- [ ] I set layer defaults in `dbt_project.yml`, not per-model

---

## Session 1.4 — Materializations

**Covered on:** 2026-07-05 *(1 note; reinforced throughout Part III)*

### Why it matters

Materialization is the highest-leverage single-line decision in a dbt project.
It directly determines build time, query latency, and warehouse spend.

### The five built-in materializations

| Materialization | What dbt creates | Cost to build | Cost to query |
|---|---|---|---|
| `view` | A database view | None | High (re-runs each time) |
| `table` | Full table (DROP + CREATE) | High | Low |
| `incremental` | Table updated partially | Low | Low |
| `ephemeral` | Nothing (inlined as CTE) | None | Medium |
| `materialized_view` | A view the warehouse keeps refreshed | Low | Low |

```sql
{{ config(materialized='table') }}
```

A sixth exists on Snowflake — `dynamic_table` — which fills the same role as
`materialized_view` elsewhere. Session 3.5 covers both. You can also write your
own (Session 5.6), though you rarely should.

### Choosing

```
Is the model a raw source cleanup?          → view
Is it a small reference/lookup table?       → view or table
Is it a large fact table (millions+ rows)?  → incremental
Is it a final mart queried by BI tools?     → table
Is it a tiny reusable sub-query?            → ephemeral
Does it need to be fresher than my schedule? → materialized_view / dynamic_table
```

Set defaults per directory, override per model only when needed:

```yaml
# dbt_project.yml
models:
  my_project:
    staging:
      +materialized: view
    intermediate:
      +materialized: ephemeral
    marts:
      +materialized: table
```

### Gotchas

- A `view` over a large source is cheap to build and expensive forever after.
  If it's queried more than ~10×/day, make it a `table`.
- `ephemeral` SQL is duplicated into *every* dependent model. Ten dependents =
  ten copies of the scan. Do not use it for large intermediate datasets.
- `materialized_view` support varies sharply by platform, and Snowflake uses
  `dynamic_table` instead. It is the one materialization that is not portable.

### Checklist

- [ ] Directory-level defaults are set in `dbt_project.yml`
- [ ] I can justify every model that overrides its layer default

---

# Part II — Getting Data In

*The two edges of the DAG that are not models: declared sources you read from, and seeds you ship in the repo.*

---

## Session 2.1 — Sources and Source Freshness

**Covered on:** 2026-06-20, 06-27, 07-02, 07-21, 07-27, 08-10, 08-19 *(7 notes)*

### Why it matters

A **source** declares a table that lives outside your dbt project. Declaring it
buys you two things: `{{ source() }}` instead of hardcoded strings, and
freshness monitoring — the only built-in way to catch a silently broken
ingestion pipeline before your dashboards go stale.

### Declaring sources

```yaml
# models/staging/_shopify__sources.yml
version: 2

sources:
  - name: shopify
    database: raw
    schema: shopify_raw
    loader: fivetran
    loaded_at_field: _fivetran_synced      # default freshness column

    freshness:
      warn_after:  {count: 12, period: hour}
      error_after: {count: 24, period: hour}

    tables:
      - name: orders
        description: "Raw orders from the Shopify webhook."
        columns:
          - name: id
            description: "Shopify order ID."

      - name: events
        loaded_at_field: event_timestamp   # per-table override
        freshness:
          warn_after:  {count: 1, period: hour}
          error_after: {count: 3, period: hour}

      - name: reference_data
        freshness: null                    # static table — opt out
```

> **1.10+ — `freshness` is moving under `config:`.** The bare property above
> still works and still appears in most documentation, but it now raises a
> deprecation warning and will be invalid in v2. The current form nests it:
>
> ```yaml
> sources:
>   - name: shopify
>     config:
>       freshness:
>         warn_after:  {count: 12, period: hour}
>         error_after: {count: 24, period: hour}
>     loaded_at_field: _fivetran_synced
> ```
>
> The same move applies to `meta`, `tags`, `docs`, `group`, and `access`.
> See Session 6.6.

### `loaded_at_query`: freshness when a column isn't enough

`loaded_at_field` assumes one column answers "when did this last load." For
partial loads, streaming ingestion, or late-arriving data it doesn't. dbt 1.10
added `loaded_at_query`, which lets you write the freshness probe yourself:

```yaml
    tables:
      - name: events
        loaded_at_query: |
          select max(ingested_at)
          from {{ this }}
          where ingested_at >= current_timestamp - interval '3 days'
```

It is mutually exclusive with `loaded_at_field` — set one or the other. The
bounded window matters: an unbounded `max()` over a billion-row table is itself
an expensive query to run every fifteen minutes.

This config does double duty. It is also what state-aware orchestration uses to
decide whether downstream models need rebuilding at all (Session 9.9), which is
why aligning its window with your incremental lookback (Session 3.1) matters
more than it first appears.

Reference it from a staging model:

```sql
select
    id         as order_id,
    email      as customer_email,
    created_at as ordered_at
from {{ source('shopify', 'orders') }}
```

### Running the freshness check

```bash
dbt source freshness
dbt source freshness --select source:shopify.orders
```

dbt runs `SELECT MAX(<loaded_at_field>)` per table, compares against now, and
exits non-zero if anything is in **error** state. Warnings surface but don't
fail.

```
ok    raw.orders    [1h 14m ago  — within warn threshold]
warn  raw.events    [13h 5m ago  — past warn, within error]
error raw.payments  [26h 42m ago — past error threshold]
```

Use it as a **pre-flight gate**:

```bash
dbt source freshness --select source:raw.payments
dbt build --select +fct_payments
```

Results are written to `target/sources.json`, which powers the dbt platform's
freshness views and observability tools.

### Gotchas

- Set `loaded_at_field` once at source level; override only where it differs.
- Use `freshness: null` on static reference tables or you'll get false alerts.
- `SELECT MAX(...)` on a huge unindexed timestamp column costs real money.
  Don't poll aggressively. Prefer metadata-based freshness where the adapter
  supports it — on BigQuery, `bigquery_use_batch_source_freshness: true` (1.11+)
  collapses one query per source into a single batch query, which is a large win
  for projects with hundreds of sources.
- Alert on freshness errors in your **orchestrator**, separately from model
  failures — a stale source is an upstream problem, not a code problem.

### Checklist

- [ ] One source YAML file per upstream system, mirroring team ownership
- [ ] `warn_after` set at ~1.5× expected load frequency
- [ ] Freshness runs as a gate before the build, not after
- [ ] `freshness` nested under `config:` (1.10+), not left as a bare property

---

## Session 2.2 — Seeds

**Covered on:** 2026-06-18, 06-22, 06-29, 07-03, 07-14, 07-17, 07-22, 07-30, 08-05, 08-10, 08-19 *(11 notes)*

### Why it matters

Seeds are CSV files in your repo loaded into the warehouse as tables. They are
the right tool for small, slowly-changing reference data you *maintain* —
country codes, fiscal calendars, cost-centre mappings, status lookups.

### Seeds vs Sources

| Use Seeds | Use Sources |
|---|---|
| Static lookups you maintain | Raw tables loaded by an ETL tool |
| Small CSVs (< a few thousand rows) | Large, frequently updated tables |
| Data that belongs in version control | Data owned by an external system |
| Bootstrapping test data | Production ingestion data |

### Mechanics

```
seeds/
  country_codes.csv
  fiscal_calendar.csv
```

```csv
country_code,country_name,region,is_active
US,United States,North America,true
CA,Canada,North America,true
DE,Germany,Europe,true
```

```bash
dbt seed
dbt seed --select country_codes
dbt seed --full-refresh          # required after a schema change
```

**Always set column types** — without them dbt infers everything as `varchar`
and you cast in every downstream model:

```yaml
# dbt_project.yml
seeds:
  my_project:
    +schema: reference
    +quote_columns: false
    fiscal_calendar:
      +schema: finance
      +column_types:
        fiscal_year: integer
        period_start_date: date
        is_current_period: boolean
```

Seeds are first-class DAG nodes — `ref()` them like models, and test them like
models:

```yaml
seeds:
  - name: country_codes
    description: "ISO 3166-1 alpha-2 codes with region groupings"
    columns:
      - name: country_code
        tests: [unique, not_null]
      - name: region
        tests:
          - accepted_values:
              values: ['North America', 'Europe', 'Asia Pacific']
```

### Gotchas

- **`dbt run` does not run seeds.** Pipeline order is `dbt seed` → `dbt run` →
  `dbt test`, or just use `dbt build` (Session 9.3).
- **No Jinja in CSVs.** Seeds are data, not templates.
- **Adding a column requires `--full-refresh`.** Without it dbt loads rows but
  never alters the table schema.
- Seeds bloat git history with near-binary diffs. Monthly updates are fine;
  weekly means you want a source instead.

### Checklist

- [ ] Every seed has explicit `+column_types`
- [ ] Seeds are tested like models
- [ ] `dbt seed` is in the CI pipeline before `dbt run`

---

# Part III — Building Models at Scale

*What to do when full rebuilds stop being affordable — and how to keep history when the source system will not.*

---

## Session 3.1 — Incremental Models

**Covered on:** 2026-06-04, 06-05, 06-17, 06-22, 06-23, 06-25, 06-29, 07-02, 07-06, 07-07, 07-10, 07-13, 07-14, 07-16, 07-22, 07-28, 08-01, 08-02, 08-03, 08-04, 08-05, 08-06, 08-11, 08-14, 08-17, 08-19 *(26 notes — the second most-revisited topic)*

### Why it matters

Rebuilding a 500M-row fact table on every run is wasteful and often impossible
inside a runtime budget. Incremental models process only new or changed rows.

### Mechanics

On the first run dbt does a full build. On subsequent runs it applies the
`is_incremental()` filter and merges the result in.

```sql
-- models/marts/fct_events.sql
{{ config(
    materialized='incremental',
    unique_key='event_id',
    incremental_strategy='merge'
) }}

select
    event_id,
    user_id,
    event_type,
    occurred_at
from {{ ref('stg_events') }}

{% if is_incremental() %}
  where occurred_at > (select max(occurred_at) from {{ this }})
{% endif %}
```

- `{{ this }}` — the existing target table.
- `is_incremental()` — false on the first run and on `--full-refresh`.
- `unique_key` — the column(s) `merge` upserts on.

### Strategies

| Strategy | How it works | Best for |
|---|---|---|
| `append` | INSERT only, no dedup | Immutable event streams, no late data |
| `merge` | MERGE/UPSERT by `unique_key` | Most cases — handles updates and inserts atomically |
| `delete+insert` | DELETE matching keys, then INSERT | Warehouses without MERGE (Redshift, Spark) |
| `insert_overwrite` | Replaces whole partitions | Partitioned tables (BigQuery, Spark) |
| `microbatch` | Chunks by a time column per batch | Very large tables, backfills, tight SLAs (1.9+) — Session 3.3 |

BigQuery partition-replacement pattern:

```sql
{{ config(
    materialized='incremental',
    incremental_strategy='insert_overwrite',
    partition_by={'field': 'event_date', 'data_type': 'date'},
    cluster_by=['user_id']
) }}

select
  date(occurred_at) as event_date,
  user_id,
  count(*) as event_count
from {{ ref('stg_events') }}
{% if is_incremental() %}
  where date(occurred_at) >= date_sub(current_date(), interval 3 day)
{% endif %}
group by 1, 2
```

`microbatch` is different enough in kind from the other four that it gets its
own session (3.3): you stop writing the `is_incremental()` filter entirely and
declare a time column instead.

### Late-arriving data — the recurring theme

A pure `max()` watermark silently drops rows that land after their event time.
Widen the window:

```sql
{% if is_incremental() %}
  where occurred_at >= dateadd(day, -3, (select max(occurred_at) from {{ this }}))
{% endif %}
```

With `merge` + `unique_key`, late rows upsert instead of duplicating.

### Full refresh

```bash
dbt run --select fct_events --full-refresh
```

Schedule a periodic full refresh (weekly/monthly) for models where upstream
corrections could cause silent divergence.

### Gotchas

- **`merge` without `unique_key` silently degrades to `append`** — duplicates
  accumulate with no error. This is the single most-repeated warning in the notes.
- **Avoid `SELECT *`** — source schema drift breaks the merge step silently.
- **`delete+insert` is not atomic** — there is a window where rows are missing
  and downstream readers can observe it. Prefer `merge`.
- **Validate the partition filter with `dbt compile`** before running
  `insert_overwrite` in production — a wrong filter can overwrite a year of
  partitions.
- **Test `--full-refresh` in CI.** Incremental bugs hide until the next full
  rebuild.
- Periodically compare row counts between the incremental table and a fresh
  full-refresh build to detect drift.

### Checklist

- [ ] Every `merge` model has a `unique_key`
- [ ] Every incremental model has a lookback window, not a bare `max()`
- [ ] The source side is filtered too, not just `{{ this }}` (see Session 11.5)
- [ ] For time-series tables, `microbatch` has been considered (Session 3.3)

---

## Session 3.2 — `on_schema_change`: Column Drift

**Covered on:** 2026-08-16 *(1 note; referenced from many incremental notes)*

### Why it matters

When an incremental model's `SELECT` gains or loses a column, dbt has to decide
what to do with the table that already exists. The default choice **silently
discards data**.

### The four options

```yaml
models:
  - name: fct_events
    config:
      materialized: incremental
      unique_key: event_id
      on_schema_change: append_new_columns
```

| Value | Behavior |
|---|---|
| `ignore` | **Default.** New columns are silently dropped. Safe but lossy. |
| `fail` | Hard error if the column set differs at all. |
| `append_new_columns` | Adds new columns, `NULL` for historical rows. Never removes. |
| `sync_all_columns` | Mirrors SELECT exactly — adds *and drops*. Destructive. |

> **Snowflake, September 2026:** default column sizes increased. `dbt-snowflake`
> below **v1.10.6** is incompatible with that change for incremental models that
> combine string collation with `on_schema_change: sync_all_columns`. If that
> describes your project, the adapter upgrade is not optional (Session 12.1).

### Why `ignore` loses data quietly

```sql
-- before
select event_id, user_id, event_type from raw.events
-- after
select event_id, user_id, event_type, session_id from raw.events
```

`session_id` is in the query result but absent from the physical table. dbt
inserts positionally against the existing columns and the values are discarded
with no warning. You find out when a downstream report queries a column that
was never written.

### The recommendation

```yaml
# dbt_project.yml
models:
  my_project:
    +on_schema_change: append_new_columns
```

Override to `fail` for models feeding ML pipelines or enforced contracts.

**`on_schema_change` cannot backfill.** New columns are `NULL` for historical
rows — if they need real values, you still need `--full-refresh`.

### Checklist

- [ ] Project default is `append_new_columns`, not the implicit `ignore`
- [ ] Contract-enforced models use `fail`

---

## Session 3.3 — The `microbatch` Strategy

**Covered on:** *Mentioned once in the archive, never explained. Written for the 2026 update.*

### Why it matters

Session 3.1's incremental pattern has a structural weakness: the whole
increment is **one query**. If it fails at 90%, you re-run everything. If a
backfill spans two years, you either write a bespoke loop or hold your breath.
And the correctness of the whole thing rests on a hand-written
`is_incremental()` filter that every engineer on the team has to get right.

`microbatch` (dbt 1.9+) replaces that filter with a declared time column and
lets dbt split the work into independent, idempotent, retryable batches.

### Mechanics

```sql
-- models/marts/fct_sessions.sql
{{ config(
    materialized='incremental',
    incremental_strategy='microbatch',
    event_time='session_start',
    batch_size='day',
    lookback=3,
    begin='2024-01-01',
    full_refresh=false
) }}

select
    page_views.id           as session_id,
    page_views.started_at   as session_start,
    customers.customer_tier
from {{ ref('page_views') }} as page_views
left join {{ ref('customers') }} as customers
    on page_views.customer_id = customers.id
```

Note what is *absent*: there is no `{% if is_incremental() %}` block. You write
the query as if it processes exactly one day, and dbt supplies the boundaries.

| Config | Required | Meaning |
|---|---|---|
| `event_time` | ✅ | The column that says *when the row happened* |
| `batch_size` | ✅ | `hour`, `day`, `month`, `year` |
| `begin` | ✅ | Where history starts on a full build |
| `lookback` | | Batches before the bookmark to reprocess (default `1`) |
| `concurrent_batches` | | Force parallel/sequential; auto-detected by default |
| `full_refresh` | | Set `false` so a stray `--full-refresh` can't nuke history |

### The upstream contract

dbt filters upstream `ref()`s automatically — but **only for models that declare
their own `event_time`**:

```yaml
# models/staging/_staging__models.yml
models:
  - name: page_views
    config:
      event_time: started_at     # gets filtered per batch

  - name: customers
    # no event_time — full scan on every batch, by design (it's a dimension)
```

For the 2024-10-01 batch, `{{ ref('page_views') }}` compiles to:

```sql
select * from (
    select * from analytics.stg.page_views
    where started_at >= '2024-10-01 00:00:00'
      and started_at <  '2024-10-02 00:00:00'
)
```

This is the single biggest cost lever in the strategy. A fact table with an
un-annotated upstream fact model will full-scan it once *per batch* — 365 times
on a year-long backfill. Annotate every upstream fact/event model; leave
dimensions alone.

To opt a single ref out: `{{ ref('upstream').render() }}`.

### Per-adapter DML

You do not choose the strategy — dbt picks the right one for the platform:

| Adapter | Underlying DML | Extra requirement |
|---|---|---|
| Snowflake | `delete+insert` | — |
| Redshift | `delete+insert` | — |
| BigQuery | `insert_overwrite` | `partition_by` |
| Spark | `insert_overwrite` | `partition_by` |
| Databricks | `replace_where` | — |
| Postgres | `merge` | `unique_key` |

### Backfills and retries — the payoff

```bash
# normal run: lookback batches + the current one
dbt run --select fct_sessions

# targeted backfill — both bounds required
dbt run --select fct_sessions \
        --event-time-start "2024-09-01" --event-time-end "2024-09-04"

# rebuild a window from scratch
dbt run --select fct_sessions --full-refresh \
        --event-time-start "2024-01-01" --event-time-end "2024-02-01"

# re-run only the batches that failed
dbt retry
```

`dbt retry` is the reason to adopt this. In the classic pattern a failed
incremental run is all-or-nothing; here, batch 340 of 365 failing costs you one
batch.

### Gotchas

- **`--full-refresh` alone does not reset the table.** Without
  `--event-time-start`/`--event-time-end` it will not do what you expect. Set
  `full_refresh=false` on the model and drive rebuilds explicitly.
- **Do not write `is_incremental()` logic in a microbatch model.** It fights
  the batch filter and produces wrong results. Delete it.
- **Everything is UTC.** `event_time`, `begin`, and both CLI bounds. Custom
  timezones are not supported — normalise upstream.
- **Un-annotated upstream models are silently expensive.** Nothing errors; the
  bill just goes up.
- **`lookback` is your late-arriving-data window**, and it plays the same role
  the manual `dateadd(day, -3, max(...))` played in Session 3.1. Same reasoning,
  now a config instead of a comment nobody reads.
- **Custom microbatch macros** need the
  `require_batched_execution_for_custom_microbatch_strategy` behaviour flag
  (Session 6.6).

### When *not* to use it

- No reliable event-time column.
- The increment isn't time-shaped (e.g. "everything with `status = 'pending'`").
- Complex incremental logic that genuinely needs to see the target table.

In those cases stay on `merge` with a hand-written filter.

### Checklist

- [ ] `event_time`, `batch_size`, and `begin` are all set
- [ ] Every upstream *event* model declares its own `event_time`
- [ ] `full_refresh: false` on the model
- [ ] No `is_incremental()` block left in the SQL
- [ ] `lookback` covers the real late-arrival window
- [ ] The team knows `dbt retry` exists

---

## Session 3.4 — Ephemeral Models

**Covered on:** 2026-07-19 *(1 note)*

### Why it matters

Ephemeral models exist only as CTEs injected into their dependents. No table,
no view, no storage, no namespace clutter.

### Mechanics

```sql
-- models/staging/stg_orders_cleaned.sql
{{ config(materialized='ephemeral') }}

select
    order_id,
    customer_id,
    lower(trim(status))      as status,
    cast(created_at as date) as order_date,
    amount / 100.0           as amount_usd
from {{ source('raw', 'orders') }}
where order_id is not null
```

At compile time, any `ref()` to it becomes an inline CTE:

```sql
with orders as (
    {{ ref('stg_orders_cleaned') }}   -- ← full SQL injected here
)
select * from orders
```

### Limitations

| Concern | Detail |
|---|---|
| Not queryable | It doesn't exist in the warehouse — you can't `SELECT` from it |
| Duplicated | 10 dependents = its SQL compiled 10 times; optimizers may not share the scan |
| Testing | Tests must run via parents; they're injected as CTEs too |

### Rule of thumb

Start as a **view** during development so you can debug it, then switch to
**ephemeral** once it's stable and only ever used as a building block.

---

## Session 3.5 — Materialized Views and Dynamic Tables

**Covered on:** *Absent from the archive. Written for the 2026 update.*

### Why it matters

Session 3.1's incremental models put *you* in charge of refresh logic: a
watermark, a lookback, a merge strategy, a schedule. Materialized views hand
that job to the warehouse. You declare the query once; the platform keeps the
result current on its own clock, between dbt runs.

That is a genuinely different operating model, and it is the fifth built-in
materialization — not an exotic add-on.

### Mechanics

```sql
-- models/marts/mv_active_subscriptions.sql
{{ config(
    materialized='materialized_view',
    on_configuration_change='apply'
) }}

select
    subscription_id,
    customer_id,
    plan,
    started_at
from {{ ref('stg_subscriptions') }}
where status = 'active'
```

`dbt run` creates the MV if absent. On later runs it does **not** rebuild the
data — the warehouse is already doing that. What dbt manages is the *object*:

| `on_configuration_change` | Behaviour when the config drifts |
|---|---|
| `apply` | Alter the object in place where the platform allows it |
| `continue` | **Default.** Warn and move on, leaving the object as-is |
| `fail` | Raise an error |

`--full-refresh` always drops and recreates.

### Snowflake: dynamic tables

Snowflake does not use `materialized_view` for this — it uses **dynamic
tables**, which are strictly more capable (joins, aggregates, incremental
refresh):

```sql
{{ config(
    materialized='dynamic_table',
    snowflake_warehouse='TRANSFORM_WH',
    target_lag='30 minutes',
    refresh_mode='INCREMENTAL',
    on_configuration_change='apply',
    cluster_by=['customer_id'],
    immutable_where='created_at < current_date - 30',
    refresh_warehouse='REFRESH_WH',
    copy_grants=true
) }}
```

`target_lag` is the freshness SLA you are buying: Snowflake schedules refreshes
to keep the table within it. `refresh_warehouse` (1.11+) lets refresh compute
bill separately from your dbt build. `immutable_where` (1.11+) tells Snowflake
a partition of the data will never change, so it can skip it.

### The trade

| | Incremental model | Materialized view / dynamic table |
|---|---|---|
| Refresh trigger | Your dbt schedule | The warehouse's clock |
| Freshness between runs | Stale | Current |
| Control over merge logic | Total | None |
| SQL restrictions | None | Significant (varies by platform) |
| Cost visibility | On your dbt job | Background compute, easy to miss |
| Testing | Normal | Tests run against whatever the last refresh produced |

### Gotchas

- **Platform support is uneven.** Postgres, BigQuery, Databricks and Redshift
  have `materialized_view`; Snowflake has `dynamic_table` instead. This is a
  portability cliff — Session 5.4's `adapter.dispatch` will not save you here.
- **SQL restrictions bite.** Many platforms reject window functions, certain
  joins, or non-deterministic functions in an MV. You often find out at run
  time.
- **`on_configuration_change` defaults to `continue`** — a config change you
  made in a PR can quietly not apply in production. Set it to `apply`
  explicitly.
- **Background refresh cost is invisible in `run_results.json`.** It will not
  appear in your dbt timing charts; it appears on the warehouse bill.
- **Downstream models see a moving target.** An MV can refresh mid-build,
  so two models reading it in the same run can disagree.

### Rule of thumb

Reach for a materialized view when the freshness requirement is tighter than
your dbt schedule and the query is simple enough for the platform to accept.
Everything else — anything with real merge semantics, late-arriving data, or
logic you need to reason about — stays an incremental model.

---

## Session 3.6 — Snapshots and SCD Type 2

**Covered on:** 42 notes, 2026-06-16 through 2026-08-18 — *the single most-revisited topic in the archive after Model Contracts.*

### Why it matters

Most source systems store only the *current* state. Update a customer's email
and the old one is gone. Snapshots answer "what did this row look like last
Tuesday?" by writing a new versioned row on every detected change.

### Mechanics

Snapshots live in `snapshots/` and use a `{% snapshot %}` block:

```sql
-- snapshots/snap_orders.sql
{% snapshot snap_orders %}

{{
  config(
    target_schema='snapshots',
    unique_key='order_id',
    strategy='timestamp',
    updated_at='updated_at',
    invalidate_hard_deletes=True
  )
}}

select
    order_id, customer_id, status, total_amount, updated_at
from {{ source('shopify', 'orders') }}

{% endsnapshot %}
```

```bash
dbt snapshot
dbt snapshot --select snap_orders
```

### The 1.9+ configuration (use this one)

dbt 1.9 reworked snapshots substantially, and the old form above is now the
legacy one. Snapshots are configured in **YAML**, `target_schema` is optional,
and three long-standing complaints got fixed:

```yaml
# snapshots/_snapshots.yml
snapshots:
  - name: snap_orders
    relation: source('shopify', 'orders')
    config:
      schema: snapshots            # not target_schema; standard schema/database configs
      unique_key: order_id
      strategy: timestamp
      updated_at: updated_at
      hard_deletes: new_record     # ignore | invalidate | new_record
      dbt_valid_to_current: "'9999-12-31'::date"
      snapshot_meta_column_names:
        dbt_valid_from: valid_from
        dbt_valid_to: valid_to
        dbt_scd_id: version_id
        dbt_updated_at: updated_at_dbt
```

| Config | What it fixes |
|---|---|
| `snapshot_meta_column_names` | Rename dbt's metadata columns to match your warehouse conventions instead of leaking `dbt_` prefixes into the semantic layer |
| `dbt_valid_to_current` | Use a sentinel date instead of `NULL` for the current row — so `where '2026-01-01' between valid_from and valid_to` works without an `or ... is null` |
| `hard_deletes` | Replaces `invalidate_hard_deletes` with three explicit behaviours |

`dbt_valid_to_current` is the one worth adopting immediately. Compare:

```sql
-- with NULL (default)
where dbt_valid_from <= '2026-01-01'
  and (dbt_valid_to > '2026-01-01' or dbt_valid_to is null)

-- with dbt_valid_to_current set
where '2026-01-01' between valid_from and valid_to
```

Every analyst who forgets the `or ... is null` produces a silently incomplete
result. The sentinel removes the failure mode.

### The two strategies

| Strategy | Config | When |
|---|---|---|
| `timestamp` | `updated_at='col'` | Source has a reliable `updated_at` |
| `check` | `check_cols=[...]` or `'all'` | No `updated_at` — dbt hashes columns to detect change |

```sql
{{ config(
    strategy='check',
    check_cols=['email', 'plan', 'status'],
    unique_key='customer_id',
    target_schema='snapshots'
) }}
```

### The four metadata columns dbt adds

| Column | Meaning |
|---|---|
| `dbt_scd_id` | Surrogate key, unique per version row |
| `dbt_updated_at` | When dbt last touched the row |
| `dbt_valid_from` | When this version became active |
| `dbt_valid_to` | When it was superseded (`NULL` = current) |

```sql
-- current state only
select * from {{ ref('snap_orders') }} where dbt_valid_to is null;

-- point-in-time reconstruction
select * from {{ ref('snap_orders') }}
where dbt_valid_from <= '2026-01-01'
  and (dbt_valid_to > '2026-01-01' or dbt_valid_to is null);

-- full history of one record
select order_id, status, dbt_valid_from, dbt_valid_to
from {{ ref('snap_orders') }}
where order_id = 12345
order by dbt_valid_from;
```

### Hard deletes

By default a row that disappears from the source keeps `dbt_valid_to = NULL`
forever — the delete is invisible. The legacy fix was
`invalidate_hard_deletes=True`, which closes the row out at the current snapshot
timestamp. dbt 1.9 replaced it with `hard_deletes`, which has three settings:

| Value | Behaviour |
|---|---|
| `ignore` | **Default.** Deleted rows stay open forever. The delete is invisible. |
| `invalidate` | Closes the row out — equivalent to the old `invalidate_hard_deletes=True` |
| `new_record` | Closes the old row *and* inserts a tombstone row marked deleted |

`new_record` is the one to prefer when deletion is itself meaningful — a
cancelled subscription, a deactivated account. `invalidate` tells you the row
stopped existing; `new_record` tells you *when it was deleted* as a first-class
fact you can join to.

### Gotchas

- **Snapshots only capture state at the moment they run.** A value that appears
  and disappears between two runs is lost forever. Run them as frequently as
  your SLA demands.
- **Run `dbt snapshot` *before* `dbt run`** so models see the freshest history.
- **Snapshot raw sources, not staging models** — capture original values before
  any transformation.
- **Keep snapshot SQL close to `select *`.** No business logic; apply it
  downstream via `ref()`.
- **`check_cols='all'` is expensive and noisy** — technical audit timestamps
  trigger false changes. List only business-meaningful columns.
- **Snapshot tables grow without bound.** Partition on `dbt_valid_from`, cluster
  on `unique_key`.
- **`updated_at` with the wrong data type** now raises a warning (1.9+) instead
  of producing quietly wrong history. Do not silence it — fix the cast.
- **Changing `snapshot_meta_column_names` on an existing snapshot** does not
  rename the existing columns. Decide the naming before the first run, or plan a
  rebuild.
- **`dbt_valid_to_current` is not retroactive.** Rows already written with
  `NULL` stay `NULL`. Set it at creation, or backfill deliberately.

### Checklist

- [ ] `dbt snapshot` runs before `dbt run` in every pipeline
- [ ] Snapshots read `source()`, not `ref()` of staging
- [ ] `hard_deletes` is set explicitly (the `ignore` default loses information)
- [ ] `dbt_valid_to_current` set on new snapshots, so point-in-time queries need
      no `is null` branch
- [ ] New snapshots use the 1.9+ YAML form, not the legacy `{% snapshot %}` config
- [ ] I can write a point-in-time query without looking it up

---

# Part IV — Data Quality

*Four layers of assurance: is the data right, is the logic right, which rows failed, and is the code consistent.*

---

## Session 4.1 — Tests: Generic and Singular

**Covered on:** 2026-06-17, 06-21, 07-02, 07-10, 07-14, 07-16, 07-21, 07-31, 08-03, 08-04 *(11 notes)*

### Why it matters

dbt's testing framework makes data quality a mandatory build step rather than a
monitoring afterthought. Tests are version-controlled next to the models they
validate.

### Generic tests

Declared in YAML, reusable across nodes. Four ship with dbt:

```yaml
models:
  - name: fct_orders
    columns:
      - name: order_id
        tests: [unique, not_null]
      - name: status
        tests:
          - accepted_values:
              values: ['placed', 'shipped', 'delivered', 'cancelled']
      - name: customer_id
        tests:
          - relationships:
              to: ref('dim_customers')
              field: customer_id
```

| Test | Checks |
|---|---|
| `unique` | No duplicate values |
| `not_null` | No NULLs |
| `accepted_values` | Values belong to a defined list |
| `relationships` | Referential integrity (foreign key) |

### Singular tests

Plain SQL files in `tests/`. **The test passes when it returns zero rows** —
write the query to return violations.

```sql
-- tests/assert_shipping_after_order.sql
select order_id, ordered_at, shipped_at
from {{ ref('fct_orders') }}
where shipped_at < ordered_at    -- physically impossible
```

Use them for multi-column or cross-model logic generic tests can't express:
"refunds must not exceed the original order total", "every completed shipment
has a tracking number".

### Severity and thresholds

Not all failures are equal:

```yaml
- name: email
  tests:
    - not_null:
        config:
          severity: warn      # logs a warning, doesn't fail the run
          warn_if: ">= 10"
          error_if: ">= 100"
```

Useful during onboarding when NULLs are expected while upstream is remediated.

### Custom generic tests

Any test you find yourself repeating becomes a macro in `tests/generic/` (or
`macros/`), then a named test in YAML. Before writing your own, check
`dbt-utils` and `dbt-expectations` (Session 5.5):

```yaml
- name: created_at
  tests:
    - dbt_utils.not_null_proportion: {at_least: 0.95}
    - dbt_utils.recency: {datepart: hour, field: created_at, interval: 24}
- name: revenue
  tests:
    - dbt_utils.expression_is_true: {expression: ">= 0"}
```

### Running selectively

```bash
dbt test --select fct_orders          # one model
dbt test --select +fct_orders         # model and everything upstream
dbt test --select test_type:generic   # only generic tests
dbt test --select test_type:unit      # only unit tests (Session 4.2)
dbt test --exclude-resource-type unit_test   # data tests only (1.9+)
dbt build --select fct_orders+        # build + test, interleaved
```

Since 1.9 a data test can carry a `description`, which shows up in the docs and
in Catalog — worth using for any test whose failure isn't self-explanatory:

```yaml
      - name: order_id
        tests:
          - unique:
              description: >
                Duplicate order_ids mean the Shopify webhook replayed.
                Check the ingestion log before touching the model.
```

### Gotchas

- **Test sources, not just models.** `unique`/`not_null` on source columns catch
  bad raw data before it propagates.
- **Tag slow tests** (`config: {tags: ['slow']}`) and `--exclude tag:slow` in CI,
  reserving them for nightly runs.
- **Name singular tests descriptively.** `assert_shipping_after_order.sql`
  documents itself; `test1.sql` does not.
- **Use `dbt build`, not `dbt run && dbt test`** — build tests each model right
  after it's built, so downstream models never consume known-bad data.
- **Treat persistent failures as a deployment blocker.** Data quality debt
  compounds.

### Checklist

- [ ] Every primary key has `unique` + `not_null` — the minimum bar
- [ ] Every foreign key in marts has a `relationships` test (catches join fan-out)
- [ ] Tests live in the same YAML file as the model they test

---

## Session 4.2 — Unit Tests (dbt 1.8+)

**Covered on:** 2026-06-24, 06-28, 07-04, 07-17, 07-22, 07-23, 07-24, 07-29, 08-07, 08-13, 08-16 *(11 notes)*

### Why it matters

Data tests validate *rows in a built table*. Unit tests validate *the SQL logic
itself*, using mock inputs — no real data, no warehouse round-trip on full
tables, and they run **before** the model materialises.

| | Data tests | Unit tests |
|---|---|---|
| Validates | Data quality in built tables | SQL transformation logic |
| Needs real data | Yes | No — uses mocks |
| Speed | Slow | Near-instant |
| Catches bugs | After `dbt run` | Before `dbt run` |

### Mechanics

```yaml
# models/marts/fct_orders.yml
unit_tests:
  - name: test_discount_applied_correctly
    description: "Orders with a coupon have discount subtracted from total."
    model: fct_orders
    given:
      - input: ref('stg_orders')
        rows:
          - {order_id: 1, subtotal: 100, coupon_discount: 10, status: 'shipped'}
          - {order_id: 2, subtotal: 200, coupon_discount: 0,  status: 'pending'}
      - input: ref('stg_customers')
        rows:
          - {customer_id: 42, tier: 'gold'}
    expect:
      rows:
        - {order_id: 1, order_total: 90,  status: 'shipped'}
        - {order_id: 2, order_total: 200, status: 'pending'}
```

Sources mock identically:

```yaml
given:
  - input: source('raw_shopify', 'orders')
    rows:
      - {id: 99, customer_id: 1, total_price: 5000, created_at: '2026-01-15'}
```

### The killer feature: testing `is_incremental()`

The `{% if is_incremental() %}` branch only executes on subsequent runs, which
makes it untestable with data tests. Unit tests can force it:

```yaml
unit_tests:
  - name: test_incremental_filter_excludes_old_events
    model: fct_events
    overrides:
      macros:
        is_incremental: true
      vars:
        cutoff_days: 7
    given:
      - input: ref('stg_events')
        rows:
          - {event_id: 1, occurred_at: '2026-06-01'}   # old — excluded
          - {event_id: 2, occurred_at: '2026-07-20'}   # recent — passes
    expect:
      rows:
        - {event_id: 2, occurred_at: '2026-07-20'}
```

Freeze non-deterministic time the same way:

```yaml
overrides:
  macros:
    dbt.current_timestamp: "'2026-06-01 00:00:00'"
```

### Running

```bash
dbt test --select "test_type:unit"
dbt test --select fct_orders,test_type:unit
dbt build --select fct_orders          # unit tests gate the build
```

Under `dbt build`, a failing unit test means the model **never runs**. Logic
bugs surface at authoring time instead of after bad data has materialised.

### Since 1.9

- Unit tests take an `enabled` config (defaults to `true`), so you can switch
  one off without deleting it.
- They are auto-disabled when their parent model is disabled (1.11+) — which
  removes a whole class of confusing parse errors.
- Filter them out of a data-test run with `--exclude-resource-type unit_test`,
  or select only them with `--select test_type:unit`.
- If the model under test calls a UDF (Session 5.5), the function must exist in
  the warehouse first: `dbt build --select "+my_model" --empty`.

### Checklist

- [ ] Every incremental model has a unit test exercising its filter branch
- [ ] Fixtures are 3–10 rows, only the columns the SQL actually touches
- [ ] Tests cover edge cases: nulls, zeros, empty joins, boundary dates
- [ ] Unit tests run before data tests in CI

---

## Session 4.3 — `store_failures`: Turning Tests into a Debugger

**Covered on:** 2026-06-25, 07-07, 07-26 *(3 notes)*

### Why it matters

A failing test tells you *how many* rows failed, not *which*. `store_failures`
persists the offending rows to a queryable table so you debug without
re-running.

### Mechanics

```yaml
# dbt_project.yml — all tests
tests:
  +store_failures: true
  +schema: dbt_test__audit
```

Or per test:

```yaml
- name: customer_id
  tests:
    - relationships:
        to: ref('customers')
        field: id
        config:
          store_failures: true
          store_failures_as: view    # table (default) or view
```

```bash
dbt test --store-failures --select fct_orders
```

Each failing test gets its own relation named after the test:

```sql
select * from analytics.dbt_test__audit.not_null_orders_customer_id limit 100;
```

| `store_failures_as` | Behavior |
|---|---|
| `table` (default) | Snapshot of what was wrong at test time; survives the session |
| `view` | Recalculated on query; always current; no storage |

Pairs well with `severity: warn` — capture near-misses without blocking the
pipeline:

```yaml
- dbt_utils.accepted_range:
    min_value: 0
    max_value: 1000000
    config:
      store_failures: true
      severity: warn
```

### Checklist

- [ ] Enabled on the tests most likely to page someone at 2am
- [ ] Failure tables land in a dedicated `dbt_test__audit` schema

---

## Session 4.4 — Linting and Formatting: SQLFluff, pre-commit, and `dbt lint`

**Covered on:** *Absent from the archive. Written for the 2026 update.*

### Why it matters

Sessions 4.1–4.3 test whether the data is right. Linting tests whether the
*code* is consistent — and on a team of more than two people, that is what
keeps review comments about logic instead of about capitalisation. It is also
the cheapest CI check you own: it needs no warehouse connection.

### SQLFluff — the incumbent

SQLFluff parses templated SQL and enforces rules. For dbt it needs the dbt
templater so it can resolve `ref()` before parsing:

```bash
pip install sqlfluff sqlfluff-templater-dbt
```

```ini
# .sqlfluff  — sits next to dbt_project.yml
[sqlfluff]
templater = dbt
dialect = snowflake
max_line_length = 120
exclude_rules = ST06, RF01

[sqlfluff:indentation]
tab_space_size = 4
indented_joins = false

[sqlfluff:rules:capitalisation.keywords]
capitalisation_policy = lower

[sqlfluff:rules:capitalisation.identifiers]
extended_capitalisation_policy = lower

[sqlfluff:templater:dbt]
project_dir = ./
profiles_dir = ./
```

```ini
# .sqlfluffignore
target/
dbt_packages/
macros/
```

```bash
sqlfluff lint models/           # report
sqlfluff fix models/            # auto-fix what is safely fixable
sqlfluff lint --format github-annotation-native models/   # CI output
```

Rule codes are stable and worth learning by prefix: `CP` capitalisation,
`LT` layout, `RF` references, `ST` structure, `AM` ambiguous, `CV` convention.

### Suppressing a line

```sql
select * from {{ ref('stg_orders') }}  -- noqa: L044
```

### `dbt lint` — the built-in replacement (Fusion / v2)

Fusion ships its own linter. The migration is close to free because it is
**SQLFluff-compatible**: it reads your existing `.sqlfluff`, uses the same rule
codes, and honours the same `-- noqa` comments.

```bash
dbt lint                       # whole project
dbt lint --select marts        # node selection works
```

The difference is speed. On projects between 1k and 10k models it runs
**40×–250× faster** than parallel SQLFluff and 280×–1500× faster than
single-threaded SQLFluff — because the engine has already parsed the SQL for
its own static analysis, so linting is nearly free.

The practical consequence: linting moves from "a CI step we sometimes skip" to
"something that runs on every keystroke in the editor."

> **Note:** legacy SQLFluff linting is *not* supported inside platform jobs
> running on Fusion. On Fusion, `dbt lint` is the path.

### Wiring it into pre-commit

```yaml
# .pre-commit-config.yaml
repos:
  - repo: https://github.com/sqlfluff/sqlfluff
    rev: 3.2.5
    hooks:
      - id: sqlfluff-lint
        additional_dependencies:
          - dbt-core~=1.9
          - dbt-snowflake~=1.9
          - sqlfluff-templater-dbt

  - repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v5.0.0
    hooks:
      - id: end-of-file-fixer
      - id: trailing-whitespace
      - id: check-yaml
        args: [--allow-multiple-documents]
```

```bash
pre-commit install
pre-commit run --all-files      # first run — expect a large diff
```

The `dbt-checkpoint` package is worth adding on top: it lints the *project*
rather than the SQL — "every model has a description", "every model has at
least one test", "no model references a source directly outside staging".

### In CI

```yaml
# .github/workflows/lint.yml
name: lint
on: pull_request

jobs:
  sqlfluff:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
        with: {python-version: "3.11"}
      - run: pip install sqlfluff sqlfluff-templater-dbt dbt-snowflake
      - run: dbt deps
      - run: sqlfluff lint --format github-annotation-native models/
```

Run this as a **separate job** from the dbt build (Session 9.10). It needs no
warehouse credentials, so it finishes in seconds and fails fast.

### Gotchas

- **Adopting on an existing project produces a 400-file diff.** Land the
  formatting commit on its own, add it to `.git-blame-ignore-revs`, then turn
  the CI gate on.
- **Start with a narrow rule set.** Turning on all rules at once guarantees the
  team disables the whole thing. Begin with capitalisation + line length.
- **The dbt templater needs a working profile.** In CI that means a
  `profiles.yml` exists — even a dummy one — or SQLFluff can't render `ref()`.
- **`sqlfluff fix` is not always safe.** Review the diff; some layout fixes
  change query semantics in exotic cases.
- **Lint `models/`, not the repo root.** `target/` and `dbt_packages/` contain
  generated SQL that will never pass.

### Checklist

- [ ] `.sqlfluff` committed, dialect matches the warehouse
- [ ] `target/` and `dbt_packages/` in `.sqlfluffignore`
- [ ] pre-commit installed locally by every contributor
- [ ] A lint job in CI that runs without warehouse credentials
- [ ] On Fusion: `dbt lint` replaces the SQLFluff job

---

# Part V — Programmability

*Where dbt stops being SQL files and becomes a system you can extend — Jinja, macros, warehouse functions, materializations, and packages.*

---

## Session 5.1 — Macros and Jinja

**Covered on:** 24 notes, 2026-06-16 through 2026-08-18

### Why it matters

Jinja turns SQL into a programmable language. Macros are the difference between
copying a `CASE WHEN` block into 40 models and calling
`{{ classify_revenue(amount) }}` everywhere, defined and tested once.

### Anatomy

```sql
-- macros/cents_to_dollars.sql
{% macro cents_to_dollars(column_name, scale=2) %}
    round({{ column_name }} / 100.0, {{ scale }})
{% endmacro %}
```

```sql
select
    order_id,
    {{ cents_to_dollars('amount_cents') }}      as amount_usd,
    {{ cents_to_dollars('shipping_cents', 4) }} as shipping_usd
from {{ ref('stg_orders') }}
```

Macros compile to plain SQL before hitting the warehouse — **zero runtime cost**.

### Control flow

```sql
{% macro safe_divide(numerator, denominator) %}
    case
        when {{ denominator }} = 0 or {{ denominator }} is null then null
        else {{ numerator }} / nullif({{ denominator }}, 0)
    end
{% endmacro %}
```

```sql
{% macro safe_hash(columns) %}
    md5(concat_ws('||',
        {% for col in columns %}
            coalesce(cast({{ col }} as varchar), '')
            {%- if not loop.last %}, {% endif %}
        {% endfor %}
    ))
{% endmacro %}
```

### Context variables

```sql
{% macro is_production() %}
    {{ target.name == 'prod' }}
{% endmacro %}
```

`{{ this }}` is always the current model's relation:

```sql
{% macro get_max_loaded_at() %}
    {% if is_incremental() %}
        (select max(loaded_at) from {{ this }})
    {% else %}
        '1970-01-01'::timestamp
    {% endif %}
{% endmacro %}
```

### Debugging

```sql
{{ log("Current value: " ~ val, info=True) }}
```

`info=True` prints to the console at default log level.

### Gotchas

- **One macro, one job.** A macro that does five things can't be tested or reused.
- **Document macros in `macros/schema.yml`** — dbt renders them in the docs site.
- **Reach for `dbt-utils` first** (Session 5.5). `generate_surrogate_key`,
  `star`, `union_relations` are battle-tested; your version is a maintenance
  liability.

---

## Session 5.2 — `run_query` and the `execute` Flag

**Covered on:** 2026-08-15 *(1 note; the `{% if execute %}` guard is repeated across the macro notes)*

### Why it matters

`run_query` executes SQL against the warehouse *during* a run and returns an
Agate table — enabling macros driven by live warehouse state.

### The two-phase model

dbt runs macros **twice**:

1. **Parse/compile phase** — builds the DAG, resolves `ref()`. **No warehouse
   connection exists.**
2. **Execute phase** — runs models. Warehouse is live.

`run_query` only works in phase 2. **Always guard it:**

```sql
{% macro get_column_values(table, column) %}
    {% set query %}
        select distinct {{ column }} from {{ table }} order by 1
    {% endset %}

    {% set results = run_query(query) %}
    {% if execute %}
        {{ return(results.columns[0].values()) }}
    {% else %}
        {{ return([]) }}
    {% endif %}
{% endmacro %}
```

An unguarded `run_query` crashes `dbt compile`, `dbt parse`, and `dbt ls`.

### Reading results

```sql
{% set id_list    = results.columns['id'].values() %}   -- column as a list
{% set first_name = results.rows[0]['name'] %}          -- single scalar
{% for row in results %} ... {% endfor %}               -- iterate
```

### Gotchas

- **Results are in-memory Python objects.** Use it for config lookups and scalar
  aggregates — never to pull millions of rows.
- **Beware invisible dependencies.** If a macro queries a model to generate
  another model's SQL, you've created a build-order dependency the DAG can't
  see. Query seeds or external tables instead.

---

## Session 5.3 — `dbt run-operation`

**Covered on:** 2026-08-11 *(1 note)*

### Why it matters

Invoke any macro directly from the CLI without building a model — the escape
hatch for maintenance, setup, and macro debugging.

```bash
dbt run-operation <macro_name> --args '{"arg1": "value1"}'
```

### Use cases

```sql
-- macros/vacuum_table.sql
{% macro vacuum_table(schema, table) %}
  {% set query %}
    VACUUM {{ schema }}.{{ table }};
    ANALYZE {{ schema }}.{{ table }};
  {% endset %}
  {% do run_query(query) %}
  {{ log("Vacuumed " ~ schema ~ "." ~ table, info=True) }}
{% endmacro %}
```

```bash
dbt run-operation vacuum_table --args '{"schema": "analytics", "table": "fct_orders"}'
dbt run-operation create_audit_schema
dbt run-operation drop_schema_if_empty --args '{"schema_name": "dbt_dev_ktran"}'
```

### Limitations

- **Does not participate in the DAG.** No `ref()` dependencies are built.
- **No dry-run mode.** DDL/DML executes immediately.
- **Output only appears via `{{ log(..., info=True) }}`.** Return values are
  discarded.

### `run-operation` vs `on-run-end`

Use `run-operation` for one-off or environment-specific invocations; register
the macro under `on-run-end` for routine post-build steps (Session 6.4).

---

## Session 5.4 — Cross-Database Macros and `adapter.dispatch`

**Covered on:** 2026-07-09, 07-18, 07-25, 08-15 *(4 notes)*

### Why it matters

SQL dialects diverge on the basics. Cross-database macros emit the right SQL for
whichever adapter you're on.

| Operation | Snowflake | BigQuery | Redshift |
|---|---|---|---|
| Truncate to month | `date_trunc('month', col)` | `date_trunc(col, month)` | `date_trunc('month', col)` |
| Concat | `col1 \|\| col2` | `concat(col1, col2)` | `col1 \|\| col2` |
| Safe cast | `try_cast(...)` | `safe_cast(... as int64)` | `case when ... end` |

### Built-ins under the `dbt` namespace

```sql
select
    {{ dbt.date_trunc('month', 'created_at') }}          as created_month,
    {{ dbt.concat(["first_name", "' '", "last_name"]) }} as full_name,
    {{ dbt.split_part('email', "'@'", 2) }}              as email_domain
from {{ ref('stg_users') }}
```

| Macro | Purpose |
|---|---|
| `dbt.date_trunc(part, date)` | Truncate to day/week/month/year |
| `dbt.dateadd(part, interval, from)` | Add intervals |
| `dbt.datediff(part, from, to)` | Difference between dates |
| `dbt.concat([...])` | String concatenation |
| `dbt.hash(field)` | MD5-like hash |
| `dbt.safe_cast(field, type)` | Cast returning NULL on failure |
| `dbt.split_part(str, delim, n)` | Nth part of a delimited string |
| `dbt.any_value(expr)` | Any value (for GROUP BY) |
| `dbt.last_day(date, part)` | Last day of the containing period |

### Writing your own with `adapter.dispatch`

```sql
{% macro custom_isnumeric(column) %}
    {{ return(adapter.dispatch('custom_isnumeric', 'my_project')(column)) }}
{% endmacro %}

{% macro default__custom_isnumeric(column) %}
    ({{ column }} ~ '^[0-9]+$')
{% endmacro %}

{% macro snowflake__custom_isnumeric(column) %}
    try_to_number({{ column }}) is not null
{% endmacro %}

{% macro bigquery__custom_isnumeric(column) %}
    safe_cast({{ column }} as int64) is not null
{% endmacro %}
```

dbt selects the adapter-prefixed implementation automatically; `default__` is
the fallback. This is exactly how `dbt-utils` works internally.

**Default to cross-database macros over raw SQL** for date math, casting, and
string ops — even on a single warehouse. It costs nothing and makes the project
portable. Verify with `dbt compile` and read `target/compiled/`.

---

## Session 5.5 — User-Defined Functions (dbt 1.11+)

**Covered on:** *New feature, absent from the archive. Written for the 2026 update.*

### Why it matters

Sessions 5.1–5.4 built reusable logic as **macros** — Jinja that expands into
SQL at compile time. Macros have one hard limit: they only exist inside dbt.
The analyst querying the warehouse from a notebook, the BI tool computing a
derived column, the ad-hoc query in a Snowflake worksheet — none of them can
call your `cents_to_dollars` macro.

UDFs (dbt 1.11+) fix that. They are real warehouse objects, versioned in your
repo, built as DAG nodes, and callable from anywhere.

### Mechanics

A UDF is two files in a `functions/` directory:

```
functions/
├── is_positive_int.sql     # the body
└── is_positive_int.yml     # the signature and config
```

```sql
-- functions/is_positive_int.sql
-- BigQuery / Snowflake / Databricks: expression only
regexp_instr(a_string, '^[0-9]+$')
```

```sql
-- Redshift / Postgres want a full statement
select regexp_instr(a_string, '^[0-9]+$')
```

```yaml
# functions/is_positive_int.yml
functions:
  - name: is_positive_int
    description: 1 if the string is a positive integer, else 0.
    config:
      schema: udf
      database: analytics
      volatility: deterministic     # deterministic | stable | non-deterministic
    arguments:
      - name: a_string
        data_type: string
        description: The string to test.
    returns:
      data_type: integer
```

### Calling it

```sql
-- models/marts/fct_orders.sql
select
    order_id,
    external_ref,
    {{ function('is_positive_int') }}(external_ref) as ref_is_numeric
from {{ ref('stg_orders') }}
```

compiles to:

```sql
select
    order_id,
    external_ref,
    analytics.udf.is_positive_int(external_ref) as ref_is_numeric
from analytics.stg.stg_orders
```

`function()` is to UDFs what `ref()` is to models: it resolves the fully
qualified name *and* creates the DAG edge, so dbt builds the function before
anything that calls it.

### Building and selecting

```bash
dbt build --select "resource_type:function"   # all UDFs
dbt build --select is_positive_int            # one
dbt build --select "+fct_orders"              # pulls in the UDFs it needs
dbt list  --resource-type function
```

`--defer`/`--state` work: in CI, `function()` resolves to the production UDF if
the branch hasn't built its own (Session 9.4).

### Python and JavaScript UDFs

```python
# functions/is_positive_int.py
import re

def main(a_string):
    return 1 if re.search(r'^[0-9]+$', a_string or '') else 0
```

```yaml
functions:
  - name: is_positive_int
    config:
      runtime_version: "3.11"       # required
      entry_point: main             # required
      packages: [numpy, "pandas==1.5.0"]
      schema: udf
    arguments:
      - name: a_string
        data_type: string
    returns:
      data_type: integer
```

| Language | Adapters |
|---|---|
| SQL | BigQuery, Snowflake, Redshift, Postgres, Databricks |
| Python | Snowflake, BigQuery, Databricks (Unity Catalog) |
| JavaScript | Snowflake, BigQuery *(1.12+)* |

Databricks Python needs a top-level `return main(a_string)` after the
definition, and ignores `runtime_version` / `entry_point`.

### UDF or macro?

| | **UDF** | **Macro** |
|---|---|---|
| Runs at | Query time, in the warehouse | Compile time, in dbt |
| Usable outside dbt | ✅ BI tools, notebooks, worksheets | ❌ |
| Creates a warehouse object | ✅ dbt manages its lifecycle | ❌ |
| Can generate *different* SQL per platform | ❌ | ✅ (`adapter.dispatch`, Session 5.4) |
| Can emit DDL/DML | ❌ | ✅ |
| Portable across warehouses | ❌ one per platform | ✅ one macro |

**Use a UDF** when the logic is a *value transformation* that people outside
dbt also need. **Use a macro** when you are generating SQL, branching on
adapter, or building DDL.

### Overloads (1.12+)

```yaml
functions:
  - name: is_positive_int
    arguments:
      - {name: a_string, data_type: string}
    returns: {data_type: integer}
    overloads:
      - defined_in: is_positive_int_numeric
        arguments:
          - {name: a_num, data_type: numeric}
        returns: {data_type: integer}
```

with a second body file `functions/is_positive_int_numeric.sql`. All overloads
form one DAG node and build together.

### Gotchas

- **UDFs are per-platform.** The `regexp_instr` body above is not portable.
  A multi-warehouse project keeps parallel definitions or falls back to macros.
- **Scalar and aggregate only.** No table functions, no Java/Scala.
- **`volatility` matters for performance.** Marking a genuinely deterministic
  function as such lets the optimiser cache and fold it; marking a
  non-deterministic one as deterministic produces wrong results.
- **Unit-testing a model that calls a UDF requires the UDF to exist.** Build it
  first: `dbt build --select "+my_model" --empty` (Session 9.6).
- **`state:modified` tracks UDF signatures** (arguments and returns), so a
  signature change correctly rebuilds downstream models.
- **Give UDFs their own schema and grant on it.** Otherwise every consumer needs
  usage on your marts schema.

### Checklist

- [ ] UDFs live in `functions/`, one `.sql`/`.py` + one `.yml` each
- [ ] Called via `{{ function('name') }}`, never hard-coded
- [ ] `volatility` set honestly
- [ ] A dedicated UDF schema with grants for BI consumers
- [ ] The macro-vs-UDF decision is written down for the team

---

## Session 5.6 — Custom Materializations

**Covered on:** *Absent from the archive. Written for the 2026 update.*

### Why it matters

The built-in materializations (Session 1.4) cover 99% of work. The remaining 1%
is real: writing to an external system, an audit-history table that logs every
build, a platform-specific object dbt doesn't ship support for, or a
company-wide "table plus mandatory row-count log" pattern you want to enforce by
construction rather than by review.

A materialization is just a macro with a special decorator, so this is an
extension of Session 5.1 rather than a new mechanism.

### Anatomy

```sql
-- macros/materializations/audited_table.sql
{% materialization audited_table, default %}

  {%- set target_relation = this.incorporate(type='table') -%}
  {%- set existing_relation = load_relation(this) -%}
  {%- set tmp_relation = make_temp_relation(target_relation) -%}

  -- 1. run the model's pre-hooks
  {{ run_hooks(pre_hooks, inside_transaction=False) }}

  {% call statement('main') -%}
    {{ create_table_as(False, tmp_relation, sql) }}
  {%- endcall %}

  -- 2. swap into place
  {% if existing_relation is not none %}
    {{ adapter.drop_relation(existing_relation) }}
  {% endif %}
  {{ adapter.rename_relation(tmp_relation, target_relation) }}

  -- 3. our custom bit: log the build
  {% call statement('audit') -%}
    insert into analytics.meta.build_log (model_name, built_at, row_count)
    select '{{ this.identifier }}', current_timestamp, count(*)
    from {{ target_relation }}
  {%- endcall %}

  {{ run_hooks(post_hooks, inside_transaction=False) }}
  {{ adapter.commit() }}

  {{ return({'relations': [target_relation]}) }}

{% endmaterialization %}
```

```sql
-- models/marts/fct_payments.sql
{{ config(materialized='audited_table') }}
select ...
```

### The contract

Four things every materialization must do:

1. **Run hooks** — `run_hooks(pre_hooks)` and `run_hooks(post_hooks)`, or
   Session 6.4 silently stops working for these models.
2. **Emit exactly one `statement('main')`** — this is what dbt times and counts
   in `run_results.json`. No `main`, no row counts, no timing.
3. **Return relations** — `{{ return({'relations': [target_relation]}) }}` so
   dbt can cache and invalidate correctly.
4. **Commit** — `adapter.commit()` where the adapter is transactional.

### Adapter dispatch

`{% materialization name, default %}` is the fallback. Override per platform:

```sql
{% materialization audited_table, adapter='snowflake' %}
  ...
{% endmaterialization %}
```

dbt picks the adapter-specific one when it exists, else `default` — the same
resolution rule as `adapter.dispatch` (Session 5.4).

### Shipping it in a package

Materializations are macros, so they distribute through `packages.yml`
(Session 5.7) like anything else. This is how a platform team rolls one
standard out to twenty project repos.

### Gotchas

- **You are now maintaining warehouse DDL.** Every adapter upgrade is a
  potential break, and nobody upstream is testing your materialization.
- **Fusion / dbt Core v2 parity is not guaranteed.** The Rust engine
  statically analyses SQL; heavily dynamic custom materializations are the most
  likely thing in a project to need rework on migration (Part XII). Check this
  before writing a new one.
- **Forgetting `statement('main')`** produces a model that builds fine and
  reports nothing — no rows, no timing, invisible in artifacts (Session 9.11).
- **Debug with `dbt run --select model --log-level debug`** and read the
  compiled SQL in `target/run/`. There is no step-through debugger.

### Rule of thumb

Before writing one, check in order: (1) can a post-hook do it (Session 6.4)?
(2) can a package do it? (3) can `on-run-end` do it (Session 5.3)? Only if all
three are no is a custom materialization the right tool — it is the highest
maintenance-cost extension point dbt has.

---

## Session 5.7 — Packages: `dbt-utils` and the Ecosystem

**Covered on:** 19 notes, 2026-06-19 through 2026-08-18

### Mechanics

```yaml
# packages.yml
packages:
  - package: dbt-labs/dbt_utils
    version: 1.3.0

  - package: calogica/dbt_expectations
    version: 0.10.4

  - git: "https://github.com/your-org/dbt-shared-macros.git"
    revision: "v1.2.0"      # pin a tag, never a branch

  - local: ../my_shared_package
```

```bash
dbt deps
```

**Commit `packages.yml`; gitignore `dbt_packages/`.** Let CI install fresh.

### `dbt-utils` — the standard library

| Macro | Purpose |
|---|---|
| `dbt_utils.generate_surrogate_key(['a','b'])` | Warehouse-agnostic hash key |
| `dbt_utils.star(from=ref('m'), except=[...])` | `SELECT *` minus listed columns |
| `dbt_utils.union_relations([ref('a'), ref('b')])` | UNION ALL across refs |
| `dbt_utils.pivot(column, values, ...)` | Dynamic CASE WHEN pivot |
| `dbt_utils.unpivot(...)` | Wide → long |
| `dbt_utils.date_spine(...)` | Continuous date series |

```sql
select {{ dbt_utils.star(from=ref('stg_orders'),
                         except=['_fivetran_synced', '_fivetran_deleted']) }}
from {{ ref('stg_orders') }}
```

Plus generic tests: `expression_is_true`, `accepted_range`, `not_null_proportion`,
`recency`, `equal_rowcount`, `sequential_values`, `not_empty_string`.

### The other packages worth knowing

| Package | Purpose |
|---------|---------|
| `dbt-labs/codegen` | Auto-generate source and model YAML from the warehouse |
| `dbt-labs/audit_helper` | Diff model output between branches/environments |
| `calogica/dbt_expectations` | Great Expectations-style tests |
| `dbt-labs/dbt_project_evaluator` | Lint the project against best practices |
| `brooklyn-data/dbt_artifacts` | Load run metadata into the warehouse |
| `Fivetran/fivetran_utils` | Utilities for Fivetran-loaded data |

`codegen` is the biggest time-saver when staging a new source:

```bash
dbt run-operation codegen.generate_source \
  --args '{"schema_name": "raw", "database_name": "analytics", "generate_columns": true}'

dbt run-operation codegen.generate_model_yaml \
  --args '{"model_names": ["stg_orders", "stg_customers"]}'
```

`dbt_project_evaluator` materialises audit models (undocumented sources, models
without tests, naming violations) as queryable tables — fail CI when any
violation count is non-zero.

### Gotchas

- **Pin exact versions, never ranges.** Unpinned packages cause
  non-deterministic CI failures when upstream ships a change.
- **`dbt deps --upgrade` is a deliberate act.** Read the changelog — packages
  with generic tests can start flagging new failures.
- **Audit package macros before adopting.** They run with your warehouse
  credentials. Treat them like any third-party dependency.

---

# Part VI — Configuration and Environments

*How the same project produces different objects in different places, and how you keep that predictable across versions.*

---

## Session 6.1 — Profiles and Targets

**Covered on:** 2026-08-16 *(1 note)*

### Mechanics

`~/.dbt/profiles.yml` — outside the repo, so credentials stay out of version
control.

```yaml
my_project:
  target: dev
  outputs:
    dev:
      type: snowflake
      account: "{{ env_var('SNOWFLAKE_ACCOUNT') }}"
      user: "{{ env_var('SNOWFLAKE_USER') }}"
      private_key_path: ~/.ssh/snowflake_key.p8
      role: TRANSFORMER_DEV
      database: ANALYTICS_DEV
      warehouse: COMPUTE_WH_DEV
      schema: "dbt_{{ env_var('DBT_USER', 'local') }}"
      threads: 4

    prod:
      type: snowflake
      account: "{{ env_var('SNOWFLAKE_ACCOUNT') }}"
      user: "{{ env_var('SNOWFLAKE_SVC_USER') }}"
      private_key_path: /secrets/snowflake_key.p8
      role: TRANSFORMER_PROD
      database: ANALYTICS
      warehouse: COMPUTE_WH_PROD
      schema: dbt_prod
      threads: 16
```

### Three design decisions

1. **Per-developer schemas** (`dbt_{{ env_var('DBT_USER') }}`) — every developer
   gets an isolated sandbox; nobody clobbers anybody.
2. **Threads** — parallelism vs warehouse concurrency load. 4 for dev, 16+ for
   CI/prod.
3. **`env_var()` for every secret** — `profiles.yml` becomes a shareable
   template.

```bash
dbt run --target prod --select tag:critical
dbt debug                # test the active connection
dbt debug --target prod
```

`dbt debug` is the first thing a new contributor runs — it catches missing env
vars, bad credentials, and network issues before any model runs.

**Commit a `profiles.yml.example`** so new contributors know what to configure.

### On the dbt platform

`profiles.yml` does not exist. Connections and credentials are managed in the
UI, and since 2026 they are grouped into **Profiles** — project-level
connection and credential sets, auto-created for existing projects. An
environment (Session 10.2) binds one of them. The mental model is the same;
the file is just somewhere else.

### The `DBT_ENGINE_` rename (1.11+)

Engine-level environment variables gained a prefix:

| Old | New |
|---|---|
| `DBT_STATE` | `DBT_ENGINE_STATE` |
| `DBT_PROJECT_DIR` | `DBT_ENGINE_PROJECT_DIR` |

This bites in CI configs and Dockerfiles rather than in the project itself.
`DBT_PROFILES_DIR` and your own `env_var()` names are unaffected — only dbt's
own engine configuration moved.

dbt v2 also reads a `.env` file from the working directory automatically, which
removes most of the reason to export these by hand locally.

---

## Session 6.2 — Variables: `var()` and `env_var()`

**Covered on:** 2026-06-20, 06-28, 07-05, 07-17, 07-25, 07-30, 08-08, 08-09, 08-17 *(9 notes)*

### Mechanics

```yaml
# dbt_project.yml
vars:
  start_date: '2020-01-01'
  lookback_days: 3
  payment_methods: ['credit_card', 'paypal', 'bank_transfer']
```

```sql
where created_at >= '{{ var("start_date") }}'
  and region      =  '{{ var("target_region", "global") }}'   -- with fallback
```

Override at run time — `--vars` always beats `dbt_project.yml`:

```bash
dbt run --vars 'start_date: 2026-01-01'
dbt run --vars '{start_date: 2026-01-01, environment: prod}'
dbt run --select fct_events --vars "start_date: $(date -d '7 days ago' +%Y-%m-%d)"
```

### Variables can drive config, not just SQL

```yaml
models:
  my_project:
    marts:
      +materialized: "{{ 'table' if var('environment') == 'prod' else 'view' }}"
```

Tables in production, cheap views in development — without touching a model file.

### Scoping to packages

```yaml
vars:
  dbt_utils:
    surrogate_key_treat_nulls_as_empty_string: true
  my_project:
    start_date: '2020-01-01'
```

### Gotchas

- **Always provide defaults** so models compile locally without `--vars`.
- **Don't branch wildly on variables.** If a model behaves completely
  differently per variable, it's two models.
- `env_var()` reads the environment (used heavily in `profiles.yml`); `var()`
  reads dbt project variables. They are not interchangeable.

---

## Session 6.3 — Custom Schema, Database, and Alias

**Covered on:** 2026-07-01, 07-27, 08-11, 08-12 *(4 notes)*

### Why it matters

dbt's *default* schema resolution concatenates target schema and custom schema,
producing `analytics_staging` in production instead of `staging`. Almost every
project needs to override it.

### Default behaviour

```yaml
models:
  my_project:
    staging: {+schema: staging}
    marts:   {+schema: marts}
```

| `target.schema` | custom | result |
|---|---|---|
| `dbt_alice` | `staging` | `dbt_alice_staging` |
| `analytics` (prod) | `staging` | `analytics_staging` ← ugly |

### The override

```sql
-- macros/generate_schema_name.sql
{% macro generate_schema_name(custom_schema_name, node) -%}
    {%- set default_schema = target.schema -%}

    {%- if custom_schema_name is none -%}
        {{ default_schema }}

    {%- elif target.name == 'prod' -%}
        {{ custom_schema_name | trim }}

    {%- else -%}
        {{ default_schema }}_{{ custom_schema_name | trim }}
    {%- endif -%}
{%- endmacro %}
```

| target | schema | custom | result |
|---|---|---|---|
| `dev` | `dbt_alice` | `staging` | `dbt_alice_staging` |
| `prod` | `analytics` | `staging` | `staging` |

Clean production names; isolated developer namespaces.

### Routing by node metadata

The `node` argument carries model metadata, so you can route by tag:

```sql
{% macro generate_schema_name(custom_schema_name, node) -%}
    {%- if 'pii' in (node.config.tags | default([])) -%}
        {{ 'restricted_pii' }}
    {%- elif custom_schema_name is not none and target.name == 'prod' -%}
        {{ custom_schema_name | trim }}
    {%- else -%}
        {{ target.schema }}{% if custom_schema_name %}_{{ custom_schema_name | trim }}{% endif %}
    {%- endif -%}
{%- endmacro %}
```

`generate_database_name` works the same way for multi-database warehouses;
`generate_alias_name` controls the table name itself.

### Gotchas

- **Branch on `target.name`, not `target.schema`.** Target names (`dev`, `ci`,
  `prod`) are explicit; schema names vary per developer.
- **Never hardcode schema strings in SQL.** `ref()`/`source()` resolve the
  fully-qualified name from your macro.
- **Verify with `dbt compile`** and read `target/compiled/` before running.

---

## Session 6.4 — Hooks

**Covered on:** 13 notes, 2026-06-20 through 2026-08-20

### The four hook types

| Hook | Fires |
|------|-------|
| `on-run-start` | Once, before any node in a run |
| `on-run-end` | Once, after all nodes complete (even on failure) |
| `pre-hook` | Before each individual model builds |
| `post-hook` | After each individual model builds |

### Project-level

```yaml
# dbt_project.yml
on-run-start:
  - "CREATE TABLE IF NOT EXISTS audit.dbt_runs (run_id VARCHAR, started_at TIMESTAMP, env VARCHAR)"
  - "INSERT INTO audit.dbt_runs VALUES ('{{ invocation_id }}', CURRENT_TIMESTAMP, '{{ target.name }}')"

on-run-end:
  - "UPDATE audit.dbt_runs SET finished_at = CURRENT_TIMESTAMP WHERE run_id = '{{ invocation_id }}'"
```

`{{ invocation_id }}` is a UUID unique to each run; `{{ target.name }}` is the
active target.

### Model-level

```yaml
models:
  my_project:
    marts:
      +post-hook: "{{ grant_select('reporter') }}"
```

```sql
{{ config(
    materialized='table',
    post_hook=["ANALYZE {{ this }}"]
) }}
```

Multiple hooks run in list order. Extract anything beyond a one-liner into a
macro so `dbt_project.yml` stays readable.

### The `results` variable in `on-run-end`

```sql
on-run-end:
  - "{% for rel in results | selectattr('status', 'equalto', 'success')
                           | map(attribute='node.relation_name') %}
       GRANT SELECT ON {{ rel }} TO ROLE reporter;
     {% endfor %}"
```

Grants only to models that actually succeeded.

### Gotchas

- **`{{ this }}` exists only in model-level hooks**, not `on-run-start`/`end`.
- **Hooks run inside the model's transaction** on Postgres/Redshift — a hook
  failure rolls back the model. Use `transaction: false` for DDL that must
  auto-commit.
- **Hooks run even on failed models.**
- **Hooks are not retried.** Build retry into the macro if you need it.
- **Prefer `on-run-end` over per-model `post-hook` for grants** — it batches
  instead of firing one `GRANT` per model. Better still, use the `grants` config
  (Session 6.5), which is idempotent where raw hooks are not.

---

## Session 6.5 — Grants

**Covered on:** 2026-07-26, 08-07 *(2 notes)*

### Mechanics

```yaml
# dbt_project.yml
models:
  my_project:
    staging:
      +grants:
        select: ['dbt_developer_role']          # only devs see staging

    marts:
      +grants:
        select: ['reporter', 'bi_tool_role']    # BI reads marts

    finance:
      +grants:
        select: ['reporter', 'bi_tool_role', 'finance_team_role']
```

Override per model in `schema.yml` or in the config block:

```sql
{{ config(grants={'select': ['reporter', 'finance_role']}) }}
```

### When grants apply

| Materialization | When |
|---|---|
| `view` / `table` | After each create/replace — reapplied every run |
| `incremental` | Only on first build; later runs skip re-granting (use `--full-refresh` to force) |
| `ephemeral` | N/A — no relation created |

### Snowflake: `copy_grants`

Replacing a relation on Snowflake **revokes all existing grants**. Set:

```yaml
models:
  +copy_grants: true
```

This uses `CREATE OR REPLACE ... COPY GRANTS`. On Snowflake this is almost
always what you want.

Default semantics are **append** — dbt adds configured roles but never revokes
others. Supported on Snowflake, BigQuery, Databricks, Redshift, and Postgres
since dbt 1.2.

---

## Session 6.6 — Behaviour Change Flags and Deprecation Handling

**Covered on:** *Absent from the archive. Written for the 2026 update.*

### Why it matters

dbt Labs commits to backward compatibility across every 1.x release. The way
they keep that promise while still fixing bad defaults is the **behaviour change
flag**: a new behaviour ships *off*, you opt in when ready, and it becomes the
default in a later major version. If you have ever wondered why a documented fix
"isn't working," this is usually why — the flag is still off.

Understanding the flag mechanism is what makes upgrading (Part XII) routine
instead of frightening.

### Mechanics

```yaml
# dbt_project.yml
flags:
  # 1.9
  state_modified_compare_more_unrendered_values: true
  skip_nodes_if_on_run_start_fails: true
  require_nested_cumulative_type_params: true
  require_batched_execution_for_custom_microbatch_strategy: true

  # 1.10
  validate_macro_args: true
  require_all_warnings_handled_by_warn_error: true

  # 1.11
  require_unique_project_resource_names: true
  require_ref_searches_node_package_before_root: false
```

The lifecycle is always the same:

```
ships off (warning)  →  you flip it on  →  becomes the default  →  flag removed
```

Flags reaching maturity on the platform's Latest track were dated
**2026-09-01**, which is why a project that "worked last month" can start
failing without a code change. Flip flags on deliberately, one at a time, ahead
of that date — not all at once on the morning it lands.

### The ones worth knowing

| Flag | What it fixes |
|---|---|
| `state_modified_compare_more_unrendered_values` | Kills the classic Slim CI false positive where a dev/prod config difference marks everything modified (Session 9.7) |
| `skip_nodes_if_on_run_start_fails` | A failing `on-run-start` hook no longer lets the run continue as if nothing happened (Session 6.4) |
| `validate_macro_args` | Macro YAML argument names/types must match the Jinja definition |
| `require_unique_project_resource_names` | Duplicate resource names error instead of warn |

### Deprecations you will hit today

dbt 1.10 and 1.11 turned on a set of warnings that flag code which becomes
invalid in v2. Fix them now; they are all mechanical.

**1. Custom top-level YAML keys must move under `meta`**

```yaml
# deprecated
models:
  - name: fct_orders
    owner_team: finance

# correct
models:
  - name: fct_orders
    config:
      meta:
        owner_team: finance
```

Read it back with `{{ config.meta_get('owner_team') }}` or
`{{ config.meta_require('owner_team') }}` (1.10+).

**2. Properties are moving under `config:`**

`freshness`, `meta`, `tags`, `docs`, `group`, `access` are all becoming
configs rather than bare properties:

```yaml
# deprecated
sources:
  - name: shopify
    freshness:
      warn_after: {count: 24, period: hour}

# correct
sources:
  - name: shopify
    config:
      freshness:
        warn_after: {count: 24, period: hour}
```

**3. `--models` / `-m` is dead**

It was renamed to `--select` / `-s` in v0.21 (October 2021). It *warns* in
1.10 and *errors* in Fusion. Grep your orchestration configs — Airflow DAGs and
old job definitions are where this hides.

**4. `warn_error_options` renamed its keys**

```yaml
flags:
  warn_error_options:
    error:                       # was "include"
      - UnusedResourceConfigPath
    warn:                        # was "exclude"
      - NoNodesForSelectionCriteria
    silence:                     # new
      - CustomTopLevelKeyDeprecation
```

**5. Duplicate YAML keys and orphaned Jinja blocks now warn.** Both were
previously silent — a duplicate key just overwrote the earlier one.

**6. Standalone YAML anchors move under an `anchors:` key** (1.10):

```yaml
anchors:
  - &id_column
    name: id
    description: Unique identifier.
    data_type: int
```

**7. `--output`/`-o` for `sources.json`** is deprecated; use `--target-path`.

### Turning the noise into a gate

Once a project is clean, keep it clean:

```bash
dbt build --warn-error-options '{"error": ["Deprecations"]}'
```

Mid-migration, do the reverse so an existing `--warn-error` CI job doesn't
fail on newly-added deprecation warnings:

```bash
dbt build --warn-error --warn-error-options '{"warn": ["Deprecations"]}'
```

### Gotchas

- **`--warn-error` plus a new minor version is a broken build waiting to
  happen.** Every release adds warnings. Pin the behaviour with
  `warn_error_options` rather than the blunt flag.
- **Flags are project-wide, not per-model.** There is no gradual rollout inside
  a project; the gradual part is *which flag*, not *which model*.
- **`dbt-autofix` handles most deprecations mechanically** — see Session 12.2.
- **JSON-schema YAML validation is on by default in 1.11** for Snowflake,
  Databricks, BigQuery and Redshift. Expect a wave of warnings on first upgrade;
  most are real typos.

### Checklist

- [ ] Every current behaviour flag explicitly listed in `dbt_project.yml`
- [ ] `dbt parse` is warning-free
- [ ] No `--models` / `-m` anywhere in orchestration
- [ ] Custom YAML keys nested under `config.meta`
- [ ] `warn_error_options` used instead of bare `--warn-error`

---

# Part VII — Interfaces and Governance

*What changes when other teams depend on your models: contracts, versions, access boundaries, and the projects and dashboards on the other side of them.*

---

## Session 7.1 — Model Contracts

**Covered on:** 46 notes, 2026-06-16 through 2026-08-17 — **the most-revisited topic in the entire archive.**

### Why it matters

Without a contract, a model's column list and types are implicit — they emerge
from whatever the SQL happens to return. A refactor that renames `customer_id`
to `id` silently breaks every downstream model and BI tool. Contracts (dbt 1.5+)
make that breakage explicit at build time.

**Think of a contract as a type signature for a SQL model.**

### Mechanics

```yaml
models:
  - name: fct_orders
    config:
      contract:
        enforced: true
    columns:
      - name: order_id
        data_type: bigint
        constraints:
          - type: not_null
          - type: primary_key
      - name: customer_id
        data_type: bigint
        constraints:
          - type: not_null
      - name: order_date
        data_type: date
      - name: order_total
        data_type: numeric
      - name: status
        data_type: varchar
```

With `enforced: true`, dbt:

1. compares the compiled SQL's output columns against the declaration,
2. **fails before writing to the warehouse** on any mismatch,
3. applies DDL-level constraints where the warehouse supports them.

### Constraint types

| Constraint | Enforced at | Notes |
|------------|-------------|-------|
| `not_null` | Build time (query fails) | Works on all adapters |
| `primary_key` | DDL level | Adapter-dependent — some enforce, some just declare |
| `unique` | DDL level | Adapter-dependent |
| `foreign_key` | DDL level | Requires `to` and `to_columns` |
| `check` | DDL level | Custom SQL expression |
| `custom` | DDL level | Adapter-specific raw SQL |

```yaml
- name: status
  data_type: varchar
  constraints:
    - type: check
      expression: "status in ('pending', 'shipped', 'delivered', 'cancelled')"
```

### Constraints vs tests

| | Constraints | Tests |
|---|---|---|
| Enforced by | Warehouse DDL | dbt test runner |
| Timing | At `dbt run` | At `dbt test` |
| Failure | Build fails | Test fails (separate step) |

Constraints for **structural** guarantees the warehouse enforces cheaply; tests
for **business-logic** assertions.

### The public interface pattern

Contracts pair with model access (Session 7.3):

```yaml
models:
  - name: fct_orders
    access: public
    config:
      contract:
        enforced: true
```

**A `public` model without a contract is a promise with no mechanism behind it.**
Together they form a genuine API boundary.

### Adopting contracts on an existing project

1. Identify public-facing models — those feeding BI, APIs, external teams.
2. Generate the YAML with `dbt-labs/codegen` to capture existing column types.
3. Set `contract.enforced: true` and run in CI — failures reveal undocumented
   columns and type mismatches.
4. Resolve discrepancies (usually `varchar` vs `text` style mismatches).
5. Expand coverage outward over time.

Start with `enforced: false` to document columns without breaking builds, then
flip to `true` once coverage is complete.

### Gotchas

- **Contracts are build-time, not query-time.** They do not replace tests.
- **Column order matters on some adapters** (notably Snowflake with `table`
  materialization) — contract order must match the SELECT.
- **Contracts are not inherited.** Every model that needs stability declares its
  own.
- **`data_type` is not translated.** Use what your warehouse understands —
  `varchar` on Snowflake, `STRING` on BigQuery.
- **Contracted incremental models need `--full-refresh` after adding a column.**
  The contract applies to the full table schema, not just the increment.

---

## Session 7.2 — Model Versioning

**Covered on:** 2026-06-27, 08-10, 08-18 *(3 notes)*

### Why it matters

When a widely-used model needs a breaking change, you face a bad choice: break
everything, or keep dead columns forever. Versioning (dbt 1.5+) is the third
option — publish v2 alongside v1, let consumers migrate on their own schedule,
deprecate v1 when it's safe.

### Mechanics

```yaml
models:
  - name: fct_orders
    latest_version: 2
    versions:
      - v: 1
        deprecation_date: "2026-10-01"
      - v: 2
```

```
models/
  fct_orders_v1.sql
  fct_orders_v2.sql
```

Or point at differently-named files:

```yaml
versions:
  - v: 1
    defined_in: fct_orders        # models/fct_orders.sql
  - v: 2
    defined_in: fct_orders_v2
```

### Referencing

```sql
select * from {{ ref('fct_orders', version=1) }}   -- pinned during migration
select * from {{ ref('fct_orders') }}              -- resolves to latest_version
```

Models still pinned to a version with a `deprecation_date` emit warnings during
runs.

### Column-level versioning

```yaml
versions:
  - v: 1
    columns:
      - include: all
        exclude: [amount_usd]     # v1 has total_cents instead
  - v: 2
    columns:
      - include: all
```

dbt validates each version exposes exactly the declared columns at parse time.

### Selection

```bash
dbt run --select fct_orders.v2
dbt run --select fct_orders.latest
dbt run --select fct_orders          # all versions
```

### The deprecation workflow

1. Ship v2 alongside v1, no `deprecation_date` yet.
2. Notify consumers — the lineage graph shows everything referencing v1.
3. Set `deprecation_date` on v1; dbt warns on every run that still uses it.
4. After the date, delete v1. Unmigrated consumers get a hard compile error —
   the intended forcing function.

**Versioning requires a contract on at least the latest version.**

---

## Session 7.3 — Access Levels and Groups

**Covered on:** 2026-06-25, 07-08, 07-22, 08-09, 08-14 *(5 notes)*

### Why it matters

Answers the question: *which models are internal implementation details, and
which are stable interfaces other teams can depend on?*

| Level | Who can `ref()` it |
|---|---|
| `private` | Only models in the same group |
| `protected` | Any model in the same project **(default)** |
| `public` | Any model in any project (cross-project refs) |

### Mechanics

```yaml
# models/finance/schema.yml
groups:
  - name: finance
    owner:
      name: Finance Analytics Team
      email: analytics@finance.example.com

models:
  - name: stg_invoices
    group: finance
    config:
      access: private            # internal staging — off-limits to other teams

  - name: int_invoice_aggregates
    group: finance
    config:
      access: private

  - name: fct_revenue
    group: finance
    config:
      access: public             # stable interface
      contract:
        enforced: true
```

A violation errors at **parse time**:

```
Error: Model 'marketing.fct_campaigns' attempted to reference 'finance.stg_invoices',
which is private to the 'finance' group.
```

```bash
dbt ls --select "config.access:public"     # what does this project expose?
```

### Practices

- **Default staging models to `private`.** Other teams consume marts, not
  transformation internals.
- **Every `public` model gets a contract.** No exceptions.
- **Groups mirror org structure** — one per team or domain, making ownership
  searchable in the docs site.
- **Treat `public` promotion like an API release.** Once other projects depend
  on it, schema changes are breaking changes: version, don't mutate.

---

## Session 7.4 — dbt Mesh: Multi-Project Architecture

**Covered on:** 2026-06-25, 07-16, 08-12 *(3 notes)*

### Why it matters

A single repo with 500+ models becomes a bottleneck: long CI runs, contributors
stepping on each other, no ownership boundaries. Mesh (dbt Core 1.6+ / dbt
Cloud) splits it into independently deployable projects that can still reference
each other. Microservices for the data platform.

### The three pieces

**1. Public models with contracts** (Sessions 7.1, 7.3) — the API surface.

**2. Cross-project `ref()`** — two arguments, project then model:

```sql
-- in the finance project, referencing the orders project
select
    o.order_id,
    o.order_total,
    c.customer_name
from {{ ref('orders', 'fct_orders') }} o
join {{ ref('customers', 'dim_customers') }} c
    on o.customer_id = c.customer_id
```

**3. `dependencies.yml`** at the root of the consuming project:

```yaml
projects:
  - name: orders
  - name: customers

packages:
  - package: dbt-labs/dbt_utils
    version: 1.3.0
```

### How resolution works

In the **dbt platform**, the metadata service knows each project's latest
compiled state; `ref('orders', 'fct_orders')` resolves to the actual warehouse relation
from the orders project's last successful run — no upstream recompilation.

In **dbt Core**, you build and export the upstream manifest, then reference it
from the downstream project.

### Practices

- Keep public models in **marts** only. Staging and intermediate stay
  `protected`.
- **Version public models** before breaking changes.
- **Own the interface, not the implementation** — upstream teams refactor
  internals freely as long as the contract holds.

---

## Session 7.5 — Exposures

**Covered on:** 15 notes, 2026-06-18 through 2026-08-20

### Why it matters

Without exposures, the lineage graph ends at your final model. Exposures declare
what *consumes* your models — dashboards, ML pipelines, apps, reverse-ETL — so
you can trace raw source → end user, and answer "what does this model feed?"
during an incident.

### Mechanics

```yaml
# models/finance/_finance__exposures.yml
exposures:
  - name: executive_revenue_dashboard
    label: "Executive Revenue Dashboard"
    type: dashboard
    maturity: high
    url: https://bi.company.com/dashboards/42
    description: >
      Weekly revenue KPIs used by the CFO and VPs of Sales and Finance.
      Refreshed nightly via dbt platform job #88.
    depends_on:
      - ref('fct_revenue')
      - ref('fct_orders')
      - ref('dim_customers')
    owner:
      name: Finance Analytics Team
      email: analytics@example.com
    tags: ['finance', 'executive']
```

Exposures can depend on both `ref()` models and `source()` tables.

| Type | Use case |
|---|---|
| `dashboard` | Looker, Tableau, Metabase, Power BI |
| `notebook` | Jupyter, Databricks, Observable |
| `analysis` | Ad-hoc SQL run regularly |
| `ml` | ML models or feature pipelines |
| `application` | Product features querying the warehouse |

`maturity` (`low` / `medium` / `high`) is metadata only — dbt enforces nothing —
but it communicates risk, and the docs site renders it distinctly.

### Selection

```bash
# everything feeding one dashboard
dbt build --select +exposure:weekly_revenue_dashboard

# targeted CI for a critical exposure
dbt build --select +exposure:weekly_revenue_dashboard --defer --state prod-manifest/

# all models feeding any exposure
dbt ls --select +exposure:*

# audit the finance data surface
dbt ls --select tag:finance,resource_type:exposure
```

### Practices

- **One exposure file per domain.**
- **Declare the most critical consumers first.** Even one exposure per
  high-stakes dashboard pays for itself during incident triage.
- **Keep URLs current** — a stale URL is worse than none; it erodes trust.
- **Always set `owner.email`** so on-call knows who to page.
- **Review exposures in refactoring PRs.** Before renaming a heavily consumed
  model, run `dbt ls --select +exposure:*`.
- The trio **`access: public` + `contract: enforced` + an exposure** is the
  signal that a model is load-bearing infrastructure.

---

# Part VIII — Documentation and Semantics

*Two layers of meaning on top of the models: what a column means, and what a metric means.*

---

## Session 8.1 — Documentation and the Docs Site

**Covered on:** 2026-06-24, 07-11, 08-08, 08-14 *(4 notes)*

### The three layers

1. **Inline YAML descriptions** — one-liners on models and columns.
2. **Doc blocks** — long-form Markdown in `.md` files, referenced by name.
3. **`dbt docs generate` + `serve`** — a static site with lineage.

### Inline

```yaml
models:
  - name: fct_orders
    description: "One row per order. Grain: order_id."
    columns:
      - name: order_id
        description: "Surrogate key — SHA256 of (source_system, source_order_id)."
```

### Doc blocks

```markdown
<!-- models/marts/docs.md -->
{% docs fct_orders %}
The `fct_orders` model is the central fact table for the orders domain.

**Grain:** one row per order (`order_id`).

**Important caveats:**
- Cancelled orders are included. Filter `status != 'cancelled'` for revenue.
- `total_amount` is USD regardless of originating currency; conversion uses
  the daily rate at order creation time.

**Refresh cadence:** hourly via the `orders` dbt job.
{% enddocs %}

{% docs order_status %}
Fulfillment lifecycle status.

| Value | Meaning |
|---|---|
| `pending` | Payment captured, not yet picked |
| `shipped` | Left the warehouse |
| `delivered` | Confirmed by carrier |
| `cancelled` | Voided before shipment |
{% enddocs %}
```

```yaml
models:
  - name: fct_orders
    description: "{{ doc('fct_orders') }}"
    columns:
      - name: status
        description: "{{ doc('order_status') }}"
```

One doc block can be referenced from every model sharing that vocabulary —
define the term once.

### Generating

```bash
dbt docs generate    # compiles docs + writes catalog.json (introspects warehouse)
dbt docs serve       # http://localhost:8080
```

The site gives you a clickable DAG, column-level metadata from `catalog.json`,
rendered Markdown, and test coverage per column.

In the dbt platform, enable **"Generate docs on run"** — the site updates after
every successful job.

### Where docs go next: Catalog and Docs v2

The static `dbt docs` site has a hard ceiling: it loads the whole manifest into
the browser, so past a few thousand models it stops being usable. Two things
replace it:

- **Catalog** (formerly dbt Explorer) — the platform's metadata explorer, with
  search, freshness and test health, column-level tags, and column-level lineage
  on Fusion. Session 10.1.
- **dbt Docs v2** — the next-generation local catalog, built on a binary index
  rather than a single JSON blob, so it scales to arbitrary project size. It
  carries Semantic Layer metadata and exposes a REST API at `/api/v1/`.
  Column-level lineage requires Fusion.

The authoring practice below does not change — descriptions, doc blocks, and
`persist_docs` feed all three surfaces. What changes is where people read them.

### Practices

- **Write for the consumer, not the author.** Describe what a column *means* and
  when to filter it, not how it was computed.
- **Doc blocks beat inline** for anything shared or longer than a sentence.
- **Require descriptions on public models.**
- Commit `manifest.json` / `catalog.json` as CI artifacts so you can diff doc
  coverage between branches.
- **Enforce coverage mechanically**, not by review — `dbt-checkpoint` has hooks
  for "every model has a description" and "every column is documented"
  (Session 4.4).

---

## Session 8.2 — The Semantic Layer and MetricFlow

**Covered on:** 2026-06-16, 06-21, 06-28, 07-03, 07-15, 07-19, 07-23, 07-29, 08-01, 08-08, 08-19 *(11 notes)*

### Why it matters

Without a semantic layer, "revenue" means one thing in Looker, something else in
a notebook, and a third thing in an executive spreadsheet. The Semantic Layer
(built on **MetricFlow**) makes one definition the truth for every tool.

It is the same shift dbt made for models, applied one level up — to the
aggregation layer.

### Two specifications

The Semantic Layer YAML changed substantially in 2026. Both forms parse; new
work should use the second.

| | **Classic spec** | **Embedded spec (1.12+)** |
|---|---|---|
| Where | A separate `semantic_models:` block | Inside the model's own `models:` entry |
| Column metadata | Re-declared in `entities:` / `dimensions:` | Attached to the `columns:` you already document |
| Aggregations | `measures:` | `metrics:` with `type: simple` |
| Nesting | Deep | Noticeably flatter |

The classic form is documented first because it is what you will meet in
existing projects and in most writing about MetricFlow.

### Semantic models — the classic spec

A semantic model wraps a dbt model and declares its entities, dimensions, and
measures:

```yaml
# models/marts/semantic_models/orders.yml
semantic_models:
  - name: orders
    model: ref('fct_orders')
    description: "Order-level facts"

    entities:
      - name: order
        type: primary
        expr: order_id
      - name: customer
        type: foreign
        expr: customer_id

    dimensions:
      - name: order_date
        type: time
        type_params:
          time_granularity: day
      - name: status
        type: categorical

    measures:
      - name: order_count
        agg: count
        expr: order_id
      - name: revenue
        agg: sum
        expr: order_total
```

### The embedded spec (1.12+)

The redesign's insight: you are already documenting columns in
`schema.yml` (Session 8.1). Semantic metadata belongs on those columns rather
than in a parallel file that drifts out of sync.

```yaml
# models/marts/_marts__models.yml
models:
  - name: fct_orders
    description: "One row per order."
    semantic_model:
      enabled: true
    agg_time_dimension: ordered_at

    columns:
      - name: order_id
        description: "Primary key."
        entity:
          type: primary
          name: order

      - name: customer_id
        entity:
          type: foreign
          name: customer

      - name: ordered_at
        granularity: day
        dimension:
          type: time

      - name: status
        dimension:
          type: categorical

    metrics:
      - name: order_count
        description: "Count of orders."
        type: simple
        label: Orders
        agg: count
        expr: order_id

      - name: revenue
        description: "Sum of order totals."
        type: simple
        label: Revenue
        agg: sum
        expr: order_total
```

Three things to notice: the entity and dimension declarations sit on the columns
they describe; `measures:` became `metrics:` with `type: simple`, unifying what
used to be two concepts; and the model's description is written once.

Derived, ratio, and cumulative metrics are declared exactly as in the classic
spec — the change is to the *semantic model*, not to the metric type system.

> Avoid double underscores (`__`) in semantic model names — they collide with
> MetricFlow's own `entity__dimension` naming convention.

### Metrics

```yaml
metrics:
  - name: monthly_revenue
    type: simple
    type_params:
      measure: revenue
    filter: |
      {{ Dimension('orders__status') }} = 'delivered'

  - name: average_order_value
    type: ratio
    type_params:
      numerator: revenue
      denominator: order_count

  - name: revenue_growth_mom
    type: derived
    type_params:
      expr: (revenue - revenue_prev_month) / revenue_prev_month
      metrics:
        - name: revenue
        - name: revenue
          offset_window: 1 month
          alias: revenue_prev_month

  - name: cumulative_revenue_ytd
    type: cumulative
    type_params:
      measure: revenue
      window: unbounded
      grain_to_date: year
```

| Type | Use case |
|------|----------|
| `simple` | Single measure, optional filter |
| `ratio` | Numerator / denominator measures |
| `derived` | Expression over other metrics (growth, margin) |
| `cumulative` | Running total over a window (YTD, rolling 30-day) |

### Querying

```bash
mf query --metrics monthly_revenue \
         --group-by metric_time__month,status \
         --start-time 2026-01-01 --end-time 2026-12-31

mf query --metrics monthly_revenue --group-by metric_time__month --explain
mf validate-configs
mf list metrics
```

**`--explain` is the essential development flag** — it prints the exact SQL
MetricFlow will send, so you verify joins and aggregations before production.

Saved queries pre-define common combinations:

```yaml
saved_queries:
  - name: monthly_revenue_by_region
    query_params:
      metrics: [revenue, order_count]
      group_by: [metric_time__month, customer__region]
```

Python SDK / JDBC / ADBC endpoints let Tableau, Looker, Hex, and Mode query
metrics natively.

### Practices

- **One semantic model per grain.** Don't mix order-level and customer-level
  facts — MetricFlow needs a consistent grain to build joins.
- **Declare `entities` for all join keys** — that's how MetricFlow joins across
  semantic models.
- **Declare `time_granularity` at the lowest available grain** (`day`);
  roll-up to week/month/quarter/year is automatic.
- **Keep filters in metric definitions, not upstream models.** A metric filter
  is explicit and auditable; pre-filtering hides business logic.
- **The hosted Semantic Layer API requires the dbt platform.** dbt Core users
  get `mf query` locally but not the BI integrations. Semantic Layer querying is
  GA inside Insights (Session 10.1), so a platform team can explore metrics
  without a BI tool at all.
- **Watch GraphQL query complexity.** Semantic Layer GraphQL queries over the
  200,000 complexity limit now *error* rather than warn. The fix is fewer
  fields, pagination, narrower filters, or splitting the query — worth knowing
  before a dashboard breaks in production.
- **New projects should use the embedded spec.** Migrating an existing
  `semantic_models:` block is mechanical but not automatic; do it when you next
  touch the model, not as a separate project.

---

# Part IX — Running dbt

*Selecting what to build, building it in the right order, and not building what you do not have to.*

---

## Session 9.1 — Node Selection and Graph Operators

**Covered on:** 2026-06-19, 06-26, 07-04, 07-12, 07-15, 07-20, 07-24, 07-29, 08-02, 08-07, 08-13, 08-18 *(12 notes)*

### Why it matters

Selection syntax is what turns dbt from a "run everything" tool into a surgical
instrument. It is the foundation of Slim CI and the biggest lever on both
warehouse cost and feedback-loop time.

### Graph operators — memorise this first

```bash
dbt run --select +my_model      # my_model and everything UPSTREAM
dbt run --select my_model+      # my_model and everything DOWNSTREAM
dbt run --select +my_model+     # the full graph around my_model
```

Limit traversal depth with a number:

```bash
dbt run --select 2+my_model     # my_model + 2 levels of parents
dbt run --select my_model+1     # my_model + immediate children only
```

`@my_model` — the model, all its ancestors, **and** those ancestors' other
descendants. Useful for the full test surface around a node.

### Selection methods

| Method | Example | Selects |
|---|---|---|
| `tag:` | `tag:pii` | Models with that tag |
| `source:` | `source:raw.orders` | A source node |
| `path:` | `path:models/staging` | Models under a directory |
| `package:` | `package:dbt_utils` | Nodes from a package |
| `config:` | `config.materialized:incremental` | Models with that config |
| `fqn:` | `fqn:my_project.staging.stg_orders` | Exact node name |
| `exposure:` | `exposure:weekly_revenue_report` | Ancestors of that exposure |
| `metric:` | `metric:revenue` | Ancestors of that metric |
| `state:` | `state:modified` | Nodes changed vs a prior manifest |
| `result:` | `result:fail` | Nodes by last run status |
| `test_type:` | `test_type:unit` | Unit vs generic vs singular tests |

### Unions, intersections, exclusions

```bash
# Union (space): staging OR tagged core
dbt run --select path:models/staging tag:core

# Intersection (comma): staging AND tagged core
dbt run --select "path:models/staging,tag:core"

# Exclusion
dbt run --select tag:finance --exclude fqn:my_project.finance.finance_archive
dbt run --select marts/ --exclude tag:experimental
```

### Resource types

```bash
dbt ls --resource-type test
dbt ls --resource-type exposure
dbt build --resource-type seed --resource-type model
dbt build --exclude resource_type:seed resource_type:snapshot
```

### YAML selectors — name your complex selections

```yaml
# selectors.yml
selectors:
  - name: nightly_finance
    description: "Finance models and their upstream sources"
    definition:
      union:
        - method: tag
          value: finance
        - method: tag
          value: finance_source
      exclude:
        - method: config
          value:
            materialized: ephemeral

  - name: ci_modified
    definition:
      method: state
      value: modified
      parents: true
```

```bash
dbt build --selector nightly_finance
```

### Practical patterns

```bash
# rebuild one model and re-run all its tests
dbt build --select +stg_orders+

# what breaks if this source changes? (dry run)
dbt ls --select source:raw.events+

# re-run only what failed last time
dbt test --select result:fail --state ./target

# find every incremental model (for an audit or bulk re-run)
dbt ls --select config.materialized:incremental

# preview a selector without running anything
dbt ls --select state:modified+ --state ./prod-manifest
```

### Gotchas

- **`dbt ls` is free** — no SQL runs. Always validate a new selector with `ls`
  before a costly `build`.
- **Always use `state:modified+` in CI, not `state:modified`.** You need
  downstream tests to catch breakage.
- **Never `dbt run --full-refresh` without `--select` in production** — it
  rebuilds every incremental table from scratch.

---

## Session 9.2 — Tags

**Covered on:** 2026-07-30, 08-16 *(2 notes)*

### Mechanics

```yaml
# dbt_project.yml — directory-wide
models:
  my_project:
    staging:
      +tags: ['staging', 'hourly']
    marts:
      finance:
        +tags: ['finance', 'daily']
```

```sql
{{ config(tags=['finance', 'critical', 'daily']) }}
```

```yaml
# tests carry tags too
- not_null:
    config:
      tags: ['p0-test']
```

```bash
dbt run  --select tag:daily
dbt run  --select tag:finance,tag:critical    # intersection
dbt test --select tag:p0-test
dbt run  --select +tag:finance                # tag + upstream
dbt ls   --select tag:critical --output name
```

### Tagging strategies

| Dimension | Examples | Use case |
|---|---|---|
| **Frequency** | `hourly`, `daily`, `weekly` | Orchestrator schedules by cadence |
| **Domain** | `finance`, `marketing`, `ops` | Teams run their own slice |
| **Priority** | `critical`, `p0`, `p1` | Alerting and on-call escalation |
| **Stage** | `staging`, `intermediate`, `mart` | Partial rebuilds |
| **State** | `experimental`, `deprecated` | Governance |

### The orchestration payoff

```bash
# Airflow task for the hourly finance refresh
dbt run --select tag:finance,tag:hourly --target prod
```

Add a new model with `tags: ['finance', 'hourly']` and it slots into the right
job automatically. **Zero orchestration changes.**

Tags are free metadata. The cost of an unused tag is nothing; the cost of not
being able to selectively run 20% of your DAG for a 2am hotfix is very real.

---

## Session 9.3 — `dbt build`: The Command You Should Actually Use

**Covered on:** 2026-08-09 *(1 note; recommended throughout the CI and testing notes)*

### Why it matters

`dbt run` only executes models. The naive substitute —

```bash
dbt seed && dbt snapshot && dbt run && dbt test
```

— runs in four sequential phases. A test failure on `stg_orders` does **not**
stop `fct_revenue` from building on top of it. You discover the corruption after
it has already materialised into marts.

### What `dbt build` does differently

It interleaves execution with the DAG. For every node it visits, it runs the
node then immediately runs that node's tests before moving downstream:

```
Seed: raw_country_codes    ✓
  └─ Test: not_null(code)  ✓
Model: stg_orders          ✓
  ├─ Test: not_null(order_id)      ✓
  └─ Test: accepted_values(status) ✗  ← STOPS HERE
     Model: fct_revenue             (skipped — upstream test failed)
```

No corrupted marts. No silent propagation of bad data.

Seeds → snapshots → models → tests, all in one DAG pass.

### Usage

All selectors carry over unchanged:

```bash
dbt build --select finance.*+
dbt build --select +fct_orders
dbt build --select state:modified+ --defer --state ./prod-artifacts/
dbt build --fail-fast                 # abort the whole run on first failure
dbt build --exclude resource_type:seed resource_type:snapshot
```

By default a test failure skips only that node's descendants; sibling branches
continue. `--fail-fast` aborts everything — better for local iteration.

### When to use what

| Command | Use when |
|---|---|
| `dbt run` | Iterating on models during development |
| `dbt test` | Running tests without re-materializing |
| `dbt build` | **CI/CD and production — always** |

### The golden production pattern

```bash
dbt build \
  --select state:modified+ \
  --defer \
  --state ./artifacts/prod \
  --target prod
```

Builds only modified models and descendants, borrows unmodified upstreams from
production, tests inline, halts on failure.

---

## Session 9.4 — `defer` and `--state`

**Covered on:** 2026-06-26, 08-07, 08-12 *(3 notes)*

### Why it matters

You're tweaking `fct_orders`, which has 15 upstream models. Without `defer`, a
local run rebuilds all 15 in your dev schema first — slow, expensive, pointless.
With `defer`, dbt resolves upstream `ref()` calls to the **production tables**.
You build only what you changed.

The notes call this "the single biggest productivity multiplier for developers
on large dbt projects."

### Mechanics

```bash
# 1. get production artifacts into a local directory
mkdir -p ./prod-artifacts
#    (manifest.json + run_results.json)

# 2. run, deferring upstreams to prod
dbt run --select fct_orders --defer --state ./prod-artifacts
```

dbt compares your manifest against production's. Any upstream that exists in
prod and hasn't changed is skipped — your dev schema borrows from prod
transparently.

### `--favor-state`

By default a locally-modified upstream gets rebuilt. `--favor-state` forces the
production version even for changed models — useful to isolate your change from
a colleague's upstream experiment:

```bash
dbt run --select fct_orders --defer --state ./prod-artifacts --favor-state
```

### Previewing

```bash
dbt ls --select fct_orders+ --defer --state ./prod-artifacts --output json | jq '.[]'
```

### Getting the artifacts

| Platform | How |
|---|---|
| dbt platform | Download from the latest successful job via API or UI |
| dbt Core + CI | Upload as CI artifacts; download in dev scripts |
| Shared storage | Copy `./target/` to S3/GCS after each prod run |

### Rules

- Requires **both** `manifest.json` and `run_results.json` in `--state`.
- Only defers nodes that **exist** in the production state. New models are
  always built locally.
- Works with `run`, `test`, `build`, and `compile`.
- **`defer` only affects upstreams.** Your dev target still controls where the
  model you're developing lands.

---

## Session 9.5 — `dbt clone`

**Covered on:** *Absent from the archive. Written for the 2026 update.*

### Why it matters

Session 9.4's `defer` solves "don't rebuild upstream models" by *pointing* at
production. That is cheap, but the pointer only exists inside dbt — a BI tool,
a notebook, or a colleague's SQL client sees nothing in your schema. And a
deferred incremental model in CI has no table to merge into, so it does a full
rebuild.

`dbt clone` solves both by creating real objects — using zero-copy clones where
the platform supports them, so it costs almost nothing.

### Mechanics

```bash
# clone everything from a production manifest into the target schema
dbt clone --state path/to/prod-artifacts

# just one model and its ancestors
dbt clone --select "+fct_orders" --state path/to/prod-artifacts

# recreate objects that already exist
dbt clone --state path/to/prod-artifacts --full-refresh

# it parallelises well — clones are metadata operations
dbt clone --state path/to/prod-artifacts --threads 50
```

| Platform | Implementation |
|---|---|
| Snowflake, Databricks, BigQuery | Zero-copy clone — metadata only, no data copied |
| Everything else | A pointer view: `create view x as select * from prod.x` |

### `clone` vs `defer`

| | `--defer` | `dbt clone` |
|---|---|---|
| Creates warehouse objects | ❌ | ✅ |
| Compute cost | None | Near-zero on zero-copy platforms |
| Visible to BI tools / SQL clients | ❌ | ✅ |
| Incremental models in CI | Full rebuild | Merge into the clone — realistic and fast |
| Setup | `--state` | `--state` |

They are complements, not alternatives. `defer` is the default for interactive
development; `clone` is for when you need the objects to actually exist.

### The two real use cases

**1. Incremental models in CI.** Without a clone, a Slim CI run of an
incremental model either full-refreshes (slow, expensive, and *not* what
production does) or fails. Clone first, and the CI run exercises the real merge
path:

```yaml
- run: dbt clone --state ./prod-artifacts --select "state:modified+"
- run: dbt build --select "state:modified+" --defer --state ./prod-artifacts
```

**2. Blue/green deployment.** Build into a staging schema, test it, and swap
only if everything passes:

```bash
dbt clone --state ./prod-artifacts --target staging
dbt build --target staging
# tests green → promote the staging schema
```

This gives you an atomic-ish release: production is never in a half-built state.

### Gotchas

- **Clones drift the moment production moves.** A clone is a point-in-time
  snapshot, not a live mirror. Re-clone rather than reasoning about staleness.
- **It still needs a production manifest** — same plumbing as Session 9.4, and
  the same failure mode when the artifact is stale.
- **On non-zero-copy platforms the "clone" is a view.** Writing to it fails.
  Know which behaviour your warehouse gives you before designing around it.
- **Clean up.** Clones are cheap, not free — cloned schemas from months of CI
  runs accumulate. Drop them on PR close.
- **Permissions are not always cloned.** Snowflake needs `copy_grants`
  (Session 6.5) for privileges to survive.

### Checklist

- [ ] CI clones before building, if the project has incremental models
- [ ] Cloned CI schemas are dropped when the PR closes
- [ ] The team knows whether their platform does zero-copy or views

---

## Session 9.6 — Sample Mode and `--empty`: Cheap Dry Runs

**Covered on:** *Absent from the archive. Written for the 2026 update.*

### Why it matters

Most development runs answer a question that does not need all the data: *does
this compile, and does the schema come out right?* Building 400M rows to find
out you misspelled a column is the most common avoidable cost in a dbt project.

Two flags shrink that loop.

### `--empty`: schema-only dry run

```bash
dbt build --select "+fct_orders" --empty
```

dbt wraps every `ref()` and `source()` in a zero-row limit, then executes the
model SQL for real against the warehouse. You get:

- genuine SQL validation (the warehouse parses and plans it)
- correct output schema and data types
- DDL that proves the model can be created
- essentially zero scan cost

This is the right flag for CI on a brand-new model, and for the "does my
refactor still compile against production types?" question.

To force a `ref()` to render normally despite `--empty` — needed when a hook
must address the real relation — use `.render()`:

```sql
{{ config(
    pre_hook = "alter external table {{ source('sys', 'customers').render() }} refresh"
) }}
```

### `--sample`: a real slice of data (1.10+)

`--empty` proves the model builds. It cannot tell you whether the join
duplicates rows or the aggregation is wrong, because there is nothing in it.
Sample mode fills that gap by filtering to a **time window** instead of
truncating to zero:

```bash
# trailing window
dbt run --select "+fct_orders" --sample="3 days"

# a specific historical range
dbt build --select "+fct_orders" --sample="2026-01-27 to 2026-01-30"
```

Sampling is time-based, so it relies on the same `event_time` config that
microbatch uses (Session 3.3):

```yaml
models:
  - name: stg_orders
    config:
      event_time: ordered_at
```

Any `ref()` whose model declares `event_time` is filtered to the window.
Anything without one is read in full — usually correct for dimensions, and
expensive for an un-annotated fact table.

### Choosing between them

| Question | Flag |
|---|---|
| Does it compile and what's the schema? | `--empty` |
| Is the row count / join fan-out plausible? | `--sample` |
| Is the output correct for known inputs? | Unit tests (Session 4.2) |
| Is the real data correct? | Data tests (Session 4.1) |

These are layers, not substitutes. `--empty` and `--sample` are about *speed of
iteration*; the tests are about correctness.

### Gotchas

- **Sample mode needs `event_time` to do anything useful.** Without it you have
  paid for the flag and got a full build.
- **A sampled build is not a valid production table.** Both flags write to your
  dev schema. Never point a dashboard at the result.
- **`--empty` still executes against the warehouse.** It is not `dbt compile` —
  it needs a live connection and creates real (empty) objects.
- **Incremental models under `--empty`** build an empty table; the next real
  run merges into it. Full-refresh before trusting the numbers.

### Checklist

- [ ] `event_time` declared on event/fact models
- [ ] `--empty` used in CI for newly added models
- [ ] The team's default dev loop uses `--sample` rather than full builds

---

## Session 9.7 — Slim CI

**Covered on:** 2026-06-25, 06-30, 07-03, 07-16, 08-05, 08-20 *(6 notes)*

### Why it matters

The single highest-leverage dbt CI optimisation. A project that takes 40 minutes
to build fully can have a 2-minute CI loop for small PRs — fast enough that
engineers actually act on the feedback.

### The mechanism

dbt diffs the current branch's compiled state against the last successful
production `manifest.json`. Identical models are skipped entirely.

```bash
dbt build --select "state:modified+ state:new" --defer --state ./prod-state
```

- `state:modified` — compiled SQL differs from the reference
- `+` — also select downstream dependents
- `state:new` — models that didn't exist in the reference (**not** matched by
  `state:modified` alone)
- `--defer` — unselected upstreams resolve to production
- `--state` — directory holding the reference manifest

### State selector variants

| Selector | Matches |
|---|---|
| `state:modified` | Changed compiled SQL |
| `state:modified.body` | SQL body only (ignores config/description) |
| `state:modified.configs` | Config-level changes only |
| `state:new` | Didn't exist in the reference state |
| `state:modified+` | Changed models and all descendants |

### What counts as "modified"

- Model SQL (content hash)
- Schema/config changes in YAML (new tests, description, materialization, tags, grants)
- Upstream source definition changes

**It does not automatically detect changes to Jinja macros a model calls.**
Widen the selection or explicitly include macro-dependent models.

Two flags are worth knowing here:

```yaml
# dbt_project.yml
flags:
  state_modified_compare_more_unrendered_values: true
```

This (1.9+) is the fix for the classic false positive where a dev-vs-prod config
difference — a table in prod, a view in dev — marks the entire project as
modified. Turn it on; see Session 6.6.

On Fusion, `compare_unrendered_code` goes further: a model is only considered
modified when *both* the Jinja template and the rendered SQL changed, so a
cosmetic macro edit stops cascading a rebuild through the whole DAG. And
`state:modified` now detects UDF signature changes (Session 5.5).

### Getting the production manifest

```bash
# dbt platform API
curl -H "Authorization: Token $DBT_CLOUD_TOKEN" \
  "https://cloud.getdbt.com/api/v2/accounts/$ACCOUNT_ID/jobs/$JOB_ID/artifacts/manifest.json" \
  -o prod-state/manifest.json

# dbt Core: upload after prod, download in CI
aws s3 cp target/manifest.json s3://my-bucket/dbt/prod/manifest.json
aws s3 cp s3://my-bucket/dbt/prod/manifest.json prod-state/manifest.json
```

### Full GitHub Actions example

```yaml
# .github/workflows/dbt-ci.yml
name: dbt Slim CI

on:
  pull_request:
    paths:
      - 'models/**'
      - 'tests/**'
      - 'macros/**'
      - 'dbt_project.yml'

jobs:
  slim-ci:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Install dbt
        run: pip install dbt-snowflake==1.8.0

      - name: Download prod manifest
        run: |
          mkdir prod-state
          aws s3 cp s3://my-bucket/dbt/prod/manifest.json prod-state/manifest.json
        env:
          AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
          AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}

      - name: dbt deps
        run: dbt deps

      - name: dbt Slim CI build
        run: |
          dbt build \
            --select "state:modified+ state:new" \
            --defer \
            --state prod-state \
            --target ci
        env:
          DBT_SNOWFLAKE_ACCOUNT: ${{ secrets.SNOWFLAKE_ACCOUNT }}
          DBT_SNOWFLAKE_USER: ${{ secrets.SNOWFLAKE_USER }}
          DBT_SNOWFLAKE_PASSWORD: ${{ secrets.SNOWFLAKE_PASSWORD }}
```

In the **dbt platform** this is built in: set "Defer to a production job" in the
CI job settings and you get a per-PR schema (`dbt_cloud_pr_123_456`) auto-dropped
after merge. Advanced CI (Session 9.8) layers a data diff on top of it.

### Practices

- **`dbt build`, not `dbt run && dbt test`.**
- **Include `state:new`** alongside `state:modified+`.
- **Use a dedicated CI target** writing to `dbt_ci_<pr_number>`.
- **Gate the workflow on path changes** — no dbt CI for a README edit.
- **Clean up CI schemas post-merge** to prevent warehouse sprawl.
- **Upload the manifest on every successful prod run** or your baseline rots.

---

## Session 9.8 — Advanced CI: Comparing Data, Not Just Code

**Covered on:** *Absent from the archive. Written for the 2026 update.*

### Why it matters

Slim CI (Session 9.7) answers *did the changed models build and pass their
tests?* It cannot answer the question reviewers actually care about: **what did
this PR do to the numbers?**

A refactor that changes a join from `left` to `inner` builds fine, passes every
test, and quietly drops 4% of orders. Advanced CI catches exactly that class of
change by diffing the CI output against production data.

### What it does

On each PR commit, the CI job builds the modified models and then compares them
to the current production tables, reporting:

- rows added and removed
- columns added and removed
- primary-key changes
- a sample of the differing records (up to 100 per model)

Results land in two places: the **Compare** tab of the job run, and a summary
comment on the pull request itself — so a reviewer sees the data impact without
leaving GitHub.

### Enabling it

It is a dbt platform feature, not a dbt Core one:

| Requirement | |
|---|---|
| Plan | Enterprise or Enterprise+ |
| Setting | Advanced CI enabled at account level |
| Job config | **dbt compare** enabled on the CI job |
| Platforms | BigQuery, Databricks, Postgres, Redshift, Snowflake |
| Connection | CI and production must share the same database host |

That last row is the most common setup failure: if CI runs against a separate
RDS instance from production, deferral queries cannot cross the boundary and
comparison silently fails.

### Tuning it with `event_time`

Slim CI usually builds only a recent slice of data, while production holds
everything. Compared naively, that produces thousands of phantom "deleted rows."
Declaring `event_time` (the same config as Sessions 3.3 and 9.6) tells dbt to
compare only the overlapping window:

```yaml
models:
  - name: fct_orders
    config:
      event_time: ordered_at
```

Without this, Advanced CI on a time-sliced CI build is unreadable.

### The CI ladder

Each rung answers a question the one below it cannot:

| Rung | Question | Cost |
|---|---|---|
| Lint (Session 4.4) | Is the code consistent? | Seconds, no warehouse |
| `--empty` (Session 9.6) | Does it compile? | Near-zero |
| Slim CI (Session 9.7) | Does it build and pass tests? | Modified subgraph |
| Advanced CI | Did the numbers move? | Modified subgraph + comparison |
| State-aware (Session 9.9) | Does it need building at all? | Deployment-time |

### Gotchas

- **Cached comparison data is retained up to 30 days** in the account's cloud
  region, and is visible to every user in the account. If CI credentials can see
  PII, so can everyone reading a PR.
- **Dynamic data masking is not applied to cached samples.** Restrict CI
  credentials or use synthetic data.
- **A diff is not a failure.** Most PRs are *supposed* to change the numbers.
  Advanced CI is a review aid, not a gate — treat a surprising diff as a
  conversation starter.
- **Same-host requirement.** Separate CI and prod database hosts break it.

### Checklist

- [ ] `event_time` set on the large fact models CI touches
- [ ] CI and production on the same connection host
- [ ] Reviewers know the Compare comment exists and what it means
- [ ] CI credentials scoped so cached samples are not sensitive

---

## Session 9.9 — State-Aware Orchestration and dbt State

**Covered on:** *New capability, absent from the archive. Written for the 2026 update.*

### Why it matters

Every session so far assumes a schedule: `dbt build` runs hourly, or nightly,
and rebuilds everything in scope whether or not anything changed. That is the
default and it is wasteful — most runs rebuild models whose code is identical
and whose upstream data has not moved.

Session 9.7's `state:modified` gets partway there, but it is scoped to a single
invocation comparing against one manifest. **dbt State** keeps a persistent,
shared view of every model's code *and* data across every job in an
environment, and skips what genuinely does not need rebuilding.

Reported effect: roughly **10% cost reduction from enabling it**, and another
**~15%** from tuning the freshness configs below.

### The decision, in one line

> Rebuild if the model's code changed, or its upstream data changed, or its
> table is missing, or its last run failed its tests. Otherwise reuse.

### Prerequisites

| | |
|---|---|
| Plan | Enterprise / Enterprise+ with a Developer seat |
| Engine | Fusion environment (a plugin exists for dbt Core v1.7–1.12) |
| Environment | Deployment only — production or staging |
| Job type | **Deploy jobs only** — not CI, not merge jobs |
| Models | SQL only; Python models are not supported |

New deploy jobs in Fusion environments are state-aware by default. Existing jobs
need **"Enable Fusion cost optimization features"** switched on.

### Configuring freshness

Out of the box, dbt reads warehouse metadata to decide whether a source moved.
The `freshness.build_after` config lets you say "don't bother rebuilding this
more often than X":

```yaml
# models/marts/_marts__models.yml
models:
  - name: dim_customers
    config:
      freshness:
        build_after:
          count: 4
          period: hour        # minute | hour | day
          updates_on: all
```

Or project-wide with per-folder overrides:

```yaml
# dbt_project.yml
models:
  +freshness:
    build_after: {count: 4, period: hour, updates_on: all}

  jaffle_shop:
    marts:
      +freshness:
        build_after: {count: 1, period: hour, updates_on: all}
```

**`updates_on`** is the config that actually saves money:

| Value | Behaviour |
|---|---|
| `any` *(default)* | Rebuild as soon as *any* upstream has fresh data |
| `all` | Wait until *all* upstreams are fresh |

`all` is right for a mart fed by five sources that land at different times —
it builds once instead of five times. `any` is right for the one dashboard that
must reflect a change immediately.

Opt a model out entirely with `freshness: null`.

### Telling dbt when a source moved

```yaml
sources:
  - name: raw_orders
    tables:
      - name: orders
        config:
          freshness:
            warn_after: {count: 12, period: hour}
        loaded_at_field: _etl_loaded_at
```

For streaming, partial loads, or late-arriving data, `loaded_at_query` gives you
full control:

```yaml
      - name: events
        loaded_at_query: |
          select max(ingested_at)
          from {{ this }}
          where ingested_at >= current_timestamp - interval '3 days'
```

**Align this window with the model's lookback.** An incremental model with a
3-day lookback (Session 3.1) and a `loaded_at_query` that only looks at the last
hour will skip rebuilds it should have done.

### Debugging what it decided

```bash
dbt state explain                          # why each node was built or reused
dbt state explain --verbose -s fct_orders  # the full reasoning for one node
```

The run summary also shows a **Reused** tab listing every skipped node and why.
Read this the first few weeks — the surprises are informative.

### Recent controls

| Setting | Effect |
|---|---|
| `allow_clones` (profile-level) | Whether dbt State may clone tables |
| `compare_unrendered_code` | Rebuild only when both the Jinja template *and* the rendered SQL change — stops cosmetic macro edits cascading |

Views using `select *` are now reused rather than rebuilt; a non-`select *`
`ref()`/`source()` still forces a rebuild.

### Gotchas

- **It is not a substitute for tests.** "Nothing changed" is inferred from
  metadata; a silent upstream corruption that doesn't move the watermark will be
  reused, not caught.
- **Deploy jobs only.** Do not design a CI strategy around it — that is still
  Slim CI (Session 9.7).
- **`updates_on: any` on a wide mart** can rebuild more often than the schedule
  it replaced. Default to `all` for marts.
- **A misaligned `loaded_at_query` silently under-builds.** This is the failure
  mode to watch: no error, just stale data.
- **Python models are excluded** — they always rebuild.
- **It changes what "the nightly run" means.** Alerting that assumes every model
  is touched every night needs revisiting.

### Checklist

- [ ] `build_after` set at the folder level, overridden where SLAs differ
- [ ] `updates_on: all` on marts fed by multiple sources
- [ ] `loaded_at_field` or `loaded_at_query` on every source
- [ ] Freshness windows aligned with incremental lookbacks
- [ ] `dbt state explain` reviewed after the first week
- [ ] Monitoring updated for models that may legitimately not run

---

## Session 9.10 — CI/CD and Deployment Environments

**Covered on:** 2026-06-19, 07-25 *(2 notes)*

### The two-job model

1. **CI job** — every pull request; builds only changed models; runs all
   relevant tests.
2. **Production job** — scheduled; builds everything; updates docs; publishes
   the manifest.

### Environment layout

| Environment | Schema prefix | Trigger | Purpose |
|---|---|---|---|
| dev | `dev_<username>` | Manual | Individual development |
| ci | `ci_<pr_number>` | PR open/push | Pre-merge validation |
| staging | `staging` | Merge to main | Integration testing |
| production | (none) | Schedule | Live data for consumers |

```yaml
# profiles.yml
ci:
  target: ci
  outputs:
    ci:
      type: snowflake
      schema: "ci_{{ env_var('PR_NUMBER') }}"
```

Per-PR schemas prevent parallel CI runs from colliding, and cleanup is trivial:
drop `ci_*` on merge.

### The production job is more than `dbt run`

```bash
dbt source freshness          # fail fast if upstream data is stale
dbt build --target prod       # run + test in one DAG pass
dbt docs generate             # refresh the catalog
aws s3 cp ./target/manifest.json s3://my-bucket/dbt/prod/manifest.json
```

That last line is what makes tomorrow's Slim CI possible.

### Practices

- **`--fail-fast` in CI** — abort on first failure instead of drowning in errors.
- **Pin dbt and adapter versions** in `requirements.txt`. Patch releases change
  behaviour.
- **Alert on `source freshness` failures separately** from model failures — a
  stale source is an upstream problem, not a code problem.

---

## Session 9.11 — Artifacts: `manifest.json`, `run_results.json`, `catalog.json`

**Covered on:** 2026-06-27, 07-08, 07-11, 07-27, 08-08, 08-13 *(6 notes)*

### Why it matters

Every dbt invocation writes JSON artifacts to `target/`. They are the API
surface everything else builds on: Slim CI, the docs site, lineage tooling,
observability platforms, and the platform's Catalog (Session 10.1).

### The three artifacts

**`manifest.json`** — the complete compiled graph. Written by `compile`, `run`,
`build`, `test`. Contains every node with its compiled SQL, config, metadata,
column descriptions, and the full DAG as `depends_on.nodes`.

```bash
jq '.nodes["model.my_project.fct_orders"].compiled_code' target/manifest.json
```

**`run_results.json`** — execution results of the most recent invocation:
status, timing, messages.

```bash
jq '[.results[] | select(.status == "error") | {node: .unique_id, message: .message}]' \
   target/run_results.json
```

**`catalog.json`** — warehouse introspection from `dbt docs generate`. The
*actual* columns, types, and row counts in the warehouse — not what `schema.yml`
claims.

### Reading them in Python

```python
import json

with open("target/run_results.json") as f:
    results = json.load(f)

failures = [r for r in results["results"] if r["status"] in ("error", "fail")]
for f in failures:
    print(f["unique_id"], f["message"])
```

### Practices

- **Archive `manifest.json` from every production job.** This one file unlocks
  Slim CI, defer, drift detection, and cross-environment comparison.
- **Diff `catalog.json` between releases** to catch schema drift — unexpected
  column additions, type changes, drops.
- **Never commit `target/`.** Gitignore it; store artifacts externally.
- **On dbt Core v2, artifacts are also written as Parquet** alongside JSON —
  which means you can query a run's results directly with DuckDB instead of
  parsing JSON in Python:

  ```sql
  select node_id, status, execution_time
  from read_parquet('target/run_results.parquet')
  where status != 'success'
  order by execution_time desc;
  ```
- **Hybrid jobs** (Session 10.2) let an externally orchestrated run push its
  artifacts into the platform, so an Airflow shop still gets Catalog health and
  run history without changing schedulers.
- `dbt-artifacts`, `elementary`, and `re_data` consume these files to power
  observability dashboards with zero extra instrumentation.

---

# Part X — The dbt Platform

*Everything so far works in dbt Core from a terminal. This Part covers what the
commercial platform adds, what it renamed, and which parts of it you can
replicate yourself. Skip it entirely if you run dbt Core with your own
orchestrator — with the exception of Session 10.3, which works locally too.*

---

## Session 10.1 — Platform Orientation: Studio, Catalog, Insights, Canvas

**Covered on:** *Absent from the archive — listed in the original coverage gaps. Written for the 2026 update.*

### Why it matters

The archive's notes are entirely dbt Core. The platform is where most teams
larger than a few people actually run dbt, and in 2025–26 it renamed nearly
every surface, which makes older documentation actively misleading.

### The surfaces

**Studio IDE** — the browser development environment (formerly the Cloud IDE).
Git branching, file tree, compile/preview, lineage, and a command bar. It now
has search/replace, a command palette, a VS Code-style explorer, YAML validation
aligned to Fusion's JSON schema, and a status bar exposing deferral, dbt
version, and project status.

**Catalog** — the metadata and lineage explorer (formerly dbt Explorer). Model
and column details, column-level lineage on Fusion, column-level tags,
freshness and test health, and search across the project. This is the
production-grade replacement for the static `dbt docs` site (Session 8.1).

**Insights** — exploratory analysis. Run SQL against the warehouse, query the
Semantic Layer (Session 8.2) without a BI tool, and share results. Semantic
Layer querying here is GA.

**Canvas** — drag-and-drop visual model building that emits real dbt models.
The point is analysts contributing models without writing the boilerplate,
with the output still being version-controlled SQL.

**Cost Insights** — warehouse compute cost attributed to projects, jobs, and
individual models. GA for Snowflake, BigQuery, and Databricks; preview for
Redshift. This is the tool that makes Session 11.5's performance work
measurable instead of anecdotal.

### The alternative in dbt Core

| Platform feature | Core equivalent |
|---|---|
| Studio IDE | VS Code + the dbt extension, or any editor |
| Catalog | `dbt docs generate && dbt docs serve` (Session 8.1) |
| Insights | Your warehouse console + a BI tool |
| Canvas | — no equivalent |
| Cost Insights | Query tags (Session 11.5) + warehouse billing views |
| Advanced CI | — no equivalent (Session 9.8) |
| dbt State | — plugin available for Core v1.7–1.12 (Session 9.9) |

### The VS Code extension

The officially supported local path. It provides Fusion setup, project
navigation, inline lineage, and — with the language server — the static-analysis
errors that the Rust engine produces, surfaced as you type rather than at run
time.

### Authentication

```bash
dbt login          # browser-based auth, shared across the CLI,
                   # the VS Code extension, dbt State, and the Wizard CLI
```

One login now covers the whole toolchain, and OAuth supports custom-scheme
redirects (`vscode://`, `cursor://`).

### Gotchas

- **Documentation drift.** Anything written before mid-2025 says "dbt Cloud",
  "Cloud IDE", and "dbt Explorer". Translate as you read (Session 1.2).
- **`profiles.yml` does not exist here.** Connections and credentials are
  managed in the UI as **Profiles** (Session 6.1).
- **Not everything is on every plan.** Advanced CI, dbt State, and Cost Insights
  are Enterprise-tier. Check before designing around them.

---

## Session 10.2 — Jobs, Environments, and Scheduling

**Covered on:** *Absent from the archive — listed in the original coverage gaps. Written for the 2026 update.*

### Why it matters

Session 9.10 covered the *shape* of a deployment: dev, CI, and production
environments with separate targets. This session covers how the platform
implements that, and what an Airflow-based team should replicate.

### Environments

An environment binds a **connection**, a **credential**, a **release track**
(Session 1.2), and a **target schema**. Three tiers in practice:

| Environment | Type | Schema | Deferral target |
|---|---|---|---|
| Development | Development | `dbt_<user>` | Production |
| CI | Deployment | `dbt_pr_<n>` (ephemeral) | Production |
| Production | Deployment | `analytics` | — |

Only one deployment environment can be marked **Production**; that is the one
CI and development defer to, and the one Catalog treats as canonical.

### Job types

| Type | Trigger | Purpose |
|---|---|---|
| **Deploy job** | Schedule, cron, or upstream job completion | Production builds |
| **CI job** | PR opened / new commit | Slim CI (Session 9.7) + Advanced CI (Session 9.8) |
| **Merge job** | Merge to the default branch | Post-merge production refresh |
| **Hybrid job** | Externally triggered | Tracks runs orchestrated elsewhere (Airflow, Dagster) — you keep your orchestrator and still get platform metadata, lineage, and Catalog health |

Hybrid jobs are the underrated one: they let an Airflow shop get Catalog,
Cost Insights, and run history without giving up their scheduler.

### A production deploy job

```bash
dbt deps
dbt source freshness      # allowed to fail — see below
dbt build --fail-fast
dbt docs generate
```

Settings that matter:

- **Generate docs on run** — keeps Catalog current.
- **Run source freshness** — populates `sources.json` (Session 2.1).
- **Threads** — match the warehouse's concurrency, not the model count.
- **Timeout** — set it, or a hung query holds the slot indefinitely.
- **Triggers** — cron, interval, or *on completion of another job*, which is how
  you chain ingestion → transformation without an external orchestrator.

### Notifications

Slack and Teams notifications are GA at account level. Wire failures to a
channel someone actually reads, and route *warnings* separately — a `warn`
run status now exists distinctly from `success` and `error`, which matters for
`severity: warn` tests (Session 4.1).

### Job deactivation

The platform deactivates jobs that fail repeatedly or sit idle, and the banner
now states which reason applied. If a scheduled job "just stopped running,"
check this before debugging the code.

### Doing it yourself: Airflow

```python
# the same shape, in an orchestrator you own
dbt_build = BashOperator(
    task_id="dbt_build_hourly",
    bash_command=(
        "cd /opt/dbt && "
        "dbt build --target prod --fail-fast "
        "--select tag:hourly --exclude tag:deprecated"
    ),
)
```

Whatever the orchestrator, the invariants from Session 9.10 hold: `dbt deps`
first, `dbt build` rather than `run` then `test` (Session 9.3), tags or
selectors defining the scope (Session 9.2), and artifacts persisted afterwards
(Session 9.11).

### Gotchas

- **Only one Production environment.** Marking the wrong one breaks deferral
  everywhere.
- **`dbt source freshness` failing should not fail the job** unless you mean it
  — use a separate step or a warning-level threshold.
- **CI schemas leak.** Configure them to drop on PR close or you accumulate
  thousands.
- **Release track changes apply on the next run.** A green run today does not
  guarantee a green run tomorrow when the track advances (Session 6.6).

### Checklist

- [ ] Exactly one environment marked Production
- [ ] CI job defers to it, with ephemeral schemas that get dropped
- [ ] Production job runs `dbt build`, not `run` + `test`
- [ ] Docs/Catalog generation on every production run
- [ ] Failure notifications land somewhere staffed
- [ ] Timeouts set on every job

---

## Session 10.3 — AI in dbt: Agents and the MCP Server

**Covered on:** *New capability, absent from the archive. Written for the 2026 update.*

### Why it matters

By 2026 dbt ships an AI layer, and — more usefully for engineers who prefer
their own tools — an **MCP server** that exposes the dbt project to any AI
assistant. The second is available in dbt Core, runs locally, and is the part
worth learning first.

### The dbt MCP server

MCP (Model Context Protocol) lets an assistant call tools. The dbt MCP server
exposes your project's structure, metadata, and commands as those tools, which
means an assistant can answer "what feeds `fct_orders`?" by *querying the
manifest* instead of guessing.

```bash
# self-hosted, against a local project
uvx dbt-mcp
```

Point your assistant at it (VS Code, Claude Code, Cursor — anything MCP-aware).

**Tool groups:**

| Group | Tools |
|---|---|
| Project | `get_node_details` (one tool for every resource type), `get_lineage` with `direction: upstream/downstream/both`, `list_metrics` |
| Commands | `build`, `run`, `test`, `compile`, `parse`, `docs`, `list` |
| SQL | `execute_sql` (runs against platform infrastructure, Semantic Layer aware), `text_to_sql` |
| Docs | `search_product_docs`, `get_product_doc_pages` — searches docs.getdbt.com |
| Admin | Admin API operations (remote server) |

The lineage and metadata tools are the high-value ones: they turn "which
downstream models does this column feed?" from a Catalog click-through into
something an assistant can chain into an actual answer.

### The platform agents

| Agent | What it does |
|---|---|
| **dbt Wizard** | The umbrella assistant — in Studio, in a home tab, and as a CLI (`public beta`). Builds and changes projects from natural language with inline diffs and DAG previews |
| **Developer agent** | Builds and refactors models, generates docs, tests, and semantic models |
| **Analyst agent** | Question answering in Insights, over the Semantic Layer |

BYOK is supported for Anthropic and OpenAI, so the model provider can be your
own account rather than dbt's.

### Where this actually helps

Ranked by how much of the work it genuinely removes:

1. **Documentation and test scaffolding** — generating `schema.yml` descriptions
   and obvious `not_null`/`unique` tests for a 40-column model. Tedious,
   mechanical, easy to verify.
2. **Semantic model generation** — the YAML in Session 8.2 is verbose and
   repetitive.
3. **Impact analysis** — "what breaks if I drop this column?" via lineage tools.
4. **Migration** — dbt ships an agent skill for the v1→v2 migration
   (Session 12.3).
5. **Writing the model itself** — the least reliable, and the one that most
   needs review.

### Gotchas

- **An agent's answer is only as good as the manifest.** A stale
  `manifest.json` produces confidently wrong lineage. Regenerate before asking.
- **`execute_sql` runs real queries.** Scope its credentials like any other
  service account — read-only where possible.
- **Generated tests are not free.** An assistant will happily add `unique` to a
  column that is not unique, and now CI is red for a reason nobody understands.
  Review before merging.
- **Generated documentation drifts from truth** faster than hand-written docs,
  because nobody feels ownership of it.
- **Context compression** in long agent sessions means earlier detail may be
  summarised away — re-state constraints in long conversations.

### Checklist

- [ ] MCP server configured against a *fresh* manifest
- [ ] `execute_sql` credentials scoped read-only
- [ ] Generated tests and docs reviewed, not merged blind
- [ ] The team agrees what AI-generated code needs before merge

---

# Part XI — Advanced Topics and Operations

*Python, non-warehouse storage, and the operational skills that only matter once
something is broken or expensive.*

---

## Session 11.1 — Python Models

**Covered on:** 2026-06-29, 07-12, 08-10 *(3 notes)*

### When to reach for Python

- Applying a trained ML model to a feature table
- Deduplication or fuzzy matching (`rapidfuzz`)
- Multi-step dataframe reshaping awkward in SQL window functions
- Calling external REST APIs during transformation

Supported on **Snowflake** (Snowpark), **Databricks** (PySpark), **BigQuery**
(Dataproc), and **Amazon Athena** (Spark).

### Anatomy

```python
# models/ml/scored_customers.py

def model(dbt, session):
    dbt.config(
        materialized="table",
        packages=["scikit-learn==1.4.0"],
    )

    customers = dbt.ref("stg_customers")
    orders    = dbt.ref("fct_orders")

    df = customers.join(orders, on="customer_id", how="left")
    df = df.with_column("clv_score", df["lifetime_value"] * 0.85)

    return df
```

The `model(dbt, session)` signature is required. `dbt.ref()` / `dbt.source()`
return native DataFrames for the platform.

Python models are full DAG citizens — SQL models `ref()` them and vice versa:

```sql
select * from {{ ref('scored_customers') }} where clv_score > 0.7
```

### Incremental Python

```python
def model(dbt, session):
    dbt.config(materialized="incremental", unique_key="event_id")

    df = dbt.ref("raw_events")

    if dbt.is_incremental():
        max_ts = session.sql(f"select max(event_ts) from {dbt.this}").collect()[0][0]
        df = df.filter(df["event_ts"] > max_ts)

    return df
```

### Limitations

| Constraint | Detail |
|---|---|
| Materialization | Only `table` and `incremental` — no `view` |
| Incremental logic | Filter the DataFrame manually via `dbt.is_incremental()` |
| Linting | SQL linters don't help; use `mypy`/`ruff` in pre-commit |

### Practices

- **Keep Python models thin.** Do heavy lifting in SQL upstream; use Python only
  for what SQL can't do.
- **Pin library versions** in `dbt.config(packages=[...])`.
- Python models pay session spin-up overhead — never use them for simple
  transformations.

---

## Session 11.2 — Analyses

**Covered on:** 2026-08-17 *(1 note)*

### What they are

`.sql` files in `analyses/` are **compiled but never materialized**. Full access
to `ref()`, `source()`, and Jinja; output lands in
`target/compiled/<project>/analyses/`. Copy it and run it in your warehouse
client.

```sql
-- analyses/revenue_audit.sql
-- Find orders where the header total doesn't match line items

select
    o.order_id,
    o.total_amount                                    as header_total,
    sum(li.unit_price * li.quantity)                  as line_item_total,
    o.total_amount - sum(li.unit_price * li.quantity) as discrepancy
from {{ ref('fct_orders') }} o
join {{ ref('fct_order_line_items') }} li using (order_id)
group by 1, 2
having header_total != line_item_total
order by abs(discrepancy) desc
```

```bash
dbt compile --select analyses/revenue_audit
```

### Choosing the right home for a query

| Use case | Home |
|---|---|
| Ad-hoc investigation saved for later | `analyses/` |
| Repeatable logic consumed by a model | Macro or staging model |
| Data quality check that fails a run | Singular test in `tests/` |
| Business metric exposed to BI | Mart model or semantic layer |

Because analyses are compiled but not run, CI validates that their `ref()`
targets exist and Jinja renders — without touching production data.

---

## Session 11.3 — Iceberg and `catalogs.yml`

**Covered on:** *Absent from the archive. Written for the 2026 update.*

### Why it matters

Every materialization so far writes a table *owned by one warehouse*. Apache
Iceberg breaks that coupling: the table lives in object storage, its metadata
lives in a catalog, and any engine that speaks Iceberg can read it. Write with
Snowflake, read with Spark, query with DuckDB — no copies, no sync job.

For dbt, this is the storage-layer counterpart to what Mesh (Session 7.4) did
for project boundaries.

### `catalogs.yml`

A new top-level file, alongside `dbt_project.yml`, declaring where dbt may write
Iceberg tables.

```yaml
# dbt_project.yml
flags:
  use_catalogs_v2: true       # the current spec, dbt Core v1.12+
```

```yaml
# catalogs.yml
catalogs:
  - name: lakehouse
    type: unity                 # see the table below
    table_format: iceberg       # the default
    config:
      databricks:
        catalog_database: analytics_lake
```

| `type` | Default for | Also supported by |
|---|---|---|
| `horizon` | Snowflake | duckdb |
| `glue` | Athena | snowflake, duckdb |
| `biglake_metastore` | BigQuery | snowflake |
| `unity` | Databricks | snowflake, duckdb |
| `hive_metastore` | Databricks | — |
| `ducklake` | DuckDB | — |
| `local_filesystem` | — | duckdb |
| `iceberg_rest` | — | snowflake, duckdb |

### Using it from a model

```sql
-- models/marts/fct_events.sql
{{ config(
    materialized='table',
    table_format='iceberg',
    catalog_name='lakehouse',
    base_location_root='s3://acme-lake/marts'
) }}

select * from {{ ref('stg_events') }}
```

Catalog-level config is the *lowest* precedence — a model can override
`base_location_root` or any adapter property. The exception is
`catalog_database`, which is set at the catalog and wins over a model's
`database` config.

### The older spec (1.10–1.11)

If `use_catalogs_v2` is off, `catalogs.yml` uses write integrations:

```yaml
catalogs:
  - name: my_glue_catalog
    active_write_integration: glue_rest
    write_integrations:
      - name: glue_rest
        catalog_type: iceberg_rest
        table_format: iceberg
        external_volume: prod_external_volume
        adapter_properties:
          catalog_linked_database: catalog_linked_db_glue
          catalog_linked_database_type: glue
```

Both parse; the v2 spec is where development is going.

### Gotchas

- **Most catalogs support tables only.** `table` and `incremental` work; `view`
  and `ephemeral` generally do not. Your staging layer (Session 1.3) probably
  cannot live in Iceberg.
- **Atomicity is not guaranteed.** Some catalog/engine combinations cannot do an
  atomic `create table as` and fall back to multi-statement updates without ACID
  guarantees — which means a reader can observe a half-written table. This is a
  real risk for `insert_overwrite` incremental models.
- **Compatibility is genuinely patchy.** Which materialization works on which
  engine/catalog pair changes release to release. Verify against your exact
  combination before designing around it; the community "Iceberg roulette"
  compatibility matrix exists because this is hard.
- **`external_volume` and storage permissions are outside dbt.** Most first-run
  failures are IAM, not dbt.
- **Cost moves.** Storage and compute decouple, which is the point — but it also
  means Cost Insights (Session 10.1) no longer sees the whole picture.

### When to reach for it

When more than one engine genuinely needs to read the same table, or when a
governance requirement says the data cannot live inside a single vendor's
proprietary format. Not for the general case — a normal warehouse table is
simpler, faster, and has fewer sharp edges.

---

## Session 11.4 — Debugging dbt

**Covered on:** 2026-07-15, 07-18, 07-25, 08-13, 08-19 *(5 notes)*

### The checklist, in order

1. **`dbt debug`** — is the connection working? Checks `profiles.yml`,
   credentials, adapter, dbt version, project structure. Run this first when a
   project won't start at all.

2. **`dbt parse`** — is the YAML valid? Validates all YAML and Jinja without
   executing SQL. Sub-second on most projects; surfaces syntax errors
   immediately.

3. **`dbt compile --select <model>`** — is the rendered SQL correct? The single
   most useful debugging command. Renders all Jinja to `target/compiled/`
   without executing.

   ```bash
   dbt compile --select my_model
   cat target/compiled/my_project/models/marts/my_model.sql
   ```

   Paste the result straight into your warehouse console.

4. **Read `target/run/<model>.sql`** — what actually executed? If a model
   compiled fine but failed at execution, this is the SQL that hit the warehouse.

5. **`{{ log(value, info=True) }}`** — what does that variable hold?

   ```jinja
   {% macro my_macro(event_type) %}
     {{ log("event_type received: " ~ event_type, info=True) }}
     select * from events where type = '{{ event_type }}'
   {% endmacro %}
   ```

6. **`dbt test --select <model>`** — which specific assertion is failing?
   Narrow before you re-run everything.

### The `target/` directory

| Path | Contents |
|---|---|
| `target/compiled/` | Rendered Jinja SQL (post-compile) |
| `target/run/` | The SQL actually executed |
| `target/manifest.json` | Full DAG metadata |
| `target/run_results.json` | Timing and status of the last run |

### Also useful

```bash
dbt run --fail-fast                       # stop at the first failure
dbt run --select +failing_model           # iterate on a broken node
dbt test --store-failures --select model  # see WHICH rows failed (Session 4.3)
```

These six steps handle the vast majority of dbt issues without digging into
warehouse query history.

---

## Session 11.5 — Performance Tuning

**Covered on:** 2026-06-30, 07-09, 07-11, 07-31 *(4 notes)*

### 1. Materialization is the biggest lever

| Materialization | Build cost | Query cost | Use when |
|---|---|---|---|
| `view` | None | High | Cheap intermediates, rarely queried |
| `table` | High | Low | Frequently queried, heavy aggregations |
| `incremental` | Low | Low | Large append/merge-friendly fact tables |
| `ephemeral` | None | Medium | Lightweight reusable CTEs |

Slow view → make it a table. Slow full rebuild → make it incremental.

### 2. Filter the *source*, not just `{{ this }}`

The most common incremental performance bug:

```sql
-- BAD: the WHERE on {{ this }} is correct, but the source is still fully scanned
{% if is_incremental() %}
  where event_ts > (select max(event_ts) from {{ this }})
{% endif %}

-- GOOD: give the warehouse something to prune on
{% if is_incremental() %}
  where event_ts > (select max(event_ts) from {{ this }})
    and event_ts >= dateadd('day', -3, current_date)
{% endif %}
```

The lookback both narrows the scan and guards against late-arriving data.

### 3. Partition and cluster

```sql
-- BigQuery
{{ config(
    materialized='incremental',
    partition_by={"field": "event_date", "data_type": "date", "granularity": "day"},
    cluster_by=["user_id", "event_type"]
) }}

-- Snowflake
{{ config(materialized='table', cluster_by=['customer_id', 'event_date']) }}

-- Redshift
{{ config(materialized='table', sort=['event_date', 'customer_id'], dist='customer_id') }}
```

Partitioning narrows row groups; clustering orders within them. Match keys to
the `WHERE` and `JOIN` columns downstream queries actually use.

On BigQuery, prefer `insert_overwrite` to `merge` when the unique key aligns
naturally with partitions — it avoids a full-table scan.

**Always filter on the partition column inside `{% if is_incremental() %}`** or
the engine scans every partition even when writing to one.

### 4. Kill `SELECT *` in staging and intermediate

```sql
-- BAD: carries 60 columns through 3 transform layers
select * from {{ ref('stg_orders') }}

-- GOOD
select order_id, customer_id, order_amount, ordered_at
from {{ ref('stg_orders') }}
```

On columnar warehouses, scan cost is proportional to columns selected — a wide
`SELECT *` chain multiplies cost at every layer.

### 5. Parallelism

```yaml
# profiles.yml
threads: 8      # respects DAG dependencies
```

On large projects the *graph itself* becomes the bottleneck before the warehouse
does — dbt adds an edge for every test, and on 10k-model projects that graph
costs real time and memory to walk:

```bash
dbt build --use-fast-test-edges     # 1.10+
```

### 6. Tag your queries so you can find the slow ones

```yaml
# dbt_project.yml
query-comment:
  comment: "dbt={{ dbt_version }} | project={{ project_name }} | model={{ model.name }} | profile={{ target.name }}"
  append: true
```

Every dbt query in Snowflake's `QUERY_HISTORY` or BigQuery's
`INFORMATION_SCHEMA.JOBS` is now attributable to a model.

### 7. Measure before you optimise

Everything above is a hypothesis until you have per-model cost. Three ways to
get it, in increasing order of convenience:

| Source | What it gives you |
|---|---|
| `run_results.json` (Session 9.11) | Execution time per node, per run |
| `query-comment` + warehouse query history | Bytes scanned and credits per model |
| **Cost Insights** (Session 10.1) | Warehouse cost attributed to project, job, and model, with an Assets filter for models vs tests |

The most common outcome of actually measuring is discovering that the slow model
everyone complains about is cheap, and the expensive one is a test nobody
noticed.

### Quick wins checklist

- [ ] Replace `view` with `table` for models queried >10×/day
- [ ] Add source-side date filters to every incremental model
- [ ] Set `cluster_by` / `partition_by` on large fact tables
- [ ] Raise `threads` to 4–8 in production profiles
- [ ] Remove `SELECT *` from staging and intermediate layers
- [ ] Adopt Slim CI (Session 9.7) — often an 80–90% CI time cut
- [ ] Add a `query-comment` so slow models are attributable
- [ ] Use `--sample` / `--empty` for the dev loop (Session 9.6)
- [ ] On large projects, `--use-fast-test-edges`
- [ ] Consider state-aware orchestration for deploy jobs (Session 9.9)

---

## Session 11.6 — Data Quality Observability (Where dbt Fits)

**Covered on:** 2026-05-31 *(1 note — the earliest dbt-adjacent material in the archive)*

### The five dimensions

1. **Freshness** — is data arriving on schedule? (dbt: `source freshness`)
2. **Volume** — did the expected number of rows arrive? A 90% drop in event
   count is a bug, not user behaviour.
3. **Schema** — did column types or names change? Schema drift is the leading
   cause of silent pipeline failure. (dbt: contracts, `on_schema_change`)
4. **Uniqueness** — are primary keys duplicated? Usually introduced by retry
   logic in ingestion. (dbt: `unique` tests)
5. **Null rate / distribution** — are nulls within historical norms? Has a
   numeric distribution shifted? (dbt: `dbt_utils.not_null_proportion`,
   `dbt_expectations`)

### Three monitoring layers

- **Source-level** — assert on raw ingested data before any transformation.
  Catches upstream issues at the earliest point.
- **Transformation-level** — dbt tests after each step. Catches your own logic
  errors.
- **Consumption-level** — monitor metric values in the BI layer.

### The dbt + Elementary stack

For teams already on dbt, **Elementary** (open-source) is the fastest path: it
instruments dbt runs, exposes test results as dbt models, and generates an HTML
report with test history, anomalies, and lineage. Combined with native tests,
that's a solid baseline with **zero new infrastructure**.

Tools like Monte Carlo, Anomalo, and Bigeye add unsupervised anomaly detection
that learns baselines automatically — which matters because manual threshold
tuning is the reason quality checks don't scale past a few hundred columns.

### The governing principle

The worst outcome is a **silent failure**. The second worst is **alert fatigue**.
Calibrate so only actionable anomalies page a human; log the rest.

Implement **circuit breakers**: if a source fails its freshness check, block
downstream models rather than propagating stale data deeper. In dbt terms:

```bash
dbt source freshness && dbt build
```

---

# Part XII — Upgrading and the Road to v2

*The original coverage notes flagged "dbt-core upgrade/migration paths between
minor versions" as absent from the archive. In 2026 that gap became the most
consequential one in the book: there is now a major version boundary to cross,
not just a minor one.*

---

## Session 12.1 — Version Strategy: Pinning, Tracks, and Staying Current

**Covered on:** *Absent from the archive. Written for the 2026 update.*

### Why it matters

dbt ships continuously. A project that never upgrades accumulates deprecations
until the jump becomes a project of its own; a project that upgrades blindly
gets surprised in production. The middle path is deliberate and cheap.

### Pin explicitly

```yaml
# dbt_project.yml
require-dbt-version: [">=1.10.0", "<1.13.0"]
```

dbt refuses to run outside this range — which turns "someone's laptop has 1.8
and mine has 1.12" from a mystery bug into an immediate, legible error.

Pin the adapter too, exactly, in CI:

```txt
# requirements.txt
dbt-core==1.12.3
dbt-snowflake==1.12.0
```

And pin packages by tag or version, never by branch (Session 5.7).

### The version landscape

| Version | Notable |
|---|---|
| 1.8 | Unit tests; adapters decoupled from `dbt-core` |
| 1.9 | `microbatch`; YAML snapshots; `hard_deletes`; `dbt_valid_to_current`; `state:modified` improvements |
| 1.10 | `--sample`; `catalogs.yml`; `loaded_at_query`; `config.meta_get()`; the deprecation wave |
| 1.11 | UDFs; JSON-schema YAML validation on by default; `DBT_ENGINE_` env prefix |
| 1.12 | Current stable (`1.12.3`); enforces the behaviour changes that v2 removes; ships the Fusion-powered parser |
| 2.0 | Rust engine, Apache 2.0; beta (`2.0.0b2`) as of August 2026 |

### On the platform: pick a cadence, not a number

You cannot select a minor version on the platform any more — you select a
release track (Session 1.2) and dbt upgrades you on that cadence. Practical
allocation:

| Environment | Track |
|---|---|
| Development | `latest` / `fusion-nightly` — find breakage early, where it's cheap |
| CI | Same as production |
| Production | `compatible` / `fusion-stable`, or `extended` if you need bake time |

Running development *ahead* of production is the entire trick: your engineers
hit the breakage weeks before the scheduled job does.

### A minor-version upgrade, in order

```bash
# 1. read the release notes — specifically the behaviour-flag section
# 2. upgrade in a branch
pip install --upgrade dbt-core==1.12.3 dbt-snowflake==1.12.0

# 3. parse first — most breakage is parse-time
dbt parse

# 4. clean up deprecations mechanically
uvx dbt-autofix

# 5. build against a dev schema, then diff against prod
dbt build --target dev --full-refresh
```

Step 5 matters more than it looks: a minor upgrade that parses cleanly can still
change a numeric result (a changed default, a fixed rounding bug). Compare
before promoting — Advanced CI (Session 9.8) does this for you if you have it.

### Gotchas

- **Adapters version independently from `dbt-core` since 1.8.** `dbt-core==1.12`
  with `dbt-snowflake==1.9` is a supported-looking combination that will bite.
  Upgrade both.
- **`dbt-snowflake` below 1.10.6 is incompatible with Snowflake's September 2026
  column-size increase** for incremental models with string collation and
  `on_schema_change: sync_all_columns` (Session 3.2). This is a hard deadline,
  not a warning.
- **Behaviour flags mature on a schedule** (2026-09-01 on Latest). Flipping them
  yourself first is the whole point (Session 6.6).
- **Package compatibility lags.** Check `dbt-utils` and friends support the
  target version before upgrading, not after.
- **`--warn-error` in CI turns every new deprecation into a failed build.** Use
  `warn_error_options` instead.

### Checklist

- [ ] `require-dbt-version` set to a range, not open-ended
- [ ] `dbt-core` and adapter pinned exactly in CI
- [ ] Development runs a track ahead of production
- [ ] Upgrades land in a branch with a data diff before promotion
- [ ] `dbt-snowflake >= 1.10.6` if on Snowflake

---

## Session 12.2 — Clearing the Path: `dbt parse`, `dbt-autofix`, and the v2 Parser

**Covered on:** *Absent from the archive. Written for the 2026 update.*

### Why it matters

Nearly all of the work of getting to v2 is *deprecation cleanup on v1*, and
almost all of it is mechanical. Doing it incrementally on 1.10–1.12 turns the
major-version move from a migration project into a version bump.

### The three-command loop

```bash
# 1. what is wrong?
dbt parse

# 2. fix what can be fixed automatically
uvx dbt-autofix

# 3. will the new engine accept it?
dbt parse --use-v2-parser
```

Step 3 is the real gate. dbt 1.12 ships the Fusion-powered parser behind a flag,
so you can validate against the v2 language spec while still running the Python
engine in production. A clean `--use-v2-parser` run is the signal that migration
is viable.

### What `dbt-autofix` handles

The deprecations from Session 6.6, mechanically:

- custom top-level YAML keys → nested under `config.meta`
- properties moving under `config:` (`freshness`, `tags`, `docs`, `group`, `access`)
- standalone YAML anchors → the `anchors:` key
- `warn_error_options` key renames (`include`→`error`, `exclude`→`warn`)
- missing `+` prefixes on configs in `dbt_project.yml`

Run it on a branch and read the diff. It is a rewriting tool, not a reviewer.

### What it does not handle

| Needs a human | Why |
|---|---|
| `--models` / `-m` in orchestration | Lives in Airflow DAGs and job configs, outside the dbt project |
| Custom materializations (Session 5.6) | Static analysis may reject dynamic SQL construction |
| Heavily dynamic macros | Same reason — `run_query` at parse time, string-built SQL |
| Adapter-specific escape hatches | Raw SQL that only the old parser tolerated |
| Duplicate YAML keys | The fix requires knowing which one you meant |

### Why the v2 parser is stricter

The Rust engine has a **defined language specification**. In v1, an unrecognised
YAML key was silently ignored — which is why `desciptin:` on a model produced no
error and no description. In v2 it is an error. The same applies to argument
types, config shapes, and Jinja block structure.

This is a genuine improvement and also the source of most migration noise: a
mature project accumulates years of silently-ignored typos, and they all surface
at once.

### Sequencing it

```
1.9 or earlier
   ↓  upgrade minor versions one at a time, flags on at each step
1.12  +  all behaviour flags enabled  +  dbt parse clean
   ↓  dbt parse --use-v2-parser clean
2.0 / Fusion
```

Do not skip from 1.9 to 2.0. Each minor version's flags exist to make the next
one boring.

### Gotchas

- **JSON-schema validation in 1.11 produces a large first-run warning volume.**
  Most are real typos. Read them; do not silence them wholesale.
- **`uvx dbt-autofix` rewrites files in place.** Commit first.
- **Silencing is a migration tool, not a destination:**

  ```yaml
  flags:
    warn_error_options:
      silence: [CustomTopLevelKeyDeprecation]
  ```

  Use it to keep CI green for a sprint, not for a year.
- **A clean parse is not a clean run.** It proves the project is *readable* by
  v2, not that every macro behaves identically.

### Checklist

- [ ] `dbt parse` produces zero warnings on the current version
- [ ] `dbt-autofix` has been run and its diff reviewed
- [ ] `dbt parse --use-v2-parser` runs clean
- [ ] The non-mechanical list (custom materializations, dynamic macros) is
      written down with an owner

---

## Session 12.3 — Migrating to Fusion / dbt Core v2

**Covered on:** *New capability, absent from the archive. Written for the 2026 update.*

### Why it matters

This is the first major version boundary dbt has had in years, and the first
time the engine underneath changed language. It is worth doing — the wins are
real — but it is a migration, not an upgrade, and it deserves to be planned as
one.

### What you gain

| | |
|---|---|
| **Parse speed** | Order of magnitude on large projects; the dev loop stops being parse-bound |
| **Static analysis** | Column-level type and reference errors caught before any query runs |
| **Column-level lineage** | Real column lineage in Catalog, not model-level approximation |
| **`dbt lint`** | 40×–250× faster than SQLFluff, SQLFluff-compatible (Session 4.4) |
| **dbt State** | Skip rebuilds when nothing changed (Session 9.9) |
| **Parquet artifacts** | `manifest`/`run_results` queryable directly with DuckDB (Session 9.11) |
| **Docs v2** | A catalog that scales past the point where the static site stops loading |
| **Install** | A single binary; no Python virtualenv |

### Choosing a distribution

```
dbt-core   Apache 2.0, fully open source, the Rust engine
dbt        "Fusion" — the same engine + proprietary extensions, free to use
```

dbt Labs recommends the Fusion CLI for most users because it includes more
out of the box. Project code is portable in both directions, so this is not a
lock-in decision at the code level.

### The route

```bash
# 0. prerequisite: Session 12.2 complete — clean parse under --use-v2-parser

# 1. install alongside the existing setup, don't replace it
dbt login

# 2. run both engines against the same project and diff
dbt parse
dbt compile --select marts        # compare target/compiled/ between engines

# 3. build to a scratch schema and compare row counts and checksums
dbt build --target v2_test

# 4. move development first, production last
```

Running the two engines side by side through a full development cycle is the
step teams skip and regret. Compiled SQL diffs are where the surprises are.

### Adapter readiness (August 2026)

| Adapter | Status |
|---|---|
| Snowflake, BigQuery, Databricks, Redshift | Preview |
| Spark (3.0), DuckDB, Salesforce Data 360 | Beta |
| Everything else | Not yet |

If your adapter is not listed, the migration is not available yet — track it
rather than planning around it. Note that new platform projects on the four
Preview adapters already default to Fusion Stable.

### What tends to break

Ranked by how often it comes up:

1. **Custom materializations** (Session 5.6) — dynamic SQL construction that
   static analysis cannot verify.
2. **Macros that build SQL as strings** — same root cause.
3. **Silently-ignored YAML** — years of typos surfacing as errors.
4. **`--models` / `-m`** — warns in 1.10, *errors* in Fusion. Fix the
   orchestrator, not the project.
5. **Adapter-specific escape hatches** — raw SQL the old parser waved through.
6. **Python models** — supported, but excluded from dbt State.

### Tooling

- `dbt parse --use-v2-parser` — the readiness gate (Session 12.2)
- `uvx dbt-autofix` — mechanical deprecation fixes
- The dbt migration agent skill — for the non-mechanical remainder (Session 10.3)
- The Fusion upgrade-readiness guide in the official docs

### Gotchas

- **v2 is beta as of this writing** (`2.0.0b2`). Production migration is a
  judgement call about your risk tolerance and adapter maturity, not a default.
- **Do not migrate and refactor in the same PR.** When the numbers move you
  need to know which change caused it.
- **Behaviour flags must be on first.** v2 *removes* the old behaviours; it
  does not offer them as options.
- **`DBT_` env vars became `DBT_ENGINE_`** in 1.11 (`DBT_STATE` →
  `DBT_ENGINE_STATE`, `DBT_PROJECT_DIR` → `DBT_ENGINE_PROJECT_DIR`). CI configs
  are full of these.
- **Keep the Python engine installable** until production has run on v2 for a
  full cycle including a month-end close.

### Checklist

- [ ] Session 12.2 complete: `--use-v2-parser` clean
- [ ] Adapter is Preview or better for the target platform
- [ ] Compiled SQL diffed between engines for the critical marts
- [ ] Row counts and checksums compared on a scratch build
- [ ] Development migrated and lived in for a full cycle before production
- [ ] `DBT_ENGINE_` env var renames applied in CI and orchestration
- [ ] Rollback path documented and tested

---

# Appendices

## Appendix A — Command Cheat Sheet

### Build commands

```bash
dbt build                       # seeds → snapshots → models → tests → UDFs, in DAG order
dbt run                         # models only
dbt test                        # tests only
dbt seed                        # load CSVs from seeds/
dbt snapshot                    # capture SCD2 history
dbt source freshness            # check ingestion recency
dbt compile                     # render Jinja to target/compiled/, run nothing
dbt parse                       # validate YAML/Jinja, run nothing
dbt debug                       # test the warehouse connection
dbt deps                        # install packages from packages.yml
dbt clean                       # remove target/ and dbt_packages/
dbt retry                       # re-run only what failed last time
dbt docs generate && dbt docs serve
dbt ls --select <selector>      # preview a selection — free, no SQL
dbt run-operation <macro> --args '{"k": "v"}'
dbt show --select model --limit 5    # preview results without materialising
```

### Newer commands (1.9 → v2)

```bash
dbt clone --state DIR           # zero-copy clone from a manifest      (9.5)
dbt lint                        # built-in SQL linter, Fusion / v2     (4.4)
dbt login                       # browser auth, shared across the toolchain (10.1)
dbt state explain               # why each node was built or reused    (9.9)
dbt state explain --verbose -s <model>
dbt parse --use-v2-parser       # v2 readiness gate                    (12.2)
uvx dbt-autofix                 # mechanical deprecation fixes         (12.2)
uvx dbt-mcp                     # local MCP server for AI assistants   (10.3)
```

### Selection

```bash
--select model_name             # one node
--select +model                 # + upstream
--select model+                 # + downstream
--select +model+                # full graph around it
--select 2+model  / model+1     # depth-limited
--select @model                 # model + ancestors + ancestors' descendants
--select tag:finance
--select path:models/staging
--select source:raw.orders
--select config.materialized:incremental
--select state:modified+ --state ./prod
--select source_status:fresher+ --state ./prod
--select test_type:unit
--select resource_type:function             # UDFs
--exclude-resource-type unit_test
--select result:fail --state ./target
--select "path:models/staging,tag:core"     # intersection (comma)
--select path:models/staging tag:core       # union (space)
--exclude tag:experimental
--selector <name_from_selectors.yml>
```

### Flags worth memorising

```bash
--full-refresh        # rebuild incremental models from scratch
--defer --state DIR   # resolve unselected refs to production
--favor-state         # prefer prod even for locally modified upstreams
--fail-fast           # abort on first failure
--target prod         # switch profiles.yml target
--vars '{k: v}'       # override project variables
--store-failures      # persist failing test rows
--threads N           # override profile parallelism
--empty               # schema-only dry run, zero rows            (9.6)
--sample="3 days"     # time-sliced dev build                     (9.6)
--event-time-start / --event-time-end      # microbatch backfill  (3.3)
--use-fast-test-edges                      # smaller graph, big projects (11.5)
--warn-error-options '{"error": ["Deprecations"]}'                (6.6)
--target-path DIR     # where artifacts are written
```

### Deprecated — fix these

```bash
--models / --model / -m    # → --select / -s   (warns in 1.10, ERRORS in Fusion)
-o / --output              # for sources.json → use --target-path
DBT_STATE / DBT_PROJECT_DIR # → DBT_ENGINE_STATE / DBT_ENGINE_PROJECT_DIR (1.11+)
```

---

## Appendix B — Config Quick Reference

### Model config

```sql
{{ config(
    materialized      = 'incremental',        -- view | table | incremental | ephemeral
                                              -- | materialized_view | dynamic_table (Snowflake)
    incremental_strategy = 'merge',           -- append | merge | delete+insert
                                              -- | insert_overwrite | microbatch
    unique_key        = 'order_id',           -- REQUIRED for merge
    on_schema_change  = 'append_new_columns', -- ignore | fail | append_new_columns | sync_all_columns
    partition_by      = {"field": "event_date", "data_type": "date"},
    cluster_by        = ['user_id'],
    tags              = ['finance', 'daily'],
    schema            = 'finance',
    alias             = 'orders',
    grants            = {'select': ['reporter']},
    post_hook         = ["GRANT SELECT ON {{ this }} TO ROLE reporter"],
    pre_hook          = [],
    contract          = {'enforced': True},
    access            = 'public',             -- private | protected | public
    group             = 'finance',
    event_time        = 'ordered_at',         -- microbatch, --sample, Advanced CI
    on_configuration_change = 'apply',        -- materialized views: apply | continue | fail
    catalog_name      = 'lakehouse',          -- Iceberg (11.3)
    table_format      = 'iceberg'
) }}
```

### Microbatch (1.9+)

```sql
{{ config(
    materialized         = 'incremental',
    incremental_strategy = 'microbatch',
    event_time           = 'session_start',   -- REQUIRED
    batch_size           = 'day',             -- REQUIRED: hour|day|month|year
    begin                = '2024-01-01',      -- REQUIRED
    lookback             = 3,
    concurrent_batches   = true,
    full_refresh         = false
) }}
```

### Snapshot config — 1.9+ YAML form

```yaml
snapshots:
  - name: snap_orders
    relation: source('shopify', 'orders')
    config:
      schema: snapshots
      unique_key: order_id
      strategy: timestamp                  # or 'check'
      updated_at: updated_at               # timestamp strategy
      check_cols: ['status']               # check strategy
      hard_deletes: new_record             # ignore | invalidate | new_record
      dbt_valid_to_current: "'9999-12-31'::date"
      snapshot_meta_column_names:
        dbt_valid_from: valid_from
        dbt_valid_to: valid_to
```

The legacy `{% snapshot %}` block with `target_schema` and
`invalidate_hard_deletes` still works but is superseded.

### State-aware freshness (Fusion)

```yaml
models:
  - name: fct_orders
    config:
      freshness:
        build_after:
          count: 4
          period: hour              # minute | hour | day
          updates_on: all           # all | any
```

### UDF properties (1.11+)

```yaml
functions:
  - name: is_positive_int
    config:
      schema: udf
      volatility: deterministic     # deterministic | stable | non-deterministic
      runtime_version: "3.11"       # Python only
      entry_point: main             # Python only
      packages: [numpy]
    arguments:
      - {name: a_string, data_type: string}
    returns: {data_type: integer}
```

### Behaviour flags (`dbt_project.yml`)

```yaml
flags:
  state_modified_compare_more_unrendered_values: true   # 1.9
  skip_nodes_if_on_run_start_fails: true                # 1.9
  validate_macro_args: true                             # 1.10
  require_all_warnings_handled_by_warn_error: true      # 1.10
  require_unique_project_resource_names: true           # 1.11
  use_catalogs_v2: true                                 # 1.12, Iceberg
  warn_error_options:
    error: []      # was "include"
    warn:  []      # was "exclude"
    silence: []
```

---

## Appendix C — Decision Tables

### Which materialization?

| Situation | Choice |
|---|---|
| Raw source cleanup | `view` |
| Small reference/lookup | `view` or `table` |
| Large fact table (millions+ rows) | `incremental` |
| Final mart queried by BI | `table` |
| Tiny reusable sub-query, never queried directly | `ephemeral` |
| Needs to be fresher than the dbt schedule | `materialized_view` / `dynamic_table` |
| None of the above fit, and a hook cannot do it | Custom materialization (rarely) |

### Which incremental strategy?

| Situation | Choice |
|---|---|
| Immutable event log, no late data | `append` |
| Rows can update (orders, users) | `merge` + `unique_key` |
| Warehouse has no MERGE (Redshift, Spark) | `delete+insert` |
| Partitioned table, late data within a partition | `insert_overwrite` |
| Time-series table, backfills, retryable batches (1.9+) | `microbatch` |
| No reliable event-time column | Not `microbatch` — stay on `merge` |

### Where does this data belong?

| Data lives… | Use |
|---|---|
| Loaded by an external pipeline | `source()` |
| A small CSV you maintain | seed |
| Produced by a dbt model | `ref()` |

### Which kind of test?

| You want to assert… | Use |
|---|---|
| A column is unique / not null / in a list / a valid FK | Generic test |
| A cross-column or cross-model business rule | Singular test in `tests/` |
| The SQL logic is correct, before any data exists | Unit test |
| The output schema will not change | Model contract |
| Raw data arrived on time | `dbt source freshness` |
| The SQL is formatted consistently | SQLFluff / `dbt lint` |
| This PR did not silently change the numbers | Advanced CI (`dbt compare`) |

### Which command?

| Situation | Command |
|---|---|
| Iterating on models locally | `dbt run --select model` |
| CI or production | `dbt build` |
| Checking a selector before spending money | `dbt ls --select ...` |
| Working on one model in a big project | `dbt run --select model --defer --state ./prod` |
| Just checking it compiles | `dbt build --select model --empty` |
| Checking logic on a data slice | `dbt run --select model --sample="3 days"` |
| CI needs real tables for incremental models | `dbt clone --state ./prod` first |
| Something failed halfway | `dbt retry` |
| A deploy job rebuilds things that did not change | State-aware orchestration |

### Macro, UDF, or model?

| You want… | Use |
|---|---|
| To generate SQL at compile time | Macro |
| Logic callable from BI tools and notebooks | UDF |
| Warehouse-specific SQL from one definition | Macro + `adapter.dispatch` |
| To emit DDL/DML | Macro |
| A persisted result set | Model |

### Which engine?

| Situation | Engine |
|---|---|
| Adapter not yet supported by Fusion | dbt Core v1 (Python) |
| Want static analysis, column lineage, fast lint | Fusion / dbt Core v2 |
| Want the cost savings of dbt State | Fusion (plugin exists for Core 1.7–1.12) |
| Production, risk-averse, today | dbt Core v1.12 with all behaviour flags on |

---

## Appendix D — Glossary

| Term | Meaning |
|---|---|
| **Adapter** | The plugin connecting dbt to a specific warehouse (`dbt-snowflake`, `dbt-bigquery`) |
| **Analysis** | Compiled-but-not-materialized SQL in `analyses/` |
| **Artifact** | JSON written to `target/` (`manifest`, `run_results`, `catalog`, `sources`) |
| **Behaviour flag** | An opt-in switch in `flags:` that enables a changed default ahead of the next major version |
| **build_after** | Freshness config controlling how often state-aware orchestration may rebuild a model |
| **Canvas** | Drag-and-drop visual model building in the dbt platform |
| **Catalog** | The dbt platform's metadata and lineage explorer (formerly dbt Explorer) |
| **`catalogs.yml`** | Declares external catalogs (Iceberg, Glue, Unity, Horizon) dbt may write to |
| **Contract** | Enforced declaration of a model's output columns and types |
| **DAG** | The dependency graph dbt infers from `ref()` and `source()` |
| **dbt Core v2** | The Rust engine released as open source under Apache 2.0; beta as of August 2026 |
| **dbt State** | Persistent code + data state used to skip unnecessary rebuilds |
| **Ephemeral** | A materialization compiled inline as a CTE, never persisted |
| **`event_time`** | The column declaring when a row occurred; drives microbatch, `--sample`, and Advanced CI |
| **Exposure** | A declared downstream consumer (dashboard, ML model, app) |
| **Function (UDF)** | A warehouse function defined in `functions/` and referenced with `function()` |
| **Fusion** | The commercial distribution of the Rust engine, with proprietary extensions |
| **Generic test** | A reusable, YAML-declared assertion |
| **Group** | A named collection of models with an owner, used for access control |
| **Hook** | SQL executed before/after a model or run |
| **Insights** | Exploratory analysis and Semantic Layer querying in the dbt platform |
| **Macro** | A reusable Jinja function in `macros/` |
| **Materialization** | The strategy dbt uses to persist a model |
| **Mesh** | Multi-project architecture with cross-project `ref()` |
| **MetricFlow** | The engine behind the dbt Semantic Layer |
| **Microbatch** | Incremental strategy that splits work into independent time-bounded batches |
| **Model** | One `.sql` file containing one `SELECT` |
| **Node** | Any DAG member: model, test, seed, snapshot, source, exposure |
| **Package** | An installable collection of macros/models/tests |
| **Profile** | Warehouse connection config in `profiles.yml`; on the platform, a named connection + credential set |
| **Release track** | A platform upgrade cadence (`latest`, `compatible`, `fusion-stable`, …) chosen instead of a version number |
| **Seed** | A CSV in `seeds/` loaded as a table |
| **Semantic model** | A YAML declaration of entities/dimensions/metrics on a model; since 1.12 embedded in the model's own YAML |
| **Singular test** | A SQL file in `tests/` that passes when it returns zero rows |
| **Slim CI** | Building only `state:modified+` with `--defer` |
| **Snapshot** | SCD Type 2 history table built by `dbt snapshot` |
| **Source** | A declared raw table outside the dbt project |
| **Static analysis** | Compile-time SQL type and reference checking, available only on the Rust engine |
| **Studio IDE** | The dbt platform's browser development environment (formerly the Cloud IDE) |
| **Target** | A named connection context (`dev`, `ci`, `prod`) within a profile |
| **Unit test** | A logic test using mocked inputs (dbt 1.8+) |
| **Wizard** | The dbt platform's AI assistant, in Studio, a home tab, and a CLI |


---

## Appendix E — Source Index

Every topic mapped back to the daily notes it came from, so you can read the
primary material. Format: **Topic** *(n sections)* → dates. Session numbers are
the current ones; the Part groupings below are the archive's original topic
clusters.

### Part I — Foundations

- **What dbt Is** *(6)* — 2026-06-02, 06-03, 06-06, 06-08, 06-09, 06-16
- **Project Structure & Layering** *(4)* — 2026-06-21, 07-06, 07-07, 08-11
- **Materializations** *(1)* — 2026-07-05

### Part II — Getting Data In

- **Sources & Freshness** *(7)* — 2026-06-20, 06-27, 07-02, 07-21, 07-27, 08-10, 08-19
- **Seeds** *(11)* — 2026-06-18, 06-22, 06-29, 07-03, 07-14, 07-17, 07-22, 07-30, 08-05, 08-10, 08-19

### Part III — Building Models at Scale

- **Incremental Models** *(26)* — 2026-06-04, 06-05, 06-17, 06-22, 06-23, 06-25, 06-29, 07-02, 07-06, 07-07, 07-10, 07-13, 07-14, 07-16, 07-22, 07-28, 08-01, 08-02, 08-03, 08-04, 08-05, 08-06, 08-11, 08-14, 08-17, 08-19
- **`on_schema_change`** *(1)* — 2026-08-16
- **Ephemeral Models** *(1)* — 2026-07-19
- **Snapshots / SCD2** *(42)* — 2026-06-16, 06-17, 06-18, 06-19, 06-22, 06-23, 06-24, 06-26, 06-28, 06-30, 07-01, 07-04, 07-05, 07-06, 07-07, 07-08, 07-09, 07-10, 07-12, 07-13, 07-16, 07-18, 07-19, 07-20, 07-21, 07-23, 07-24, 07-25, 07-26, 07-28, 07-29, 07-31, 08-01, 08-02, 08-04, 08-06, 08-07, 08-09, 08-13, 08-14, 08-17, 08-18

### Part IV — Data Quality

- **Tests (Generic & Singular)** *(11)* — 2026-06-17, 06-21, 07-02, 07-10, 07-14, 07-16, 07-21, 07-31, 08-03, 08-04
- **Unit Tests** *(11)* — 2026-06-24, 06-28, 07-04, 07-17, 07-22, 07-23, 07-24, 07-29, 08-07, 08-13, 08-16
- **`store_failures`** *(3)* — 2026-06-25, 07-07, 07-26

### Part V — Programmability

- **Macros & Jinja** *(24)* — 2026-06-16, 06-17, 06-18, 06-21, 06-22, 06-27, 06-30, 07-01, 07-02, 07-06, 07-07, 07-09, 07-10, 07-11, 07-14, 07-21, 07-22, 07-28, 08-01, 08-02, 08-04, 08-10, 08-18
- **`run_query` / `execute`** *(1)* — 2026-08-15
- **`run-operation`** *(1)* — 2026-08-11
- **Cross-DB Macros / dispatch** *(4)* — 2026-07-09, 07-18, 07-25, 08-15
- **Packages & dbt-utils** *(19)* — 2026-06-19, 06-20, 06-23, 06-27, 07-01, 07-04, 07-08, 07-13, 07-15, 07-20, 07-23, 07-26, 07-31, 08-03, 08-06, 08-11, 08-12, 08-14, 08-18

### Part VI — Configuration and Environments

- **Profiles & Targets** *(1)* — 2026-08-16
- **Variables & `env_var`** *(9)* — 2026-06-20, 06-28, 07-05, 07-17, 07-25, 07-30, 08-08, 08-09, 08-17
- **Custom Schema / Alias** *(4)* — 2026-07-01, 07-27, 08-11, 08-12
- **Hooks** *(13)* — 2026-06-20, 06-26, 07-04, 07-05, 07-13, 07-18, 07-19, 07-24, 07-28, 08-06, 08-12, 08-15, 08-20
- **Grants** *(2)* — 2026-07-26, 08-07

### Part VII — Interfaces and Governance

- **Model Contracts** *(46)* — 2026-06-16, 06-17, 06-18, 06-19, 06-20, 06-21, 06-22, 06-23, 06-24, 06-26, 06-28, 06-29, 06-30, 07-01, 07-02, 07-03, 07-05, 07-08, 07-09, 07-10, 07-11, 07-12, 07-13, 07-14, 07-15, 07-17, 07-18, 07-19, 07-20, 07-21, 07-23, 07-26, 07-27, 07-28, 07-29, 07-30, 07-31, 08-01, 08-02, 08-04, 08-05, 08-06, 08-08, 08-15, 08-16, 08-17
- **Model Versioning** *(3)* — 2026-06-27, 08-10, 08-18
- **Access & Groups** *(5)* — 2026-06-25, 07-08, 07-22, 08-09, 08-14
- **dbt Mesh** *(3)* — 2026-06-25, 07-16, 08-12
- **Exposures** *(15)* — 2026-06-18, 06-23, 06-24, 06-29, 07-03, 07-12, 07-17, 07-20, 07-24, 07-27, 07-30, 08-05, 08-09, 08-15, 08-20

### Part VIII — Documentation and Semantics

- **Documentation & Docs Site** *(4)* — 2026-06-24, 07-11, 08-08, 08-14
- **Semantic Layer / MetricFlow** *(11)* — 2026-06-16, 06-21, 06-28, 07-03, 07-15, 07-19, 07-23, 07-29, 08-01, 08-08, 08-19

### Part IX — Running dbt

- **Node Selection & Graph Ops** *(12)* — 2026-06-19, 06-26, 07-04, 07-12, 07-15, 07-20, 07-24, 07-29, 08-02, 08-07, 08-13, 08-18
- **Tags** *(2)* — 2026-07-30, 08-16
- **`dbt build`** *(1)* — 2026-08-09
- **`defer` & `--state`** *(3)* — 2026-06-26, 08-07, 08-12
- **Slim CI** *(6)* — 2026-06-25, 06-30, 07-03, 07-16, 08-05, 08-20
- **CI/CD & Deployment** *(2)* — 2026-06-19, 07-25
- **Artifacts** *(6)* — 2026-06-27, 07-08, 07-11, 07-27, 08-08, 08-13

### Part XI — Advanced Topics and Operations

- **Python Models** *(3)* — 2026-06-29, 07-12, 08-10
- **Analyses** *(1)* — 2026-08-17
- **Debugging** *(5)* — 2026-07-15, 07-18, 07-25, 08-13, 08-19
- **Performance Tuning** *(4)* — 2026-06-30, 07-09, 07-11, 07-31
- **Data Quality Observability** *(1)* — 2026-05-31

### Sessions with no archive source

Added in the 2026 update from the official documentation and release notes.
Nothing in these sessions traces back to the daily notes:

| Session | Topic |
|---|---|
| 1.2 | The 2026 landscape: engines, distributions, release tracks |
| 3.3 | The `microbatch` strategy *(named once in the archive, never explained)* |
| 3.5 | Materialized views and dynamic tables |
| 4.4 | Linting: SQLFluff, pre-commit, `dbt lint` |
| 5.5 | User-defined functions |
| 5.6 | Custom materializations |
| 6.6 | Behaviour change flags and deprecations |
| 9.5 | `dbt clone` |
| 9.6 | Sample mode and `--empty` |
| 9.8 | Advanced CI |
| 9.9 | State-aware orchestration and dbt State |
| 10.1–10.3 | The dbt platform: Studio, Catalog, Insights, jobs, AI |
| 11.3 | Iceberg and `catalogs.yml` |
| 12.1–12.3 | Version strategy, deprecation cleanup, migrating to v2 |

Existing sessions revised with post-archive material are listed in
"The 2026 update" at the front of the book.

---

## Appendix F — Version Timeline: What Landed When

A quick index for "when did this become available?" Everything below is
dbt Core unless marked *(platform)*.

| Version / date | What shipped |
|---|---|
| **1.5** | Model contracts, model versions, access levels and groups |
| **1.6** | dbt Mesh — cross-project `ref()`, `dbt-loom`-style dependencies |
| **1.7** | Last manually selectable version on the platform |
| **1.8** | Unit tests; adapters decoupled from `dbt-core`; `--empty` |
| **1.9** | `microbatch`; YAML snapshots; `hard_deletes`; `dbt_valid_to_current`; `snapshot_meta_column_names`; Iceberg tables on Snowflake; data test `description`; unit test `enabled`; `state:modified` improvements |
| **1.10** | `--sample`; `catalogs.yml` parsing; `loaded_at_query`; `config.meta_get()` / `meta_require()`; `--use-fast-test-edges`; `anchors:` key; the deprecation wave (`--models`, custom top-level keys, properties → configs, `warn_error_options` renames) |
| **1.11** | **UDFs** as first-class resources; JSON-schema YAML validation on by default; `DBT_ENGINE_` env prefix; Snowflake `immutable_where` / `refresh_warehouse` / dynamic-table `cluster_by`; BigQuery batch source freshness; Redshift `datasharing` |
| **1.12** | Current stable (`1.12.3`); embedded Semantic Layer spec; `use_catalogs_v2`; JavaScript UDFs; UDF overloads; ships the Fusion-powered parser behind `--use-v2-parser` |
| **2.0** | Rust engine, Apache 2.0; alpha 2026-06-01, beta (`2.0.0b2`) August 2026. Parquet artifacts, language spec, no virtualenv, Docs v2 |

### Platform timeline (2026)

| When | What |
|---|---|
| January | State-aware orchestration *(private preview)*; new Semantic Layer YAML spec; Semantic Layer querying GA in Insights; Analyst agent *(beta)* |
| February | Advanced CI on Fusion; Profiles; Python UDFs on Fusion; Cost Insights *(private beta)* |
| March | dbt MCP server product-docs tools; new projects default to Fusion Stable on Snowflake/BigQuery/Databricks/Redshift; Spark on Fusion *(beta)* |
| April | Developer agent *(beta)*; DuckDB on Fusion *(beta)*; Fusion-aligned YAML validation in Studio |
| May | Cost Insights *(public beta)*; native private packages GA; `state:modified` detects UDF changes; Fusion + Snowflake GA |
| **June 1** | **Fivetran + dbt Labs merger completes.** dbt Core 2.0 *(alpha)*; `dbt lint` *(beta)*; Docs v2 *(preview)*; dbt State *(preview)*; `dbt login`; Wizard CLI *(public beta)* |
| July | Cost Insights GA (Snowflake, BigQuery, Databricks); hybrid jobs; Fusion built-in lint replaces SQLFluff in Fusion runs; `latest-fusion` becomes Fusion Stable everywhere |
| August | dbt Core 2.0 *(beta)*; `dbt state explain`; `compare_unrendered_code`; `allow_clones`; Semantic Layer GraphQL complexity limit now errors |
| **September 1** | Behaviour change flags reach maturity on the Latest track — plan for this |
| September | Snowflake default column-size increase (needs `dbt-snowflake >= 1.10.6`) |

### Renames to keep straight

| Was | Is |
|---|---|
| dbt Cloud | the dbt platform |
| Cloud IDE | Studio IDE |
| dbt Explorer | Catalog |
| dbt Copilot | dbt Wizard / agents |
| `measures:` (Semantic Layer) | `metrics:` with `type: simple` |
| `invalidate_hard_deletes` | `hard_deletes` |
| `target_schema` (snapshots) | `schema` |
| `warn_error_options: include/exclude` | `error` / `warn` / `silence` |
| `--models` / `-m` | `--select` / `-s` |
| `DBT_STATE`, `DBT_PROJECT_DIR` | `DBT_ENGINE_STATE`, `DBT_ENGINE_PROJECT_DIR` |

---

## Appendix G — Coverage Notes

**Topics the archive covers heavily** (>10 notes each): Model Contracts (46),
Snapshots (42), Incremental Models (26), Macros & Jinja (24), Packages (19),
Exposures (15), Hooks (13), Node Selection (12), Seeds (11), Tests (11), Unit
Tests (11), Semantic Layer (11).

**Topics the archive touches only once** — thin coverage, supplemented from the
official docs in this edition: Materializations, Ephemeral Models,
`on_schema_change`, `run-operation`, `run_query`/`execute`, Profiles & Targets,
`dbt build`, Analyses, Data Quality Observability.

### Gaps closed in the 2026 update

The first edition listed nine topics as absent from the archive. All are now
covered:

| Original gap | Now |
|---|---|
| dbt Cloud IDE and job scheduling specifics | Sessions 10.1, 10.2 |
| `dbt-core` upgrade/migration paths between minor versions | Sessions 12.1, 12.2 |
| SQLFluff / linting and pre-commit setup | Session 4.4 |
| Snapshot `dbt_valid_to_current` and YAML snapshot config (1.9+) | Session 3.6 |
| Microbatch incremental strategy in depth | Session 3.3 |
| Materialized views as a materialization | Sessions 1.4, 3.5 |
| Custom materializations | Session 5.6 |
| `dbt clone` | Session 9.5 |
| State-aware orchestration beyond Slim CI | Session 9.9 |

### Still thin, deliberately

- **Adapter-specific tuning** beyond Snowflake and BigQuery. Redshift, Databricks,
  Spark, DuckDB, and Postgres appear only where behaviour genuinely differs.
- **Elementary, re_data, and Monte Carlo** are named in Session 11.6 but not
  taught. They move faster than a book can track.
- **Airflow / Dagster / Prefect integration patterns.** Session 10.2 gives the
  shape; the orchestrator-specific detail belongs in that tool's documentation.
- **`dbt-fusion` internals.** Covered as a user, not as a contributor.
- **Apache Ossie** (the emerging open semantic interchange format, parsed from
  `osi/` since July 2026) is too new to teach usefully. Watch it.

### Where the currency risk is

The parts of this book most likely to be stale first, in order:

1. **Part XII** — v2 is in beta; adapter status and migration tooling move
   monthly.
2. **Part X** — the platform ships weekly and renames things.
3. **Session 9.9** — dbt State gained four configs in a single month.
4. **Session 11.3** — Iceberg catalog compatibility is genuinely unstable.

Parts I–VIII are the durable core. `ref()`, the DAG, layering, testing,
contracts, and incremental logic have not changed in years and are not about to.

---

*Assembled from 335 dbt sections across 91 daily notes (2026-05-31 →
2026-08-20), updated 2026-08-30 against dbt Core 1.12.3 / 2.0.0b2 and the
official dbt documentation and release notes.*
