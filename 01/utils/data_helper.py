from pymysql.cursors import Cursor
import pandas as pd
from sqlalchemy import create_engine


def fetch_cursor(cursor: Cursor):
    """
    Combine the description and data by pymysql to a list of dictionary.
    >>> a = cursor.description
    >>> a
    (('id', 3, None, 11, 11, 0, False), ('name', 253, None, 255, 255, 0, False))
    >>> b = cursor.fetchall()
    >>> b
    ((1, 'Alice'), (2, 'Bob'))
    >>> fetch_cursor(cursor)
    [{'id': 1, 'name': 'Alice'}, {'id': 2, 'name': 'Bob'}]
    """
    description = cursor.description
    data = cursor.fetchall()
    return [dict(zip([x[0] for x in description], row)) for row in data]


URL = "mysql+pymysql://practice:123456@127.0.0.1:3306/practice1"


def csv2sql(file_path: str, table_name: str):
    """
    Read a csv file and write it to a table in the database.
    Use `csv2sql_submission()` instead to write the submission table.
    """
    engine = create_engine(URL)
    df = pd.read_csv(file_path)
    df.to_sql(table_name, engine, if_exists="append", index=False)


def csv2sql_submission(file_path: str, table_name: str):
    engine = create_engine(URL)
    df = pd.read_csv(file_path)
    df["code"] = df["codefile"].apply(lambda x: open("data/code/" + x).read())
    del df["codefile"]
    df.to_sql(table_name, engine, if_exists="append", index=False)


def csv2sql_IOpair(file_path: str, table_name: str):
    engine = create_engine(URL)
    df = pd.read_csv(file_path)
    df["input"] = df["iofile"].apply(lambda x: open("data/test_io/" + x + ".in").read())
    df["output"] = df["iofile"].apply(lambda x: open("data/test_io/" + x + ".out").read())
    del df["iofile"]
    df.to_sql(table_name, engine, if_exists="append", index=False)
