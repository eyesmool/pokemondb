#! /usr/bin/env python3


"""
COMP3311
25T1
Assignment 2
Pokemon Database

Written by: Richard z5513417
Written on: 18th April

File Name: Q1.py
"""


import sys
import psycopg2
import helpers


### Constants
USAGE = f"Usage: {sys.argv[0]}"

def main(db):
    ### Command-line args
    if len(sys.argv) != 1:
        print(USAGE)
        return 1

    cursor = db.cursor()
    query = """
    SELECT
        G.name,
        COUNT(DISTINCT I.egg_group),
        COUNT(DISTINCT P.national_id)
    FROM
        Pokedex P
        LEFT JOIN In_Group I ON (P.national_id = I.pokemon)
        JOIN Games G ON (P.game = G.id)
    GROUP BY G.name
    ;
    """
    cursor.execute(query)
    print(f"{'GameName':<17} {'#EggGroup':<9} {'#Pokemon':<8}")
    for tuple in cursor.fetchall():
        GameName, EggGroup, Pokemon = tuple
        print(f"{GameName:<17} {EggGroup:<9} {Pokemon:<8}")


if __name__ == '__main__':
    exit_code = 0
    db = None
    try:
        db = psycopg2.connect(dbname="pkmon")
        exit_code = main(db)
    except psycopg2.Error as err:
        print("DB error: ", err)
        exit_code = 1
    except Exception as err:
        print("Internal Error: ", err)
        raise err
    finally:
        if db is not None:
            db.close()
    sys.exit(exit_code)
