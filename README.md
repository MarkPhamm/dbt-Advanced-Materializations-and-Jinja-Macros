# dbt-Advanced-Materializations  

## Tables  
When using the ```table``` materialization, your model is rebuilt as a table on each run, via a ```create table``` as statement.

- Built as tables in the database  
- Data is stored on disk  
- Slower to build  
- Faster to query  

**Pros:**  
- Tables are fast to query

**Cons:**  
- Tables can take a long time to rebuild, especially for complex transformations  
- New records in underlying source data are not automatically added to the table  

**Advice:**  
- Use the table materialization for any models being queried by BI tools to provide a faster experience for end users  
- Use table materialization for slower transformations that are used by many downstream models  

**Configuration:**  
Configure in `dbt_project.yml` or with the following config block:  
```jinja
{{ config(
    materialized='table'
) }}
```

---

## Views 
When using the ```view``` materialization, your model is rebuilt as a view on each run, via a   ```create view as``` statement.

- Built as views in the database  
- Query is stored on disk  
- Faster to build  
- Slower to query  

**Pros**
- No additional data is stored; views on top of source data will always have the latest records.
  
**Cons**
- Views that perform significant transformations or are stacked on top of other views can be slow to query.
  
**Advice**
- Generally, start with views for your models and only switch to another materialization when you notice performance issues.
- Views are best suited for models that do not involve significant transformations, such as renaming or recasting columns.

**Configuration:**  
Configure in `dbt_project.yml` or with the following config block:  
```jinja
{{ config(
    materialized='view'
) }}
```

---

## Ephemeral Models  
```ephemeral``` models are not directly built into the database. Instead, dbt will interpolate the code from an ephemeral model into its dependent models using a common table expression (CTE). You can control the identifier for this CTE using a model alias, but dbt will always prefix the model identifier with ```__dbt__cte__```.

- Does not exist in the database  
- Imported as CTE into downstream models  
- Increases build time of downstream models  
- Cannot be queried directly  
 
**Pros:**  
- You can still write reusable logic  
- Ephemeral models help keep your data warehouse clean by reducing clutter (also consider splitting your models across multiple schemas by using custom schemas)

**Cons:**  
- You cannot select directly from this model  
- Operations (e.g., macros called using `dbt run-operation`) cannot `ref()` ephemeral nodes  
- Overuse of ephemeral materialization can make queries harder to debug  
- Ephemeral materialization doesn't support model contracts  

**Advice:**  
Use the ephemeral materialization for:  
- Very light-weight transformations that are early on in your DAG  
- Models that are only used in one or two downstream models  
- Models that do not need to be queried directly  

**Configuration:**  
Configure in `dbt_project.yml` or with the following config block:  
```jinja
{{ config(
    materialized='ephemeral'
) }}
```

---
## Materialized views

The `materialized_view` materialization allows the creation and maintenance of materialized views in the target database. Materialized views are a combination of a view and a table, and serve use cases similar to incremental models.

**Pros:**  
- Materialized views combine the query performance of a table with the data freshness of a view  
- Materialized views operate much like incremental materializations, but they can usually be refreshed automatically on a regular cadence (depending on the database), without manual intervention—avoiding the regular dbt batch refresh required with incremental models  
- `dbt run` on materialized views corresponds to a code deployment, just like views  

**Cons:**  
- Materialized views are more complex database objects, so database platforms tend to have fewer configuration options available; check your database platform's docs for more details  
- Materialized views may not be supported by every database platform  

**Advice:**  
Consider materialized views for use cases where incremental models are sufficient, but you want the data platform to manage the incremental logic and refresh automatically.  

**Configuration:**  
Configure in `dbt_project.yml` or with the following config block:  
```jinja
{{ config(
    materialized='materialized_view'
) }}
```

## Incremental Models  
- Built as a table in the database  
- On the first run, builds the entire table  
- On subsequent runs, only appends new records*  
- Faster to build because only new records are added  
- Does not capture 100% of the data all the time  

**Configuration:**  
Incremental models require more advanced configuration. Consult the [dbt documentation](https://docs.getdbt.com/docs/build/incremental-models) for guidance on building your first incremental model.  

---

## Snapshots  
- Built as a table in the database, usually in a dedicated schema  
- On the first run, builds the entire table and adds four columns:  
  - `dbt_scd_id`, `dbt_updated_at`, `dbt_valid_from`, `dbt_valid_to`  
- In future runs, dbt will scan the underlying data and append new records based on the defined configuration  
- Allows capturing historical data  

**Configuration:**  
Snapshots require more advanced configuration. Consult the [dbt documentation](https://docs.getdbt.com/docs/build/snapshots) for guidance on writing your first snapshot.  

# Jinja

## Overview

Jinja is a templating language written in the Python programming language. Jinja is used in dbt to write functional SQL. For example, we can write a dynamic pivot model using Jinja.

## Jinja Basics

The best place to learn about leveraging Jinja is the [Jinja Template Designer documentation](https://jinja.palletsprojects.com/).

There are three Jinja delimiters to be aware of in Jinja:

- `{% … %}` is used for statements. These perform any function programming such as setting a variable or starting a for loop.
- `{{ … }}` is used for expressions. These will print text to the rendered file. In most cases in dbt, this will compile your Jinja to pure SQL.
- `{# … #}` is used for comments. This allows us to document our code inline. This will not be rendered in the pure SQL that you create when you run `dbt compile` or `dbt run`.

A few helpful features of Jinja include dictionaries, lists, if/else statements, for loops, and macros.

### Dictionaries
Dictionaries are data structures composed of key-value pairs.

```jinja
{% set person = {
    'name': 'me',
    'number': 3
} %}

{{ person.name }}
```
**Output:**
```
me
```
```jinja
{{ person['number'] }}
```
**Output:**
```
3
```

### Lists
Lists are data structures that are ordered and indexed by integers.

```jinja
{% set self = ['me', 'myself'] %}

{{ self[0] }}
```
**Output:**
```
me
```

### If/Else Statements
If/else statements are control statements that make it possible to provide instructions for a computer to make decisions based on clear criteria.

```jinja
{% set temperature = 80.0 %}

On a day like this, I especially like

{% if temperature > 70.0 %}

a refreshing mango sorbet.

{% else %}

A decadent chocolate ice cream.

{% endif %}
```
**Output:**
```
On a day like this, I especially like

a refreshing mango sorbet
```

### For Loops
For loops make it possible to repeat a code block while passing different values for each iteration through the loop.

```jinja
{% set flavors = ['chocolate', 'vanilla', 'strawberry'] %}

{% for flavor in flavors %}

Today I want {{ flavor }} ice cream!

{% endfor %}
```
**Output:**
```
Today I want chocolate ice cream!

Today I want vanilla ice cream!

Today I want strawberry ice cream!
```

### Macros
Macros are a way of writing functions in Jinja. This allows us to write a set of statements once and then reference those statements throughout your codebase.

```jinja
{% macro hoyquiero(flavor, dessert = 'ice cream') %}

Today I want {{ flavor }} {{ dessert }}!

{% endmacro %}

{{ hoyquiero(flavor = 'chocolate') }}
```
**Output:**
```
Today I want chocolate ice cream!
```
```jinja
{{ hoyquiero('mango', 'sorbet') }}
```
**Output:**
```
Today I want mango sorbet!
```

## Whitespace Control
We can control for whitespace by adding a single dash on either side of the Jinja delimiter. This will trim the whitespace between the Jinja delimiter on that side of the expression.


## Intermediate Macro Macros

Macros are functions that are written in Jinja. This allows us to write generic logic once, and then reference that logic throughout our project.  

Consider the case where we have three models that use the same logic. We could copy-paste the logic between those three models. If we want to change that logic, we need to make the change in three different places.  

Macros allow us to write that logic once in one place and then reference that logic in those three models. If we want to change the logic, we make that change in the definition of the macro, and this is automatically used in those three models.  

### DRY Code  
Macros allow us to write DRY (Don’t Repeat Yourself) code in our dbt project. This allows us to take one model file that was 200 lines of code and compress it down to 50 lines of code. We can do this by abstracting away the logic into macros.  

### Tradeoff  
As you work through your dbt project, it is important to balance the readability/maintainability of your code with how concise (or DRY) your code is. Always remember that you are not the only one using this code, so be mindful and intentional about where you use macros.  

---

## Macro Example: Cents to Dollars  

### Original Model:  
```sql
select
    id as payment_id,
    orderid as order_id,
    paymentmethod as payment_method,
    status,
    -- amount stored in cents, convert to dollars
    amount / 100 as amount,
    created as created_at
from {{ source('stripe', 'payment') }}
```

### New Macro:  
```jinja
{% macro cents_to_dollars(column_name, decimal_places=2) -%}
round( 1.0 * {{ column_name }} / 100, {{ decimal_places }})
{%- endmacro %}
```

### Refactored Model:  
```sql
select
    id as payment_id,
    orderid as order_id,
    paymentmethod as payment_method,
    status,
    -- amount stored in cents, convert to dollars
    {{ cents_to_dollars('payment_amount') }} as amount,
    created as created_at
from {{ source('stripe', 'payment') }}
```


## Packages

Packages are a tool for importing models and macros into your dbt project. These may have been written by a coworker or someone else in the dbt community that you have never met. Fishtown Analytics maintains a site called [hub.getdbt.com](https://hub.getdbt.com) for sharing open-source packages that you can install in your project. Packages can also be imported directly from GitHub, GitLab, another site, or from a subfolder in your dbt project.

## Installing Packages

Packages are configured in the root of your dbt project in a file called `packages.yml`.  
You can adjust the version to be compatible with your working version of dbt. Read the package documentation to determine the appropriate version.  

Packages are then installed with the command:

```sh
dbt deps
```

**Example:** Adding `dbt_utils` and `snowflake_spend` to your dbt project

**packages.yml**
```yaml
packages:
  - package: dbt-labs/dbt_utils
    version: 0.7.1
  - package: gitlabhq/snowflake_spend
    version: 1.2.0
```

After defining your packages, install them by running:

```sh
dbt deps
```

## Using Macros from a Package

After importing a package, your dbt project has access to all macros from that package.  
The documentation of the specific package is the best place to learn how to use its macros.  

When referencing a macro from a package, you must specify the package name followed by the macro name.  
For example, referencing the `dbt_utils` package and using the `date_spine` macro:

```jinja
{{ dbt_utils.date_spine(
    datepart="day",
    start_date="to_date('01/01/2016', 'mm/dd/yyyy')",
    end_date="dateadd(week, 1, current_date)"
) }}
```

## Using Models from a Package

After importing a package, your dbt project has access to all models from that package.  
The documentation of the specific package is the best place to learn how to use its models.  

Those models become part of your dbt project and will be built when you run:

```sh
dbt run
```

They can also be viewed in the documentation as part of your DAG and text-based documentation.

## Advance Jinja and Macro

### Grant Permissions Macro  

Macros allow us to run queries against the database. Dave’s example demonstrates how to use a macro to execute multiple permission statements in a parameterized way, leveraging the following dbt-specific Jinja functions:

- **run_query**  
  Runs queries and fetches results. It wraps around the statement block, providing a convenient interface.
  
- **log**  
  Logs messages to dbt logs. Using `default=True` also logs messages to the command line interface.
  
- **target**  
  Stores connection details for the warehouse, including `profile_name`, `name`, `schema`, `type`, and `threads`.

---

### Union by Prefix Macro  

This macro demonstrates how to use query results to template SQL in a model file. Dave’s example showcases the use of:

- **execute**  
  A boolean variable that is `true` during dbt execution, useful for conditional execution.
  
- **agate file types**  
  The result of `run_query` is stored in an `agate` table, similar to a Pandas DataFrame in Python.
  
- **get_relations_by_prefix**  
  Available via `dbt_utils`, this macro retrieves relations with a specified prefix.

---

### Clean Stale Models Macro  

Dave illustrates how to clean up stale models in his development schema using:

- The **information schema** in Snowflake (replicable on other platforms)
- A macro that identifies models not modified in the past 7 days

For more details, read the Discourse post on cleaning old and deprecated models.