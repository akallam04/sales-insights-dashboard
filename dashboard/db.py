"""
dashboard/db.py
---------------
SQLAlchemy connection helper.

Usage
-----
    from dashboard.db import get_engine, query

    df = query("SELECT * FROM sales_cleaned LIMIT 100")

The engine is created once per process (module-level singleton) so that
Streamlit's hot-reload and the notebook don't spin up a new connection pool
on every import.

Environment variables (loaded from .env via python-dotenv):
    DB_HOST     — default: localhost
    DB_PORT     — default: 3306
    DB_USER     — default: root
    DB_PASSWORD — default: (empty)
    DB_NAME     — default: sales
"""

from __future__ import annotations

import os
from urllib.parse import quote_plus

import pandas as pd
from dotenv import load_dotenv
from sqlalchemy import create_engine, text
from sqlalchemy.engine import Engine

# Load .env from the project root (works whether you run from root or a subdir)
load_dotenv()


def _build_engine() -> Engine:
    host = os.getenv("DB_HOST", "localhost")
    port = os.getenv("DB_PORT", "3306")
    user = os.getenv("DB_USER", "root")
    password = os.getenv("DB_PASSWORD", "")
    db_name = os.getenv("DB_NAME", "sales")

    # quote_plus encodes special characters (@ $ ! etc) so the URL parses correctly
    url = f"mysql+pymysql://{quote_plus(user)}:{quote_plus(password)}@{host}:{port}/{db_name}"
    return create_engine(url, pool_pre_ping=True)


# Module-level singleton — created once on first import
_engine: Engine = _build_engine()


def get_engine() -> Engine:
    """Return the shared SQLAlchemy engine."""
    return _engine


def query(sql: str, params: dict | None = None) -> pd.DataFrame:
    """
    Execute *sql* and return results as a Pandas DataFrame.

    Parameters
    ----------
    sql    : Raw SQL string (SELECT only — this helper is read-only by convention).
    params : Optional dict of bind parameters, e.g. {"year": 2020}.

    Example
    -------
    >>> df = query("SELECT * FROM sales_cleaned WHERE year = :year", {"year": 2020})
    """
    with _engine.connect() as conn:
        return pd.read_sql(text(sql), conn, params=params or {})
