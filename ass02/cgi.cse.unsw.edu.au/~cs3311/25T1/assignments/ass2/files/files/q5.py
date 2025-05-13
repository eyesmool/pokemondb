#! /usr/bin/env python3


"""
COMP3311
25T1
Assignment 2
Pokemon Database

Written by: <YOUR NAME HERE> <YOUR STUDENT ID HERE>
Written on: <DATE HERE>

File Name: Q4
"""


import sys
import psycopg2
import helpers


### Constants
USAGE = f"Usage: {sys.argv[0]} <requirements> <types>"


def main(db):
    ### Command-line args
    if len(sys.argv) != 3:
        print(USAGE)
        return 1

    requirements = sys.argv[1]
    types = sys.argv[2]

    # TODO: your code here
    cursor = db.cursor()
    if requirements and not types:
        query = 'SELECT * FROM filterReqs(%s);'
        cursor.execute(query, (requirements,))
        rows = cursor.fetchall()
        for tuple in rows:
            basic_pokemon,evln_pre, evln_post, evln_id, requirement, inverted, assertion = tuple
            depth_query = 'SELECT * FROM depthDiff(%s, %s);'
            cursor.execute(depth_query, (evln_pre, evln_post))
            evolutionCount, = cursor.fetchone()
            print(f"You can get the pokemon {evln_post} by evolving {evln_pre}, {evolutionCount} times! ")
    
    if requirements and types:
        types_list = types.split(';') if ';' in types else [types]
        
        query = 'SELECT * FROM filterReqs(%s);'
        cursor.execute(query, (requirements,))
        rows = cursor.fetchall()
        for tuple in rows:
            basic_pokemon,evln_pre, evln_post, evln_id, requirement, inverted, assertion = tuple
            depth_query = 'SELECT * FROM depthDiff(%s, %s);'
            cursor.execute(depth_query, (evln_pre, evln_post))
            evolutionCount, = cursor.fetchone()
            print(f"You can get the pokemon {evln_post} by evolving {evln_pre}, {evolutionCount} times! ")

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
