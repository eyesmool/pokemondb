-- COMP3311 25T1 Ass2 ... SQL helper Views/Functions
-- Add any views or functions you need into this file
-- Note: it must load without error into a freshly created Pokemon database

-- The `dbpop()` function is provided for you in the dump file
-- This is provided in case you accidentally delete it

DROP TYPE IF EXISTS Population_Record CASCADE;
CREATE TYPE Population_Record AS (
	Tablename Text,
	Ntuples   Integer
);

CREATE OR REPLACE FUNCTION DBpop()
    RETURNS SETOF Population_Record
    AS $$
        DECLARE
            rec Record;
            qry Text;
            res Population_Record;
            num Integer;
        BEGIN
            FOR rec IN SELECT tablename FROM pg_tables WHERE schemaname='public' ORDER BY tablename LOOP
                qry := 'SELECT count(*) FROM ' || quote_ident(rec.tablename);

                EXECUTE qry INTO num;

                res.tablename := rec.tablename;
                res.ntuples   := num;

                RETURN NEXT res;
            END LOOP;
        END;
    $$ LANGUAGE plpgsql
;

--
-- Example Views/Functions
-- These Views/Functions may or may not be useful to you.
-- You may modify or delete them as you see fit.
--

-- `Move_Learning_Info`
-- The `Learnable_Moves` table is a relation between Pokemon, Moves, Games and Requirements.
-- As it just consists of foreign keys, it is not very easy to read.
-- This view makes it easier to read by displaying the names of the Pokemon, Moves and Games instead of their IDs.
CREATE OR REPLACE VIEW Move_Learning_Info(Pokemon, Move, Game, Requirement) AS
    SELECT
        P.Name,
        M.Name,
        G.Name,
        R.Assertion
    FROM
        Learnable_Moves AS L
        JOIN Pokemon AS P
        ON Learnt_By = P.ID
        JOIN Games AS G
        ON Learnt_In = G.ID
        JOIN Moves AS M
        ON Learns = M.ID
        JOIN Requirements AS R
        ON Learnt_When = R.ID
;

-- `Super_Effective`
-- This function takes a type name and
-- returns a set of all types that it is super effective against (multiplier > 100)
-- eg Water is super effective against Fire, so `Super_Effective('Water')` will return `Fire` (amongst others)
CREATE OR REPLACE FUNCTION Super_Effective(_Type Text)
    RETURNS SETOF Text
    AS $$
        SELECT
            B.Name
        FROM
            Types AS A
            JOIN Type_Effectiveness AS E
            ON A.ID = E.Attacking
            JOIN Types AS B
            ON B.ID = E.Defending
        WHERE
            A.Name = _Type
            AND
            E.Multiplier > 100
    $$ LANGUAGE SQL
;

--
-- Your Views/Functions Below Here
-- Remember This file must load into a clean Pokemon database in one pass without any error
-- NOTICEs are fine, but ERRORs are not
-- Views/Functions must be defined in the correct order (dependencies first)
-- eg if my_supper_clever_function() depends on my_other_function() then my_other_function() must be defined first
-- Your Views/Functions Below Here
--

DROP TYPE IF EXISTS Pokemon10MoveInfo CASCADE;
CREATE TYPE Pokemon10MoveInfo as (_Type Text, nmoves integer, npokemon integer);
CREATE OR REPLACE FUNCTION q2Helper()
    RETURNS SETOF Pokemon10MoveInfo
    AS $$
    DECLARE
        tuple record;
        info Pokemon10MoveInfo;
    BEGIN
        for tuple in
            SELECT
                T.name as type_name,
                count(distinct M.id) AS nmoves
            FROM
                Moves M
                JOIN Types T on (M.of_type = T.id)
            GROUP BY T.name
        LOOP
            info._type := tuple.type_name;
            info.nmoves := tuple.nmoves;
            info.npokemon := sigma(tuple.type_name);
            return next info;
        END LOOP;
    END; $$ language plpgsql;
;

CREATE OR REPLACE FUNCTION typeToID (_Type text)
    RETURNS text
    AS $$
    DECLARE
        id integer;
    BEGIN
        SELECT T.id INTO id FROM Types T WHERE t.name ILIKE _Type;
        return id;
    END; $$language plpgsql;

CREATE OR REPLACE FUNCTION sigma(_type text)
    RETURNS integer
    AS $$
    DECLARE
        npokemon INTEGER;
        qry TEXT;
    BEGIN
        qry := '
        SELECT COUNT(*)
        FROM
            (SELECT
                P.name,
                count(distinct M.name)
            FROM
                Moves M
                JOIN Learnable_Moves L ON (M.id = L.learns)
                JOIN Pokemon P ON (P.id = L.learnt_by)
                JOIN Types T ON (T.id = M.of_type)
            WHERE t.name = '|| quote_literal(_type) ||'  AND P.first_type = '|| typeToID(_type) ||'
            GROUP BY P.name
            HAVING count(distinct M.name) > 10
            ) AS Foo;
        ';
        
        EXECUTE qry INTO npokemon;
        RETURN npokemon;
    END;$$ LANGUAGE plpgsql;



