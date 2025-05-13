-- COMP3311 23T1 Final Exam
-- Q3: show branches where
-- *all* customers who hold accounts at that branch
-- live in the suburb where the branch is located

-- replace this line with any helper views --

create or replace view q3(branch)
as
select 
  nc.branch_location
from ncust nc
  join nsame ns on (nc.branch_location = ns.branch_location)
where nc.ncust = ns.lives_in
-- replace this line with your SQL code --
;

create or replace view ncust
as
select 
  b.location as branch_location,
  count(h.customer) as ncust
from branches b
join accounts a on (a.held_at = b.id)
join held_by h on (h.account = a.id)
join customers c on (c.id = h.customer)
group by b.location
order by branch_location
;

create or replace view nsame
as
select 
  b.location as branch_location,
  count(c.lives_in) as lives_in
from branches b
  join accounts a on (a.held_at = b.id)
  join held_by h on (h.account = a.id)
  join customers c on (c.id = h.customer)
where b.location LIKE c.lives_in
group by b.location
order by branch_location
;