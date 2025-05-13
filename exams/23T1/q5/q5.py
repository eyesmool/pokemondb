#! /usr/bin/env python3

# COMP3311 23T1 Final Exam
# Q5: Print details of accounts at a named branch

import sys
import psycopg2

### Constants
USAGE = f"Usage: {sys.argv[0]} <branch name>"

### Globals
db = None

### Queries

### replace this line with any query templates ###

### Command-line args
if len(sys.argv) != 2:
    print(USAGE, file=sys.stderr)
    sys.exit(1)
suburb = sys.argv[1]


try:
    ### replace this line with your Python code ###
    conn = psycopg2.connect("dbname=bank")
    cur = conn.cursor()
    query = '''select * from branchId(%s)'''
    cur.execute(query, [suburb,])
    tup, = cur.fetchone()
    if not tup:
        print(f'No such branch {suburb}')
        sys.exit()
    suburb_id = tup
    query = '''select * from accounts(%s)'''
    cur.execute(query, [suburb,])
    print(f"{suburb} branch ({suburb_id}) holds")
    checking_sum = 0
    for tup in cur.fetchall():
        acc, name, cus_suburb, bal = tup
        print(f"- account {acc} owned by {name} from {cus_suburb} with ${bal}")
        checking_sum += bal
    query = '''select * from asset(%s)'''
    cur.execute(query,[suburb,])
    tup, = cur.fetchone()
    assets = tup
    print(f'Assets: ${assets}')
    if (checking_sum != assets):
        print('Discrepancy between assets and sum of account balances')


except psycopg2.Error as err:
    print("DB error: ", err)
except Exception as err:
    print("Internal Error: ", err)
    raise err
finally:
    if db is not None:
        db.close()
sys.exit(0)

### replace this line by any helper functions ###
