-- COMP3311 21T3 Exam Q2
-- Number of unsold properties of each type in each suburb
-- Ordered by type, then suburb

create or replace view q2(suburb, ptype, nprops)
as
select
  su.name,
  p.ptype,
  count(p.ptype) as nprops
from properties p
join streets s on (p.street = s.id)
join suburbs su on (su.id = s.suburb)
where p.sold_price is null
group by su.name, p.ptype
order by p.ptype, su.name
;
