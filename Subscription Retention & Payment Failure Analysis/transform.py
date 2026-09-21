import pandas as pd
import sqlalchemy as db

dfc = pd.read_csv('Data/charges.csv')
dfm = pd.read_csv('Data/members.csv')

engine = db.create_engine('mysql+pymysql://root:1234@localhost:3306/s2')

dfc.to_sql(
    name = 'charges',
    con=engine,
    if_exists='replace',
    index=False
)

print('dfc is imported sucessfully')

dfm.to_sql(
    name = 'members',
    con=engine,
    if_exists='replace',
    index=False
)

print('dfm is imported sucessfully')
print(dfc.shape)
print(dfm.shape)