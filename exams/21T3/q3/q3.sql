-- COMP3311 21T3 Exam Q3
-- Unsold house(s) with the lowest listed price
-- Ordered by property ID

create or replace view q3(id,price,street,suburb)
as
select 
  p.id,
  p.list_price,
  p.street_no || ' ' || st.name || ' ' || st.stype,
  su.name
from
  properties p
join streets st on (st.id = p.street)
join suburbs su on (su.id = st.suburb)
where p.sold_price is null and p.ptype ='House'
and p.list_price = (
  select min(list_price)
  from
    properties p
  where p.sold_price is null and p.ptype ='House'
)
order by p.list_price asc, p.id
;
