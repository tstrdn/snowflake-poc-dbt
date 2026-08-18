# snowflake-poc-dbt

The dbt project for the Snowflake platform, running natively in Snowflake via
dbt Projects on Snowflake. One of the two promotion pipelines in this proof of
concept — the other is
[`snowflake-poc-infrastructure`](../snowflake-poc-infrastructure), which
provisions the databases, warehouses and roles this project builds into.

## How a change reaches production

```
feature branch → PR (lint + build in ANALYTICS.PR_n) → merge → artifact → DEV (auto)
                                                                  ↓
                                                    Promote → TST (approval)
                                                                  ↓
                                                    Promote → PRD (approval)
```

The artifact is a tarball of the project with `dbt_packages/` vendored inside
it, published to Artifactory with a SHA256. **Every environment deploys that
same file**, and each deployment verifies the checksum before doing anything.
Promoting to production redeploys exactly the bytes that were tested.

Dependencies are resolved once, on the CI runner. `dbt deps` inside Snowflake
would need External Network Access, which trial accounts lack — and vendoring is
better practice regardless, since it stops a fixed version from quietly
resolving to different code later.

## Layout

```
models/staging/      stg_customers, stg_orders, stg_payments  (views)
models/marts/        customers, orders                        (tables)
seeds/               Jaffle Shop source data
macros/              generate_schema_name — keeps sandbox and CI builds isolated
tests/               singular tests beyond the schema tests
profiles.yml         deployed targets: dev, tst, prd, ci — deliberately no credentials
ci/profiles.yml      throwaway profile so dbt parse can run offline
dev/                 template for local development
deploy/*.version     which artifact version each environment runs
```

## Developing

See the [developer guide](../snowflake-poc-infrastructure/docs/developer-guide.md).
The short version:

```bash
pip install -r requirements-ci.txt
cp dev/profiles.yml.example dev/profiles.yml     # then fill it in
dbt deps
dbt build --profiles-dir dev --target sandbox
```

You build into `ANALYTICS.DBT_<YOURNAME>` in the development account. The
`generate_schema_name` macro collapses the staging and mart schemas into your
one schema for `sandbox` and `ci` targets, so your work cannot land in the
shared `JAFFLE_STG` or `JAFFLE_MARTS`.

Snowsight Workspaces is the alternative: a Git-connected browser IDE with no
local setup.

## Making a change

```bash
git checkout -b feature/add-customer-segments
# edit models/…
echo "0.2.0" > VERSION          # required: artifacts are immutable
git commit -am "feat: add customer segment model"
gh pr create --fill
```

The pull request lints and parses, then deploys your branch as
`JAFFLE_SHOP_PR_<n>` and runs a full `dbt build` — seeds, models and tests —
into a throwaway `ANALYTICS.PR_<n>` schema in the development account. Both are
dropped afterwards, and again when the pull request closes.

## The model

```
raw_customers ─┐
raw_orders   ──┼─→ stg_* (views) ─→ orders ─→ customers (tables)
raw_payments ──┘
```

`orders` pivots payment amounts by method, driven by the `payment_methods`
variable in `dbt_project.yml` — adding a method adds a column, with no SQL
change. Returned orders carry a zero payment, so they count towards order volume
but not towards customer lifetime value.

25 tests: uniqueness and not-null on every key, referential integrity between
layers, accepted values on enumerations, plus two singular tests — that the
pivoted payment columns sum back to the order total, and that no payment is
negative.
