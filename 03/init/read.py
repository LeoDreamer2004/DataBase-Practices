import json
import pymysql
from data_helper import *

pymysql.install_as_MySQLdb()

with open("./config.json") as f:
    config = json.load(f)
db = pymysql.connect(**config)
cursor = db.cursor()

setURL(
    "homework",
    "Crlcrl123",
    "rm-cn-em93osvdn001h9xo.rwlb.rds.aliyuncs.com",
    3306,
    "practice3",
)
csv2sql("./csi_300.csv", "stock")

db.commit()
