-- COMP3311 25T1 Ass2 ... SQL helper Views/Functions
-- Add any views or functions you need into this file
-- Note: it must load without error into a freshly created Pokemon database

-- The `dbpop()` function is provided for you in the dump file
-- This is provided in case you accidentally delete it

-- Drop and create Population_Record type
DROP TYPE IF EXISTS Population_Record CASCADE;
CREATE TYPE Population_Record AS (
    Tablename Text,
    Ntuples   Integer
);

-- Function: DBpop()
-- Returns the number of tuples in each table in the public schema
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

-- View: Move_Learning_Info
-- Displays readable info about which Pokemon can learn which moves in which games and under what requirement
CREATE OR REPLACE VIEW Move_Learning_Info(Pokemon, Move, Game, Requirement) AS
    SELECT
        P.Name,
        M.Name,
        G.Name,
        R.Assertion
    FROM
        Learnable_Moves AS L
        JOIN Pokemon AS P ON Learnt_By = P.ID
        JOIN Games AS G ON Learnt_In = G.ID
        JOIN Moves AS M ON Learns = M.ID
        JOIN Requirements AS R ON Learnt_When = R.ID
;

-- Function: Super_Effective(_Type Text)
-- Returns all types that the given type is super effective against (multiplier > 100)
CREATE OR REPLACE FUNCTION Super_Effective(_Type Text)
    RETURNS SETOF Text
    AS $$
        SELECT
            B.Name
        FROM
            Types AS A
            JOIN Type_Effectiveness AS E ON A.ID = E.Attacking
            JOIN Types AS B ON B.ID = E.Defending
        WHERE
            A.Name = _Type
            AND E.Multiplier > 100
    $$ LANGUAGE SQL
;

-- Your Views/Functions Below Here
-- Remember: This file must load into a clean Pokemon database in one pass without any error
-- NOTICEs are fine, but ERRORs are not
-- Views/Functions must be defined in the correct order (dependencies first)

-- Type: Pokemon10MoveInfo
DROP TYPE IF EXISTS Pokemon10MoveInfo CASCADE;
CREATE TYPE Pokemon10MoveInfo AS (
    _Type Text,
    nmoves Integer,
    npokemon Integer
);

-- Function: q2Helper()
-- Returns, for each type, the number of moves and the number of Pokemon with more than 10 learnable moves of that type
CREATE OR REPLACE FUNCTION q2Helper()
    RETURNS SETOF Pokemon10MoveInfo
    AS $$
    DECLARE
        tuple RECORD;
        info Pokemon10MoveInfo;
    BEGIN
        FOR tuple IN
            SELECT
                T.name AS type_name,
                COUNT(DISTINCT M.id) AS nmoves
            FROM
                Moves M
                JOIN Types T ON (M.of_type = T.id)
            GROUP BY T.name
        LOOP
            info._type := tuple.type_name;
            info.nmoves := tuple.nmoves;
            info.npokemon := nPokemonMore10LearnableMovesWithType(tuple.type_name);
            RETURN NEXT info;
        END LOOP;
    END;
    $$ LANGUAGE plpgsql
;

-- Function: typeToID(_Type text)
-- Returns the ID of a type given its name (case-insensitive)
CREATE OR REPLACE FUNCTION typeToID(_Type text)
    RETURNS text
    AS $$
    DECLARE
        id Integer;
    BEGIN
        SELECT T.id INTO id FROM Types T WHERE T.name ILIKE _Type;
        RETURN id;
    END;
    $$ LANGUAGE plpgsql
;

-- Function: nPokemonMore10LearnableMovesWithType(_type text)
-- Returns the number of Pokemon whose first type is _type and who can learn more than 10 moves of that type
CREATE OR REPLACE FUNCTION nPokemonMore10LearnableMovesWithType(_type text)
    RETURNS Integer
    AS $$
    DECLARE
        npokemon Integer;
        qry Text;
    BEGIN
        qry := '
            SELECT COUNT(*)
            FROM (
                SELECT
                    P.name,
                    COUNT(DISTINCT M.name)
                FROM
                    Moves M
                    JOIN Learnable_Moves L ON (M.id = L.learns)
                    JOIN Pokemon P ON (P.id = L.learnt_by)
                    JOIN Types T ON (T.id = M.of_type)
                WHERE t.name = ' || quote_literal(_type) || ' AND P.first_type = ' || typeToID(_type) || '
                GROUP BY P.name
                HAVING COUNT(DISTINCT M.name) > 10
            ) AS Foo;
        ';
        EXECUTE qry INTO npokemon;
        RETURN npokemon;
    END;
    $$ LANGUAGE plpgsql
;

-- Function: pkmonNameToId(pkmonName text)
-- Returns the _Pokemon_ID for a given Pokemon name (case-insensitive)
CREATE OR REPLACE FUNCTION pkmonNameToId(pkmonName text)
    RETURNS _Pokemon_ID
    AS $$
    DECLARE
        result _Pokemon_ID := (NULL, NULL);
    BEGIN
        SELECT (P.ID).Pokedex_Number, (P.ID).Variation_Number
        INTO result
        FROM Pokemon P
        WHERE P.name ILIKE pkmonName;
        RETURN result;
    END;
    $$ LANGUAGE plpgsql
;

-- Function: pkmonIdToName(_id _Pokemon_ID)
-- Returns the name of a Pokemon given its _Pokemon_ID
CREATE OR REPLACE FUNCTION pkmonIdToName(_id _Pokemon_ID)
    RETURNS text
    AS $$
    DECLARE
        result text;
    BEGIN
        SELECT P.name
        INTO result
        FROM Pokemon P
        WHERE P.id = _id;
        IF result IS NULL THEN
            RAISE EXCEPTION 'No Pokemon found with ID %', _id;
        END IF;
        RETURN result;
    END;
    $$ LANGUAGE plpgsql
;

-- Type: q3Info
DROP TYPE IF EXISTS q3Info CASCADE;
CREATE TYPE q3Info AS (
    _MoveName text,
    nGames integer,
    AvgLearntLevel integer
);

-- Function: q3Helper(_pkmonName text)
-- For a given Pokemon, returns moves learnt in at least 30 games, with average learnt level (between 1 and 100)
CREATE OR REPLACE FUNCTION q3Helper(_pkmonName text)
    RETURNS SETOF q3Info
    AS $$
    DECLARE
        tuple RECORD;
        info q3Info;
    BEGIN
        FOR tuple IN
            SELECT
                M.name AS MoveName,
                COUNT(DISTINCT L.learnt_in) AS Games,
                AVG(L.learnt_when) AS AvgLearntLevel
            FROM
                Pokemon P
                JOIN Learnable_Moves L ON (P.id = L.learnt_by)
                JOIN Moves M ON (L.learns = M.id)
            WHERE
                L.Learnt_By = pkmonNameToId(_pkmonName)
                AND L.Learnt_When <= 100
                AND L.Learnt_When >= 1
            GROUP BY M.name
            HAVING COUNT(DISTINCT L.learnt_in) >= 30
        LOOP
            info._MoveName := tuple.movename;
            info.nGames := tuple.games;
            info.AvgLearntLevel := tuple.avglearntlevel;
            RETURN NEXT info;
        END LOOP;
    END;
    $$ LANGUAGE plpgsql
;

-- Type: strMatchInfo
DROP TYPE IF EXISTS strMatchInfo CASCADE;
CREATE TYPE strMatchInfo AS (
    id _Pokemon_ID,
    name text
);

-- Function: pkmonStrMatch(_pkmonName text)
-- Returns all Pokemon whose names contain the given substring (case-insensitive)
CREATE OR REPLACE FUNCTION pkmonStrMatch(_pkmonName text)
    RETURNS SETOF strMatchInfo
    AS $$
    DECLARE
        tuple RECORD;
        info strMatchInfo;
    BEGIN
        FOR tuple IN
            SELECT
                P.id,
                P.name
            FROM
                Pokemon P
            WHERE
                P.name ILIKE '%' || _pkmonName || '%'
            ORDER BY name
        LOOP
            info.id := tuple.id;
            info.name := tuple.name;
            RETURN NEXT info;
        END LOOP;
    END;
    $$ LANGUAGE plpgsql
;

-- Function: findLeafEvlnHelper(_id _Pokemon_ID)
-- Recursively finds the root/base evolution for a given Pokemon ID
CREATE OR REPLACE FUNCTION findLeafEvlnHelper(_id _Pokemon_ID)
    RETURNS _Pokemon_ID
    AS $$
    DECLARE
        leafId _Pokemon_ID := _id;
        prevId _Pokemon_ID;
    BEGIN
        -- Check if _id has any previous evolutions
        SELECT (E.pre_evolution).Pokedex_Number, (E.pre_evolution).Variation_Number
        INTO prevId
        FROM Evolutions E
        WHERE E.post_evolution = _id;
        IF prevId IS NULL THEN
            -- No previous evolutions, this is the root/base
            RETURN leafId;
        ELSE
            -- Recurse on the previous evolution
            RETURN findLeafEvlnHelper(prevId);
        END IF;
    END;
    $$ LANGUAGE plpgsql
;

-- Type: leafInfo
DROP TYPE IF EXISTS leafInfo CASCADE;
CREATE TYPE leafInfo AS (
    name text,
    pkmon_Id _Pokemon_ID,
    leaf_Id _Pokemon_ID
);

-- Function: findLeafEvlns(_pkmonName text)
-- For all Pokemon matching the name, returns their root/base evolution
CREATE OR REPLACE FUNCTION findLeafEvlns(_pkmonName text)
    RETURNS SETOF leafInfo
    AS $$
    DECLARE
        tuple RECORD;
        info leafInfo;
    BEGIN
        FOR tuple IN
            SELECT * FROM pkmonStrMatch(_pkmonName)
        LOOP
            info.name := tuple.name;
            info.pkmon_id := tuple.id;
            info.leaf_id := findLeafEvlnHelper(tuple.id);
            RETURN NEXT info;
        END LOOP;
    END;
    $$ LANGUAGE plpgsql
;

-- Function: findEvlnReqId(pre _Pokemon_ID, post _Pokemon_ID)
-- Returns the evolution ID(s) for a given pre- and post-evolution pair
CREATE OR REPLACE FUNCTION findEvlnReqId(pre _Pokemon_ID, post _Pokemon_ID)
    RETURNS TABLE(evln_id integer)
    AS $$
    BEGIN
        RETURN QUERY
        SELECT E.id AS evln_id
        FROM Evolutions E
        WHERE E.pre_evolution = pre AND E.post_evolution = post;
    END;
    $$ LANGUAGE plpgsql
;

-- Type: evlnInfo
DROP TYPE IF EXISTS evlnInfo CASCADE;
CREATE TYPE evlnInfo AS (
    pre_name text,
    pre_ev_id _Pokemon_ID,
    post_name text,
    post_ev_id _Pokemon_ID,
    evln_id integer
);

-- Function: findEvlnInfo(_id _Pokemon_ID)
-- Recursively finds all evolutions starting from a given Pokemon ID
CREATE OR REPLACE FUNCTION findEvlnInfo(_id _Pokemon_ID)
    RETURNS SETOF evlnInfo
    AS $$
    DECLARE
        tuple RECORD;
        tuple1 RECORD;
        info evlnInfo;
        result evlnInfo;
    BEGIN
        FOR tuple IN
            SELECT DISTINCT
                P.name,
                E.pre_evolution AS pkmon_id,
                E.post_evolution AS post_ev_id,
                ER.Evolution AS evln_id
            FROM
                Evolutions E
                JOIN Pokemon P ON P.id = E.pre_evolution
                JOIN Evolution_Requirements ER on E.id = ER.Evolution
            WHERE
                E.pre_evolution = _id
            ORDER BY post_ev_id DESC
        LOOP
            info.pre_name := tuple.name;
            info.pre_ev_id := tuple.pkmon_id;
            info.post_name := pkmonIdToName(tuple.post_ev_id);
            info.post_ev_id := tuple.post_ev_id;
            info.evln_id := tuple.evln_id;
            RETURN NEXT info;
        IF tuple.post_ev_id IS NOT NULL THEN
            FOR result IN
                SELECT DISTINCT * FROM findEvlnInfo(tuple.post_ev_id)
            LOOP
                RETURN NEXT result;
            END LOOP;
        END IF;
        END LOOP;
    END;
    $$ LANGUAGE plpgsql
;

-- Type: q4Info
DROP TYPE IF EXISTS q4Info CASCADE;
CREATE TYPE q4Info AS (
    pkmonMatch text,
    evln_pre text,
    evln_post text,
    evln_id integer
);

-- Function: q4Helper(_pkmonName text)
-- For all Pokemon matching the name, returns their evolution chain info
CREATE OR REPLACE FUNCTION q4Helper(_pkmonName text)
    RETURNS SETOF q4Info
    AS $$
    DECLARE
        tuple1 RECORD;
        tuple2 RECORD;
        info q4Info;
    BEGIN
        FOR tuple1 IN
            SELECT * FROM pkmonStrMatch(_pkmonName)
        LOOP
            info.pkmonMatch := tuple1.name;
            FOR tuple2 IN
                SELECT * FROM findEvlnInfo(findLeafEvlnHelper(tuple1.id))
            LOOP
                info.evln_pre := tuple2.pre_name;
                info.evln_post := tuple2.post_name;
                info.evln_id := tuple2.evln_id;
                RETURN NEXT info;
            END LOOP;
            IF NOT FOUND THEN
                info.evln_pre := NULL;
                info.evln_post := NULL;
                info.evln_id := NULL;
                RETURN NEXT info;
            END IF;
        END LOOP;
    END;
    $$ LANGUAGE plpgsql
;

-- Type: evolutionReqInfo
DROP TYPE IF EXISTS evolutionReqInfo CASCADE;
CREATE TYPE evolutionReqInfo AS (
    inverted boolean,
    assertion text
);

-- Function: evolutionReq(evln_id integer)
-- Returns the requirements for a given evolution ID
CREATE OR REPLACE FUNCTION evolutionReq(evln_id integer)
    RETURNS SETOF evolutionReqInfo
    AS $$
    BEGIN
        RETURN QUERY
        SELECT
            E.inverted,
            R.assertion
        FROM
            Evolution_Requirements E
            JOIN Requirements R ON R.id = E.requirement
        WHERE evolution = evln_id
        ORDER BY E.requirement;
    END;
    $$ LANGUAGE plpgsql
;
