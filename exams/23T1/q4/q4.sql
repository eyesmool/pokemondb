-- COMP3311 23T1 Final Exam
-- Q4: Check whether account balance is consistent with transactions

-- replace this line with any helper views or functions --

create or replace function q4(_acctID integer)
	returns text
as $$
-- replace this line with your PLpgSQL code --
begin
	if not exists (select 1 from accounts a where a.id = _acctID) then
		return 'No such account';
	elsif storedBalance(_acctID) = sumTransactions(_acctID) then
		return 'OK';
	else
		return 'Mismatch: calculated balance ' || 
						sumTransactions(_acctID) ||
						', stored balance ' ||
						storedBalance(_acctID);
	end if;
end;
$$ language plpgsql;

create or replace function storedBalance(_acctID integer)
	returns table (
		balance integer
	)
as $$
begin
	return query
		select
			a.balance
		from
			accounts a
		where a.id = _acctId;
end
$$ language plpgsql;

create or replace function transactions(_acctID integer)
	returns table (
		amount integer,
		source integer,
		destination integer,
		ttype Transaction_Type
	)
as $$
begin
		return query
			select
				t.amount,
				t.source,
				t.dest,
				t.ttype
		from accounts a
		join transactions t on (t.source = a.id or t.dest = a.id)
		where a.id = _acctId;
end
$$ language plpgsql;

create or replace function sumTransactions(_acctID integer) 
	returns integer
as $$
declare
	total integer := 0;
	tup record;
begin
	for tup in
		select amount, source, destination,ttype from transactions(_acctID)
		loop
			if tup.ttype = 'deposit' then
				total = total + tup.amount;
			elsif tup.ttype = 'transfer' then
				if tup.destination = _acctID then
					total = total + tup.amount;
				else
					total = total - tup.amount;
				end if;
			elsif tup.ttype = 'withdrawal' then
				total = total - tup.amount;
			end if;
		end loop;
		return total;
end;
$$ language plpgsql

