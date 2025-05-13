
# pokemondb

A command-line tool built with Python and PostgreSQL to explore an extensive Pokémon database, featuring over 1000 Pokémon across 9 generations. Developed as part of UNSW’s COMP3311 (Database Systems) course.

## Features

This project includes five Python scripts (`q1.py` to `q5.py`) that interact with a normalized Pokémon database using `psycopg2`. Each script focuses on a specific aspect of the dataset:

- **`q1.py`** – Lists each game and the number of distinct Egg Groups and Pokémon associated with it.
- **`q2.py`** – Shows each move type, how many moves exist for that type, and how many Pokémon with that type can learn more than 10 of them.
- **`q3.py`** – Given a Pokémon name, lists all moves it can learn via level-up in at least 30 games, along with average level and count.
- **`q4.py`** – Given a name fragment, prints full evolution chains of all matching Pokémon including branching evolutions and requirements.
- **`q5.py`** – Given evolution requirements and type filters, returns all final-form Pokémon that meet the criteria.

## Setup

1. Ensure you have PostgreSQL and Python 3 installed.
2. Load the provided database dump:

```bash
createdb pkmon
psql pkmon -f pkmon.dump.sql
```

3. Install required Python libraries:

```bash
pip install psycopg2
```

4. Run any query script:

```bash
python3 q1.py
python3 q3.py "Pikachu"
```

## Schema Overview

The database includes tables such as:

- `pokemon`, `moves`, `games`, `types`, `evolutions`, `requirements`, `learnable_moves`, `egg_groups`
- Composite types like `Pokemon_ID` and enums like `Growth_Rates`, `Move_Categories`, `Regions`

## Testing

All scripts were tested on the UNSW `vxdb02` server using the course-provided `3311 autotest ass2` command. All test cases passed successfully.

## License

Academic use only. Built as part of COMP3311 (25T1) at UNSW.
