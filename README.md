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

