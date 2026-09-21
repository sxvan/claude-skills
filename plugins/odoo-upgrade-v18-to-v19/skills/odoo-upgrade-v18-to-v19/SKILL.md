---
name: odoo-upgrade-v18-to-v19
description: Upgrade Odoo modules from version 18.0 to version 19.0. Use it when a module, manifest, model, view, controller, or test written for Odoo 18 has to run on Odoo 19, or when the user asks what changed in the ORM between the two versions.
---

# Odoo upgrade, 18.0 to 19.0

Covers the ORM changes released in 18.1, 18.2, 18.3, 18.4 (Odoo Online) and 19.0, plus the 18.0 changes a module written for 17 may still be missing. Each item is tagged with the version that introduced it.

## Check whether 19.0 already does it

Before porting anything, compare what the module adds against the functional release notes: https://www.odoo.com/odoo-19-release-notes. A custom module often exists to fill a gap that the new version closes, and the cheapest migration is the one where the module is dropped or reduced to the part Odoo still does not cover.

The page is grouped by app, with `General` and `Technical` sections for cross-app changes. Read the sections matching the apps in the module's `depends`, then say plainly which of the module's features are now native, which are partly covered and need the module trimmed, and which are untouched. Leave the decision to drop a module to the user.

## Run the automatic rewrites first

Odoo ships source-rewriting scripts in `odoo/upgrade_code`:

```
$ odoo-bin upgrade_code --from 18.0 --to 19.0 --dry-run
$ odoo-bin upgrade_code --from 18.0 --to 19.0
```

They cover `_sql_constraints`, `type='json'`, `self._cr`/`_uid`/`_context`, dynamic dates in domains, and two l10n data changes. They are best-effort regex and AST rewrites, so read the diff. Everything below is what they do not catch.

## Breaks silently

Two changes produce no error and no failing import. Grep for both before anything else.

**`_sql_constraints` is no longer read (18.1, enforced 19.0).** The model builder logs a warning and the constraint is never created. Declare table objects as class attributes whose name starts with `_`:

```python
class AModel(models.Model):
    _name = 'a.model'
    _my_check = models.Constraint("CHECK (x > y)", "x > y is not true")
    _name_idx = models.Index("(last_name, first_name)")
    _code_uniq = models.UniqueIndex("(code)")
```

The ORM now creates and drops indexes as well as constraints. The second argument is the error message; it can be a string, or a function `(env, diag)` returning one, where `diag` is the psycopg diagnostics.

**`_name_search` no longer exists on `Model` (18.0).** An override of it is dead code. Searching by name goes through the `display_name` field like any other field:

```python
@api.model
def _search_display_name(self, operator, value):
    return Domain('partner_id.ref', operator, value)
```

`name_search` stays as the public method and now only holds the record-limiting logic.

## Deprecated, still working

These raise a `DeprecationWarning` in 19.0 and will be removed later.

| 18.0 code | 19.0 code | Since |
| --- | --- | --- |
| `self._cr`, `self._uid`, `self._context` | `self.env.cr`, `self.env.uid`, `self.env.context` | 19.0 |
| `from odoo.osv import expression` | `from odoo.fields import Domain` | 19.0 |
| `expression.AND(...)`, `expression.OR(...)` | `Domain.AND(...)`, `Domain.OR(...)` | 19.0 |
| `expression.TRUE_DOMAIN`, `FALSE_DOMAIN` | `Domain.TRUE`, `Domain.FALSE` | 19.0 |
| `expression.expression(...)` | `Domain` or `_search` | 19.0 |
| `read_group(...)` | `_read_group(...)` or `formatted_read_group(...)` | 18.2 |
| `check_access_rights`, `check_access_rule` | `check_access(operation)` | 18.0 |
| `_filter_access_rules`, `_filter_access_rules_python` | `_filtered_access(operation)` | 18.0 |
| `_("...")` from `odoo.tools` | `self.env._("...")` | 18.0 |

`check_access(operation)` checks access rights and record rules together, works on an empty recordset, and raises `AccessError`. `has_access(operation)` returns a bool instead. `_filtered_access(operation)` returns the accessible subset, empty when the model itself is forbidden.

`self.env._` resolves the language from the environment instead of inspecting the call stack, and the module from the caller's package. For strings defined outside a method, use the lazy factory once per file:

```python
from odoo.tools import LazyTranslate
_lt = LazyTranslate(__name__)
LAZY_TEXT = _lt("some text")
```

## read_group (18.2)

`_read_group` is the backend method and returns a list of tuples. `formatted_read_group` lives in the `web` module and returns a list of dicts for the client. Both take the same arguments in the same order:

```python
formatted_read_group(domain, groupby=(), aggregates=(), having=(), offset=0, limit=None, order=None)
```

Differences from `read_group`:

- `groupby` and `fields` swapped position, and `fields` became `aggregates`.
- `having` was added, `orderby` became `order`.
- `lazy` is gone. Both methods always behave as `lazy=False` and no longer return `__context`.
- Aggregates must be spelled out, including `__count`. `Field.aggregator` is only used by the web client now. The result key is the aggregate specification itself, so `__count` is always named `__count`.
- The `name:aggregator(field)` renaming syntax is gone.
- Groups carry `__extra_domain` for the group instead of repeating the full domain.

An override of `read_group` no longer covers list, kanban or pivot views. Move the logic to `_read_group` when it is about the query, or to `formatted_read_group` when it is about the client payload.

## Pivot grouping sets (19.0)

A pivot view used to issue one `formatted_read_group` call per row and column combination. It now issues a single `formatted_read_grouping_sets(domain, grouping_sets, aggregates=(), order=None)` call, backed by `_read_grouping_sets` and PostgreSQL `GROUPING SETS`. An override of `formatted_read_group` written for a pivot view has to be repeated on the grouping-sets methods.

## Domains

**The `Domain` object (18.1).** Import it from `odoo.fields`. It parses lists, combines with Python operators, and serializes back to a list:

```python
from odoo.fields import Domain

d = Domain('name', '=', 'ABC') & (
    Domain('phone', 'ilike', '7620') | Domain('mobile', 'ilike', '7620')
)
~d                       # not
Domain.AND([d1, d2])     # and Domain.OR
Domain.TRUE              # and Domain.FALSE
list(d)                  # back to the list form
```

Lists still work everywhere a domain is accepted. Use `Domain` for anything built conditionally, and drop the hand-rolled `['&', ...]` prefix juggling.

**Date part conditions (17.3).** `field.granularity` compares an integer part of a date: `year_number`, `quarter_number`, `month_number`, `iso_week_number`, `day_of_week`, `day_of_month`, `day_of_year`, `hour_number`, `minute_number`, `second_number`.

```python
Domain('birthday.month_number', '=', 2)
```

**Dynamic dates (19.0).** For `Date` and `Datetime` fields the value can be a string relative to now in the user's timezone, which removes most `relativedelta` and `context_today` use in domains. Terms are space-separated: an optional leading `today` or `now`, then `+`, `-` or `=` followed by an integer and a unit (`d w m y H M S`) or a lowercase weekday.

```python
Domain('some_date', '<', 'now')
Domain('some_date', '<', '-3d +1H')     # now minus 3 days plus 1 hour
Domain('some_date', '<', '=3H')         # today at 3:00:00
Domain('some_date', '>=', '=monday -1w')  # Monday of the previous week
```

`=` sets the unit and zeroes the smaller ones. For weekdays, `+` and `-` mean next and previous, `=` means the current week starting Monday.

**Custom SQL (18.4).** Passing an `SQL` object as a condition value is deprecated. Use a custom domain, which gets the model, the table alias and the query:

```python
Domain.custom(to_sql=lambda model, alias, query: SQL(...), predicate=lambda record: ...)
```

`predicate` is used when the domain filters records in memory rather than in SQL.

**`inselect` is gone (17.4).** Use `in` with a `Query` or `SQL` value.

## Field search methods (18.3)

The ORM optimizes the domain before calling a field's `search` method, so the method sees far fewer shapes than before:

- Every `=` has become `in`. Handle `in`, not `=`.
- Boolean fields are always called with `in` or `not in` and `[True]`.
- Return `NotImplemented` for an operator you do not support. The ORM retries with an equivalent operator, and for an unsupported negative operator it calls the positive one and complements the result itself.

```python
def _search_upper(self, operator, value):
    if operator not in ('in', 'like'):
        return NotImplemented
    return Domain('name', operator, value)
```

## Controllers (18.1)

`type='json'` became `type='jsonrpc'`. The route behaves the same; only the Python argument changed. For code that has to run on both versions:

```python
@route(type=odoo.http.JsonRPCDispatcher.routing_type)
```

## RPC surface (18.2)

ORM utility methods without an underscore prefix (`browse`, `fetch`, `search_fetch` and others) are marked `@api.private` and can no longer be called over RPC. Check external integrations, not module code; Python calls are unaffected. Use `@api.private` on your own existing public methods when you need to close them to RPC without renaming them, and keep prefixing new non-public methods with `_`.

## Crons (18.3)

A cron function should process one batch and report progress. The framework commits after each batch and calls the function again until the work is done. Do not reschedule the job yourself.

```python
def _cron_do_something(self, *, limit=300):
    domain = [('state', '=', 'ready')]
    records = self.search(domain, limit=limit)
    records.do_something()
    remaining = 0 if len(records) == limit else self.search_count(domain)
    self.env['ir.cron']._commit_progress(len(records), remaining=remaining)
```

`_commit_progress(processed=0, *, remaining=None, deactivate=False)` returns the seconds left for the run. When it returns 0, return as soon as possible. Use it inside a manual loop when a batch shares a resource such as an open connection.

## Demo data (18.3)

Demo data is no longer loaded by default. `--with-demo` opts in, and `config['without_demo']` is replaced by `config['with_demo']`. `--without-demo` still works as an inverted alias. Any test that reads a demo record fails on a fresh database; build the records the test needs.

## CLI (18.4)

`--reinit <modules>` reinitializes installed modules: no migration scripts, data loaded in `init` mode, and every module depending on them reinitialized too. `-i` on an installed module does nothing.

## Packaging (18.2, 19.0)

`odoo` uses PEP 420 native namespace packages, and the code that lived in `odoo/__init__.py` moved to `odoo.init`. In 19.0 the ORM was split into `odoo.orm.*`, with `odoo.models`, `odoo.fields` and `odoo.api` kept as packages that re-export it.

`from odoo import models, fields, api` is unchanged, and so are the documented names on those packages (`models.Model`, `models.BaseModel`, `models.TransientModel`, `fields.Domain`, `api.Environment`). Code that loads `odoo/models.py` or `odoo/fields.py` by file path, or imports a helper that is not re-exported, has to be repointed at the matching `odoo.orm` module.

---

# OCA migration checklist

A second, separate pass, taken from the OCA guide for version 19.0: https://github.com/OCA/maintainer-tools/wiki/Migration-to-version-19.0. It lists framework changes only. Data-model changes per core module are covered separately below. Items here overlapping the sections above are kept as written.

## Module housekeeping

- Bump the module version to `19.0.1.0.0`.
- Delete the `migrations` folder if the module has one, along with any migration script from the previous version.
- Drop references in `CREDITS.rst` to past migrations financed by other companies.
- Do not change the copyright year and do not change the original authors. `# Copyright 2024 ACME Ltd` means "copyright from 2024".

## Security and views

- `res.groups.category_id` is gone, replaced by `privilege_id` pointing at the new model `res.groups.privilege`. A module defining its own permission section has to create the privilege record too. See odoo/odoo@33637d1.
- Rename the `groups_id` field to `group_ids` wherever views, menus, actions or reports reference it. The affected models are `res.users`, `ir.ui.view`, `ir.ui.menu`, `ir.actions`, `ir.actions.report` and `website.page.properties`. See odoo/odoo#179354.
- Remove the `string` and `expand` attributes from `<group>` tags in search views. See odoo/odoo#220023.

## Python API

- `self._cr` becomes `self.env.cr`, `self._uid` becomes `self.env.uid`, `self._context` becomes `self.env.context`.
- Replace `odoo.osv.expression` with `odoo.fields.Domain`. See odoo/odoo#217708.
- Replace the `_sql_constraints` list with attributes holding `models.Constraint` or `models.Index`. See odoo/odoo#175783.
- Replace manual timezone handling (pytz, `self.env.context.get("tz")`) with `self.env.tz`. See odoo/odoo#221541.
- On field definitions, `auto_join` is renamed `bypass_search_access`. See odoo/odoo#219627.
- Replace `read_group` with `_read_group` for backend code or `formatted_read_group` for a public call. See odoo/odoo#163300.
- In controllers, `type="json"` becomes `type="jsonrpc"` on `@route`. See odoo/odoo#183636.
- Import `SUPERUSER_ID` from `odoo.api`, not from `odoo` itself. See odoo/odoo@d6a955f.
- Replace `@ormcache_context` with plain `@ormcache`, passing the context keys as parameters read from `self.env.context.get("key")`. See odoo/odoo#220725.
- Replace `urljoin` from `urllib.parse` with `odoo.tools.urls.urljoin`, which covers more cases. See odoo/odoo@977e62d.
- Rename the `args` parameter to `domain` in `name_search` overrides. See odoo/odoo@e35bced.
- Remove the `@api.returns` decorator and adapt any caller that relied on it. See odoo/odoo#182709.
- Replace `toggle_active` calls with the explicit `action_archive` or `action_unarchive`. See odoo/odoo#183691.
- Consider adding `@api.private` to public methods that should not be reachable over the external API. See odoo/odoo#195402.

## Domains

- A search method on a computed non-stored field should return a `Domain` object rather than a list. See odoo/odoo@4f0d467.
- When such an override inspects `operator` and `value`, expect the optimizer to have rewritten them. `model.search([("boolean_field", "=", True)])` reaches `_search_boolean_field` with the operator `in` and the value `OrderedSet([True])`, not `=` and `True`.
- Elsewhere, `Domain` objects can replace list domains in searches, `filtered_domain` and similar, for clearer syntax and better optimization. See odoo/odoo#170009 and OCA/commission#646.
- Dynamic date parameters are available in domains. See odoo/odoo#216665.

## Tests

- Demo data is no longer installed by default, and Odoo advises against relying on it. Build the records the test needs in the test itself.
- Disable tracking across the test env with `cls.env = cls.env(context=dict(cls.env.context, tracking_disable=True))`, or use `BaseCommon` as the base class when the test needs company, currency, user or group setup.
- Fake models no longer need the `odoo-test-helper` library. Load them natively:

```python
from odoo.orm.model_classes import add_to_registry

@classmethod
def setUpClass(cls):
    ...
    from .fake_models import FakeModel
    add_to_registry(cls.registry, FakeModel)
    cls.registry._setup_models__(cls.env.cr, ["fake.model"])
    cls.registry.init_models(cls.env.cr, ["fake.model"], {"models_to_check": True})
    cls.addClassCleanup(cls.registry.__delitem__, "fake.model")
```

- Add tests to increase coverage.

## Squashing and multi-version jumps

- When migrating across several versions, work through each intermediate "Migration to version XX.0" guide in order, not only this one.
- Administrative commits can be squashed into the preceding commit to reduce noise. See https://github.com/OCA/maintainer-tools/wiki/Merge-commits-in-pull-requests.

---

# Data-model changes in core modules

The sections above cover framework changes. Field renames, removals and retypes inside the core modules are listed per module in the `upgrade_analysis.txt` files of https://github.com/OCA/OpenUpgrade. Look them up whenever the module reads or writes a field it does not define itself, and before concluding that a field is gone.

Do not guess the URL. The path carries the core module's target version, as in `openupgrade_scripts/scripts/sale/19.0.1.2/upgrade_analysis.txt`, and a bot bumps it whenever that module's version changes. Resolve it from the branch:

```
$ python3 references/openupgrade_analysis.py --manifest path/to/__manifest__.py
$ python3 references/openupgrade_analysis.py sale stock
$ python3 references/openupgrade_analysis.py --list
```

The script reads `depends` from the manifest, resolves each dependency's current path through the GitHub tree API for the `19.0` branch, and prints the files. It needs network access and nothing beyond the standard library. A dependency with no file is either unchanged or not a core module.

Each file has three sections. `Models` names obsolete models. `Fields` gives one line per change, in the form `module / model / field (type) : NEW|DEL` plus the relation, default and selection keys. `XML records` lists added and deleted data records, which is where renamed `ir.model.access` entries and moved config parameters show up.

```
sale / sale.order.line / product_uom (many2one)    : DEL relation: uom.uom
sale / sale.order.line / product_uom_id (many2one) : NEW relation: uom.uom, hasdefault: compute
sale / sale.order.line / tax_id (many2many)        : DEL relation: account.tax
sale / sale.order.line / tax_ids (many2many)       : NEW relation: account.tax, hasdefault: compute
```

A `DEL` and a `NEW` of the same shape on one model is almost always a rename, as with `product_uom` and `tax_id` above, but the file does not say so. Confirm against the 19.0 source before rewriting a reference to the field.

## Reference

- ORM changelog: https://www.odoo.com/documentation/19.0/developer/reference/backend/orm/changelog.html
- OCA migration guide: https://github.com/OCA/maintainer-tools/wiki/Migration-to-version-19.0
- OpenUpgrade analysis files: https://github.com/OCA/OpenUpgrade
- Odoo 19 functional release notes: https://www.odoo.com/odoo-19-release-notes
