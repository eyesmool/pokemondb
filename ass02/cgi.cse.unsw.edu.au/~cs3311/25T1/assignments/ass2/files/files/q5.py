#!/usr/bin/env python3

"""
COMP3311 25T1
Assignment 2
Pokemon Database

Q5: Find evolution chains matching requirements
"""

import sys
import psycopg2
import re
from typing import List, Dict, Tuple, Set, Optional

# Constants
USAGE = f"Usage: {sys.argv[0]} '<requirements>' '<types>'"

def parse_arguments() -> Tuple[List[str], List[str]]:
    """Parse command-line arguments for requirements and types."""
    if len(sys.argv) != 3:
        print(USAGE)
        sys.exit(1)
    
    req_list = [r.strip() for r in sys.argv[1].split(';') if r.strip()]
    type_list = [t.strip() for t in sys.argv[2].split(';') if t.strip()]
    
    return req_list, type_list

def get_basic_pokemon(conn) -> List[Tuple[Tuple[int, int], str]]:
    """Find Pokémon that are not evolved from anything (basic Pokémon)."""
    query = """
    SELECT p.ID, p.Name 
    FROM Pokemon p
    WHERE NOT EXISTS (
        SELECT 1 FROM Evolutions e 
        WHERE e.Post_Evolution = p.ID
    )
    ORDER BY p.Name;
    """
    with conn.cursor() as cur:
        cur.execute(query)
        return cur.fetchall()

def trace_evolution_chains(conn, pokemon_id: Tuple[int, int]):
    """
    Trace all possible evolution paths starting from a Pokémon.
    Returns a list of evolution chains, where each chain is a list of (pokemon_id, pokemon_name) tuples.
    """
    pokedex_num, variation = pokemon_id
    query = """
    WITH RECURSIVE evolution_path AS (
        -- Base case: starting Pokémon
        SELECT 
            p.ID AS pokemon_id,
            p.Name AS pokemon_name,
            1 AS depth,
            ARRAY[p.ID] AS path
        FROM Pokemon p
        WHERE (p.ID).Pokedex_Number = %s AND (p.ID).Variation_Number = %s
        
        UNION ALL
        
        -- Recursive case: find all evolutions
        SELECT
            p.ID,
            p.Name,
            ep.depth + 1,
            ep.path || p.ID
        FROM evolution_path ep
        JOIN Evolutions e ON (ep.pokemon_id).Pokedex_Number = (e.Pre_Evolution).Pokedex_Number 
                         AND (ep.pokemon_id).Variation_Number = (e.Pre_Evolution).Variation_Number
        JOIN Pokemon p ON e.Post_Evolution = p.ID
        -- Prevent cycles
        WHERE NOT p.ID = ANY(ep.path)
    )
    SELECT (pokemon_id).Pokedex_Number, (pokemon_id).Variation_Number, pokemon_name, depth 
    FROM evolution_path
    ORDER BY path;
    """
    
    with conn.cursor() as cur:
        cur.execute(query, (pokedex_num, variation))
        rows = cur.fetchall()
    
    # Group into separate chains (handles branching evolutions)
    chains = []
    current_chain = []
    current_depth = 1
    
    for row in rows:
        pokemon_id = (row[0], row[1])
        name = row[2]
        depth = row[3]
        
        if depth == 1:  # New base Pokémon
            if current_chain:
                chains.append(current_chain)
            current_chain = [(pokemon_id, name)]
        else:
            if depth > current_depth:
                current_chain.append((pokemon_id, name))
                current_depth = depth
            else:
                # Start a new branch
                chains.append(current_chain)
                current_chain = [chains[-1][depth-2], (pokemon_id, name)]
                current_depth = depth
    
    if current_chain:
        chains.append(current_chain)
    
    return chains

def check_evolution_requirements(conn, pre_id: Tuple[int, int], post_id: Tuple[int, int], req_list: List[str]) -> bool:
    """
    Check if evolution from pre_id to post_id meets all requirements.
    """
    pre_pokedex, pre_var = pre_id
    post_pokedex, post_var = post_id
    
    query = """
    SELECT r.Assertion, er.Inverted
    FROM Evolution_Requirements er
    JOIN Requirements r ON er.Requirement = r.ID
    JOIN Evolutions e ON er.Evolution = e.ID
    WHERE (e.Pre_Evolution).Pokedex_Number = %s AND (e.Pre_Evolution).Variation_Number = %s
      AND (e.Post_Evolution).Pokedex_Number = %s AND (e.Post_Evolution).Variation_Number = %s
    ORDER BY r.ID;
    """
    
    with conn.cursor() as cur:
        cur.execute(query, (pre_pokedex, pre_var, post_pokedex, post_var))
        requirements = cur.fetchall()
    
    # If no requirements, evolution is always possible
    if not requirements:
        return True
    
    # Check each requirement against input list
    for assertion, inverted in requirements:
        req_str = assertion if not inverted else f"Not {assertion}"
        if not requirement_matches_list(req_str, req_list):
            return False
    
    return True

def requirement_matches_list(requirement: str, req_list: List[str]) -> bool:
    """
    Check if a single requirement matches any in the input list.
    Handles numeric comparisons and case insensitivity.
    """
    # Normalize
    req_lower = requirement.lower()
    
    # Check for numeric requirements (like "Level: 30")
    if ':' in req_lower:
        req_parts = req_lower.split(':', 1)
        req_key = req_parts[0].strip()
        req_value = req_parts[1].strip()
        
        # Try to extract number
        try:
            req_num = int(''.join(filter(str.isdigit, req_value)))
        except:
            req_num = None
        
        # Compare against each input requirement
        for input_req in req_list:
            input_lower = input_req.lower()
            if ':' in input_lower:
                input_parts = input_lower.split(':', 1)
                input_key = input_parts[0].strip()
                input_value = input_parts[1].strip()
                
                # Keys must match
                if input_key != req_key:
                    continue
                
                # Try to extract number from input
                try:
                    input_num = int(''.join(filter(str.isdigit, input_value)))
                except:
                    input_num = None
                
                # Numeric comparison
                if req_num is not None and input_num is not None:
                    return req_num <= input_num
                # Non-numeric exact match
                else:
                    return req_value.strip() == input_value.strip()
    
    # Non-numeric requirement
    return any(req_lower == r.lower() for r in req_list)

def check_pokemon_types(conn, pokemon_id: Tuple[int, int], type_constraints: List[str]) -> bool:
    """
    Check if a Pokémon's types match the constraints.
    - Types without ^ must be present.
    - Types with ^ must not be present.
    """
    pokedex_num, variation = pokemon_id
    
    query = """
    SELECT t.Name 
    FROM Pokemon p
    JOIN Types t ON p.First_Type = t.ID OR p.Second_Type = t.ID
    WHERE (p.ID).Pokedex_Number = %s AND (p.ID).Variation_Number = %s;
    """
    
    with conn.cursor() as cur:
        cur.execute(query, (pokedex_num, variation))
        types = {t[0].lower() for t in cur.fetchall()}
    
    required_types = set()
    forbidden_types = set()
    
    for constraint in type_constraints:
        if constraint.startswith('^'):
            forbidden_types.add(constraint[1:].lower())
        else:
            required_types.add(constraint.lower())
    
    # Must have at least one required type (if any)
    if required_types and not (required_types & types):
        return False
    
    # Must not have any forbidden types
    if forbidden_types & types:
        return False
    
    return True

def main(db):
    req_list, type_list = parse_arguments()
    
    basic_pokemon = get_basic_pokemon(db)
    valid_chains = []
    
    for pokemon_id, pokemon_name in basic_pokemon:
        chains = trace_evolution_chains(db, pokemon_id)
        
        for chain in chains:
            valid_chain = True
            
            # Check each evolution step in the chain
            for i in range(1, len(chain)):
                pre_id = chain[i-1][0]
                post_id = chain[i][0]
                
                if not check_evolution_requirements(db, pre_id, post_id, req_list):
                    valid_chain = False
                    break
            
            # Check type constraints for all Pokémon in chain
            if valid_chain:
                for pokemon_id, _ in chain:
                    if not check_pokemon_types(db, pokemon_id, type_list):
                        valid_chain = False
                        break
            
            if valid_chain and len(chain) > 1:
                depth = len(chain) - 1
                final_name = chain[-1][1]
                valid_chains.append((depth, final_name, pokemon_name))
    
    # Sort results by depth, then final name, then basic name
    valid_chains.sort(key=lambda x: (x[0], x[1], x[2]))
    
    if not valid_chains:
        print("No evolution chains match the requirements")
    else:
        for depth, final_name, basic_name in valid_chains:
            print(f"You can get the final pokemon {final_name} by evolving {basic_name} {depth} times!")

if __name__ == '__main__':
    exit_code = 0
    db = None
    try:
        db = psycopg2.connect(dbname="pkmon")
        main(db)
    except psycopg2.Error as err:
        print("DB error: ", err)
        exit_code = 1
    except Exception as err:
        print("Internal Error: ", err)
        exit_code = 1
    finally:
        if db is not None:
            db.close()
    sys.exit(exit_code)