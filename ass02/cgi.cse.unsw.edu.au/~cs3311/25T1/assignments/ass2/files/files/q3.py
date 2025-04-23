#! /usr/bin/env python3


"""
COMP3311
25T1
Assignment 2
Pokemon Database

Written by: Richard z5513417
Written on: 23rd April

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

    cursor = db.cursor()
    query = "SELECT * FROM q3Helper(%s);"
    checkPokemonExists = "SELECT * FROM pkmonNameToId(%s);"
    cursor.execute(checkPokemonExists, (pokemon_name,))
    result = cursor.fetchall()
    for tuple in result:
        pokedex_number, variation_number = tuple
        if pokedex_number is None or  variation_number is None:
            print(f'Pokemon "{pokemon_name}" not found')
            return 0
    cursor.execute(query, (pokemon_name,))
    result = cursor.fetchall()
    if not result:
        print(f'No moves learnable in at least 30 games found for Pokemon "{pokemon_name}"')
        return 0
    print(f"{'MoveName':<16} {'#Games':<6} {'#AvgLearntLevel':<16}")
    for tuple in result:
        MoveName, Games, AvgLearntLevel = tuple
        print(f"{MoveName:<16} {Games:<6} {AvgLearntLevel:<16}")

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
