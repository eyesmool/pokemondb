#! /usr/bin/env python3


"""
COMP3311
25T1
Assignment 2
Pokemon Database

Written by: Richard z5513417
Written on: 23rd April

File Name: Q4
"""


import sys
import psycopg2
import helpers
from collections import defaultdict


### Constants
USAGE = f"Usage: {sys.argv[0]} <pokemon_name>"


def main(db):
    ### Command-line args
    if len(sys.argv) != 2:
        print(USAGE)
        return 1

    pokemon_name = sys.argv[1]

    cursor = db.cursor()
    checkPokemonExists = "SELECT * FROM pkmonNameToId(%s);"
    cursor.execute(checkPokemonExists, (pokemon_name,))
    result = cursor.fetchone()
    if result is None or any(x is None for x in result):
        print(f'Pokemon "{pokemon_name}" not found')
        return 0
    query = "SELECT * FROM q4Helper(%s);"
    cursor.execute(query, (pokemon_name,))
    rows = cursor.fetchall()
    if not rows:
        print(f"No evolution chain found for {pokemon_name}")
        return 0

    # Group rows by pkmonmatch
    chains = defaultdict(list)
    for row in rows:
        pkmonmatch, evln_pre, evln_post, evln_id = row
        chains[pkmonmatch].append((evln_pre, evln_post, evln_id))

    def get_evolution_req(db, evln_id):
        if evln_id is None:
            return ""
        cur = db.cursor()
        cur.execute("SELECT inverted, assertion FROM evolutionReq(%s);", (evln_id,))
        reqs = []
        for inverted, assertion in cur.fetchall():
            if inverted:
                reqs.append(f"[Not {assertion}]")
            else:
                reqs.append(f"[{assertion}]")
        return " AND ".join(reqs)

    for pkmonmatch in chains:
        print(f"{pkmonmatch}: The full evolution chain:")
        evos = chains[pkmonmatch]

        # Handle special case: no evolutions (all fields except pkmonmatch are null/empty)
        if all(not evln_pre and not evln_post and not evln_id for evln_pre, evln_post, evln_id in evos):
            print(pkmonmatch)
            print("- No Evolutions")
            continue

        # Find all unique evln_pre that are not evln_post
        pre_set = set(evln_pre for evln_pre, _, _ in evos if evln_pre)
        post_set = set(evln_post for _, evln_post, _ in evos if evln_post)
        roots = pre_set - post_set
        if not roots:
            roots = pre_set

        def print_chain(curr, depth):
            next_evos = [
                (evln_post, evln_id)
                for evln_pre, evln_post, evln_id in evos
                if evln_pre == curr
            ]
            if depth == 0:
                print(curr)
            if not next_evos:
                return
            for evln_post, evln_id in next_evos:
                req_str = get_evolution_req(db, evln_id)
                print("+" * (depth + 1), f'For "{evln_post}", The evolution requirement is {req_str}')
                print_chain(evln_post, depth + 1)

        for root in sorted(roots):
            print_chain(root, 0)


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
