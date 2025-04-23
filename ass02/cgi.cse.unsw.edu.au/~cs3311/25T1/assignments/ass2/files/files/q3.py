#! /usr/bin/env python3


"""
COMP3311
25T1
Assignment 2
Pokemon Database

Written by: <YOUR NAME HERE> <YOUR STUDENT ID HERE>
Written on: <DATE HERE>

File Name: Q3
"""


import sys
import psycopg2
import helpers


### Constants
USAGE = f"Usage: {sys.argv[0]} <pokemon_name>"


def main(db):
    ### Command-line args
    if len(sys.argv) != 2:
        print(USAGE)
        return 1

    pokemon_name = sys.argv[1]

    # TODO: your code here
    qry_pokemon_moves_games = '''
    SELECT
        M.name,
        COUNT(distinct L.learnt_in)
    FROM
        Pokemon P
        JOIN Learnable_Moves L ON (P.id = L.learnt_by)
        JOIN Moves M ON (L.learns = M.id)
    WHERE L.Learnt_By = (1,0) AND L.Learnt_When <= 100 AND L.Learnt_When >= 1
    GROUP BY M.name
    HAVING COUNT(distinct L.learnt_in) > 30
    ;
    '''

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
