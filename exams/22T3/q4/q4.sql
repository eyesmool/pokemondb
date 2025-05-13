-- COMP3311 22T3 Final Exam Q4
-- Function to return average winnings for horses matching a partial name

drop type if exists horse_winnings cascade;
create type horse_winnings as (horse text, average integer);

-- put helper views (if any) here

-- answer: Q4(part_name text) -> setof horse_winnings

create or replace function
    Q4(part_name text) returns setof horse_winnings
as $$
declare
    tup horse_winnings;
begin
    for tup in
        select 
            nR.horse,
            hE.earnings / nR.nraces
        from numRaces(part_name) nR
        join horseEarnings(part_name) hE on (hE.horse = nR.horse)
    loop
        return next tup;
    end loop;
end
$$ language plpgsql;

drop type if exists horse_races cascade;
create type horse_races as (horse text, nraces integer);
create or replace function
    numRaces(_horse text) returns setof horse_races
as $$
declare
    tup horse_races;
begin
    for tup in
        select 
            h.name as horse_name,
            count(r.name) as race_name
        from runners ru 
        join races r on (ru.race = r.id)
        join horses h on (ru.horse = h.id)
        where h.name ILIKE '%' || _horse || '%'
        group by h.name
        order by h.name
    loop
        return next tup;
    end loop;
end
$$ language plpgsql;

drop type if exists horse_earnings cascade;
create type horse_earnings as (horse text, earnings integer);
create or replace function
    horseEarnings(_horse text) returns setof horse_earnings
as $$
declare
    tup horse_earnings;
begin
    for tup in 
        select 
            h.name as horse_name,
            sum(r.prize)
        from runners ru 
        join races r on (ru.race = r.id)
        join horses h on (ru.horse = h.id)
        where h.name ILIKE '%' || _horse || '%' and ru.finished = 1
        group by h.name
        order by h.name
    loop
        return next tup;
    end loop;
end
$$ language plpgsql;
