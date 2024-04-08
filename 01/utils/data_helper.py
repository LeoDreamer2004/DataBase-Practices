def fetch_cursor(cursor):
    """
    Combine the description and data by pymysql to a list of dictionary.
    >>> a = cursor.description
    >>> a
    (('id', 3, None, 11, 11, 0, False), ('name', 253, None, 255, 255, 0, False))
    >>> b = cursor.fetchall()
    >>> b
    ((1, 'Alice'), (2, 'Bob'))
    >>> build_lines_data(cursor)
    [{'id': 1, 'name': 'Alice'}, {'id': 2, 'name': 'Bob'}]
    """
    description = cursor.description
    data = cursor.fetchall()
    return [dict(zip([x[0] for x in description], row)) for row in data]
