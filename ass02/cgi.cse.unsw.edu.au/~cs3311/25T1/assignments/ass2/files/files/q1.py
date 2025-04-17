#! /usr/bin/env python3


"""
COMP3311
25T1
Assignment 2
Pokemon Database

Written by: <YOUR NAME HERE> <YOUR STUDENT ID HERE>
Written on: <DATE HERE>

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

    # TODO: your code here
    cursor = db.cursor()
    cursor.execute("""
    SELECT
        G.name,
        count(distinct I.egg_group) as eggs,
        count(distinct P.national_id) as pokemon
    FROM
        Pokedex P
        JOIN In_Group I on (P.national_id = I.pokemon)
        JOIN Games G on (P.game = G.id)
    GROUP BY G.name
    ;
    """)
    for tuple in cursor.fetchall():
        gameName, eggGroup,pokemon = tuple
        print(gameName, eggGroup,pokemon)


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
