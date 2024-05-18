import json
import pymysql

pymysql.install_as_MySQLdb()

with open('./config.json') as f:
    config = json.load(f)
db = pymysql.connect(**config)
cursor = db.cursor()
db.commit()
print(cursor)
