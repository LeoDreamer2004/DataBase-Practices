import pymysql
from pymysql.cursors import Cursor
import pandas as pd
import json
from sqlalchemy import create_engine

URL = ""


def read_config(path: str) -> dict:
    """
    Read a json file and return a dictionary of configuration.
    """
    with open(path) as f:
        return json.load(f)


def fetch_cursor(cursor: Cursor):
    """
    Combine the description and data by pymysql to a list of dictionary.
    >>> cursor.description
    (('id', 3, None, 11, 11, 0, False), ('name', 253, None, 255, 255, 0, False))
    >>> cursor.fetchall()
    ((1, 'Alice'), (2, 'Bob'))
    >>> fetch_cursor(cursor)
    [{'id': 1, 'name': 'Alice'}, {'id': 2, 'name': 'Bob'}]
    """
    description = cursor.description
    data = cursor.fetchall()
    return [dict(zip([x[0] for x in description], row)) for row in data]


def set_URL(config: dict):
    global URL
    user = config["user"]
    password = config["password"]
    host = config["host"]
    port = config["port"]
    database = config["db"]
    URL = f"mysql+pymysql://{user}:{password}@{host}:{port}/{database}"


def csv2sql(file_path: str, table_name: str):
    """
    Read a csv file and write it to a table in the database.
    Use `csv2sql_submission()` instead to write the submission table.
    Use `csv2sql_IOpair()` instead to write the IOpair table.
    """
    if URL == "":
        raise ValueError("Please set the URL first.")
    engine = create_engine(URL)
    df = pd.read_csv(file_path)
    df.to_sql(table_name, engine, if_exists="append", index=False)


if __name__ == "__main__":
    pymysql.install_as_MySQLdb()
    config = read_config("./config.json")
    db = pymysql.connect(**config)
    cursor = db.cursor()
    set_URL(config)
    db.commit()
