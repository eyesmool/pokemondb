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
            info.npokemon := nPokemonMore10LearnableMovesWithType(tuple.type_name);
            return next info;
        END LOOP;
    END; $$ language plpgsql;
;

CREATE OR REPLACE FUNCTION typeToID (_Type text)
    RETURNS text
    AS $$
    DECLARE
        id Integer;
    BEGIN
        SELECT T.id INTO id FROM Types T WHERE t.name ILIKE _Type;
        return id;
    END; $$language plpgsql;

CREATE OR REPLACE FUNCTION nPokemonMore10LearnableMovesWithType(_type text)
    RETURNS Integer
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
$$ LANGUAGE plpgsql;

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
$$ LANGUAGE plpgsql;

DROP TYPE IF EXISTS q3Info CASCADE;
CREATE TYPE q3Info as (_MoveName text, nGames integer, AvgLearntLevel integer);
CREATE OR REPLACE FUNCTION q3Helper(_pkmonName text)
    RETURNS SETOF q3Info
    AS $$
    DECLARE
        tuple record;
        info q3Info;
    BEGIN
        for tuple in
            SELECT
                M.name as MoveName,
                COUNT(distinct L.learnt_in) as Games,
                AVG(L.learnt_when) as AvgLearntLevel
            FROM
                Pokemon P
                JOIN Learnable_Moves L ON (P.id = L.learnt_by)
                JOIN Moves M ON (L.learns = M.id)
            WHERE L.Learnt_By = pkmonNameToId(_pkmonName)  AND L.Learnt_When <= 100 AND L.Learnt_When >= 1
            GROUP BY M.name
            HAVING COUNT(distinct L.learnt_in) >= 30
        LOOP
            info._MoveName := tuple.movename;
            info.nGames := tuple.games;
            info.AvgLearntLevel := tuple.avglearntlevel;
        return next info;
        END LOOP;
    END;
$$ language plpgsql;

DROP TYPE IF EXISTS strMatchInfo CASCADE;
CREATE TYPE strMatchInfo AS (id _Pokemon_ID, name text);
CREATE OR REPLACE FUNCTION pkmonStrMatch(_pkmonName text)
    RETURNS SETOF strMatchInfo
    AS $$
    DECLARE
        tuple record;
        info strMatchInfo;
    BEGIN
        for tuple in
            SELECT
                P.id,
                P.name
            FROM
                Pokemon P
            WHERE P.name ILIKE '%' || _pkmonName || '%'
            ORDER BY name
        LOOP
            info.id := tuple.id;
            info.name := tuple.name;
        RETURN NEXT info;
        END LOOP;
    END;
$$ language plpgsql;

CREATE OR REPLACE FUNCTION findLeafEvlnHelper(_id _Pokemon_ID)
    RETURNS _Pokemon_ID
    AS $$
    DECLARE
        leafId _Pokemon_ID := _id;
        prevId _Pokemon_ID;
    BEGIN
        -- Check if _pkmonId has any previous evolutions
        SELECT (E.pre_evolution).Pokedex_Number, (E.pre_evolution).Variation_Number
        INTO prevId
        FROM Evolutions E
        WHERE
            E.post_evolution = _id;

        IF prevId IS NULL THEN
            -- No previous evolutions, this is the root/base
            RETURN leafId;
        ELSE
            -- Recurse on the previous evolution
            RETURN findLeafEvlnHelper(prevId);
        END IF;
    END;
$$ language plpgsql;

DROP TYPE IF EXISTS leafInfo CASCADE;
CREATE TYPE leafInfo as (name text, pkmon_Id _Pokemon_ID, leaf_Id _Pokemon_ID);
CREATE OR REPLACE FUNCTION findLeafEvlns(_pkmonName text)
    RETURNS SETOF leafInfo
    AS $$
    DECLARE
        tuple record;
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
$$ language plpgsql;

CREATE OR REPLACE FUNCTION findEvlnReqId(pre _Pokemon_ID, post _Pokemon_ID)
    RETURNS integer
    AS $$
    DECLARE
        req_id integer;
    BEGIN
        SELECT E.id
        INTO req_id
        FROM Evolutions E
        WHERE pre = E.pre_evolution AND post = E.post_evolution;

        RETURN req_id;
    END;
$$ language plpgsql;

DROP TYPE IF EXISTS evlnInfo CASCADE;
CREATE TYPE evlnInfo AS (pre_name text, pre_ev_id _Pokemon_ID, post_name text, post_ev_id _Pokemon_ID, evln_id integer);
CREATE OR REPLACE FUNCTION findEvlnInfo(_id _Pokemon_ID)
    RETURNS SETOF evlnInfo
    AS $$
    DECLARE
        tuple record;
        info evlnInfo;
        result evlnInfo;
    BEGIN
        FOR tuple IN
            SELECT DISTINCT
                P.name,
                E.pre_evolution AS pkmon_id,
                E.post_evolution AS post_ev_id
            FROM
                Evolutions E
                JOIN Pokemon P ON P.id = E.pre_evolution
            WHERE
                E.pre_evolution = _id
            ORDER BY post_ev_id DESC
        LOOP
            info.pre_name := tuple.name;
            info.pre_ev_id := tuple.pkmon_id;
            info.post_name := pkmonIdToName(tuple.post_ev_id);
            info.post_ev_id := tuple.post_ev_id;
            info.evln_id := findEvlnReqId(tuple.pkmon_id, tuple.post_ev_id);
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
$$ LANGUAGE plpgsql;

DROP TYPE IF EXISTS q4Info CASCADE;
CREATE TYPE q4Info AS (pkmonMatch text, evln_pre text, evln_post text, evln_id integer);
CREATE OR REPLACE FUNCTION q4Helper(_pkmonName text)
    RETURNS SETOF q4Info
    AS $$
    DECLARE
        tuple1 record;
        tuple2 record;
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
$$ language plpgsql;

DROP TYPE IF EXISTS evolutionReqInfo CASCADE;
CREATE TYPE evolutionReqInfo AS (inverted boolean, assertion text);
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
            JOIN Requirements R on R.id = E.requirement
        WHERE evolution = evln_id
        ORDER BY E.requirement;
    END;
$$ LANGUAGE plpgsql;







