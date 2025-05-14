-- COMP3311 21T3 Exam Q4
-- Return address for a property, given its ID
-- Format: [UnitNum/]StreetNum StreetName StreetType, Suburb Postode
-- If property ID is not in the database, return 'No such property'
drop type if exists address_info cascade;
create type address_info as (
	ptype text, 
	unit_no integer,
	street_no integer,
	street_name text,
	street_type  text,
	suburb_name text,
	postcode integer
);
create or replace function address(propID integer) returns text
as
$$
declare
	tup address_info;
	error text;
begin
	for tup in
		select 
			p.ptype,
			p.unit_no,
			p.street_no,
			st.name,
			st.stype,
			su.name,
			su.postcode
		from properties p
		join streets st on (p.street = st.id)
		join suburbs su on (st.suburb = su.id)
		where p.id = propID
	loop 
		if tup.ptype = 'Apartment' then
			return (
				tup.unit_no || '/' || 
				tup.street_no || ' ' ||
				tup.street_name || ' ' ||
				tup.street_type || ', ' || 
				tup.suburb_name || ' ' ||
				tup.postcode
			);
		elsif tup.ptype = 'House' or tup.ptype = 'Townhouse' then
				return (
					tup.street_no || ' ' ||
					tup.street_name || ' ' ||
					tup.street_type || ', ' || 
					tup.suburb_name || ' ' ||
					tup.postcode
				);
		end if;
	end loop;
	error := 'No such property';
	return error;
end;
$$ language plpgsql;
