# Local SQL Testing

`run_sql.py` executes any `.sql` file in this repo against your Illuminate
Snowflake account, for local ad-hoc testing before committing a query.

## Setup (one time)

1. Install dependencies:
   ```
   pip install -r scripts/requirements.txt
   ```
2. Copy `.env.example` (repo root) to `.env` and fill in your values.
   `.env` is gitignored — it will never be committed.
   See [docs/Illuminate_Snowflake_Connection_Info.md](../docs/Illuminate_Snowflake_Connection_Info.md)
   for where to find each value in Illuminate.

## Usage

```
python scripts/run_sql.py SQL/unique_instructors_by_term.sql
python scripts/run_sql.py SQL/unique_instructors_by_term.sql --limit 20
```

Prints the result set (default: first 50 rows) as a simple text table.
