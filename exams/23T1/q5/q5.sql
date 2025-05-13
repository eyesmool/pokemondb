-- COMP3311 23T1 Final Exam
-- Q5: Helper views and functions to support q5

create or replace function branchId(_branchName text)
  returns integer
as $$
declare
  branchId integer;
begin
  select b.id
  into branchId
  from branches b
  where b.location LIKE _branchName;
  return branchId;
end
$$ language plpgsql;

create or replace function asset(_branchName text) 
  returns table (
    assets integer
  )
as $$
begin
  return query
  select
    b.assets
  from branches b
  where b.location LIKE _branchName;
end
$$ language plpgsql;

create or replace function accounts(_branchName text)
  returns table (
    account_id integer,
    _name text,
    customer_from text,
    account_balance integer
  )
as $$
begin
  return query
  select 
    a.id as account_id,
    c.given || ' ' || c.family as account_name,
    c.lives_in as customer_from,
    a.balance as account_balance
  from 
    branches b
    join accounts a on (a.held_at = b.id)
    join held_by h on (h.account = a.id)
    join customers c on (c.id = h.customer)
  where b.location LIKE _branchName
  order by a.id;
end
$$ language plpgsql;