#!/usr/bin/env python3
"""
Run a .sql file from this repo against your Illuminate Snowflake account
for local testing. Credentials are read from a gitignored `.env` file
(never committed) — see .env.example for the required fields and
docs/Illuminate_Snowflake_Connection_Info.md for where to find them.

Usage:
    python scripts/run_sql.py SQL/unique_instructors_by_term.sql
    python scripts/run_sql.py SQL/unique_instructors_by_term.sql --limit 20
"""

import argparse
import os
import sys
from pathlib import Path

from dotenv import load_dotenv


REQUIRED_VARS = [
    "SNOWFLAKE_ACCOUNT",
    "SNOWFLAKE_USER",
    "SNOWFLAKE_PASSWORD",
    "SNOWFLAKE_WAREHOUSE",
    "SNOWFLAKE_DATABASE",
]


def load_config():
    load_dotenv()
    missing = [v for v in REQUIRED_VARS if not os.environ.get(v)]
    if missing:
        sys.exit(
            "Missing required environment variable(s): "
            + ", ".join(missing)
            + "\nCopy .env.example to .env and fill in your values."
        )
    return {
        "account": os.environ["SNOWFLAKE_ACCOUNT"],
        "user": os.environ["SNOWFLAKE_USER"],
        "password": os.environ["SNOWFLAKE_PASSWORD"],
        "warehouse": os.environ["SNOWFLAKE_WAREHOUSE"],
        "database": os.environ["SNOWFLAKE_DATABASE"],
        "role": os.environ.get("SNOWFLAKE_ROLE") or None,
    }


def print_results(cursor, limit):
    columns = [col[0] for col in cursor.description]
    rows = cursor.fetchmany(limit)

    widths = [len(c) for c in columns]
    str_rows = [[("" if v is None else str(v)) for v in row] for row in rows]
    for row in str_rows:
        for i, val in enumerate(row):
            widths[i] = max(widths[i], len(val))

    def fmt_row(vals):
        return " | ".join(v.ljust(widths[i]) for i, v in enumerate(vals))

    print(fmt_row(columns))
    print("-+-".join("-" * w for w in widths))
    for row in str_rows:
        print(fmt_row(row))

    total = len(rows)
    more = cursor.fetchone() is not None
    print(f"\n({total} row{'s' if total != 1 else ''} shown"
          + (", more available)" if more else ")"))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("sql_file", type=Path, help="Path to a .sql file in this repo")
    parser.add_argument("--limit", type=int, default=50, help="Max rows to display (default: 50)")
    args = parser.parse_args()

    if not args.sql_file.exists():
        sys.exit(f"SQL file not found: {args.sql_file}")

    import snowflake.connector

    config = load_config()
    sql_text = args.sql_file.read_text(encoding="utf-8")

    conn = snowflake.connector.connect(**config)
    try:
        cursors = conn.execute_string(sql_text)
        cursor = cursors[-1]
        if cursor.description:
            print_results(cursor, args.limit)
        else:
            print(f"Statement executed. Rows affected: {cursor.rowcount}")
    finally:
        conn.close()


if __name__ == "__main__":
    main()
