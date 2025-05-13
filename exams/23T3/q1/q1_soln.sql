-- COMP3311 23T3 Final Exam
-- Q1: oldest Fun Run participants

-- replace this line with any helper views --
create or replace view ages(person,event,held,age)
as
select p.name, e.name, e.held_on,
       (e.held_on - p.d_o_b) / 365 as age
from   People p
join   Participants pp on p.id = pp.person_id
join   Events e on pp.event_id = e.id;

create or replace view q1_soln(person,age,event)
as
-- replace this line with your SQL code --
select person, age, substr(held::text,1,4)||' '||event
from   ages
where  age = (select max(age) from ages)
;
;
