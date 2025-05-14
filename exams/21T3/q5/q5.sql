drop type if exists property_info cascade;
create type property_info as (
  property_id integer,
  price integer,
  bed_bath_cars text,
  paddress text
);
create or replace function properties(_type propertytype, maxprice integer)
  returns setof property_info
as $$ 
declare
  tup property_info;
begin
  for tup in 
    select 
      f.property,
      p.list_price,
      string_agg(f.number::text, ',' order by 
        case f.feature
          when 'bedrooms' then 1
          when 'bathrooms' then 2
          when 'carspaces' then 3
        end
      ) as bed_bath_cars
    from properties p
    join features f on (p.id = f.property)
    where p.ptype = _type and 
    (f.feature = 'bedrooms' or f.feature = 'bathrooms' or f.feature = 'carspaces')
    and p.sold_price is null and p.list_price <= maxprice 
    group by f.property, p.list_price
    order by p.list_price
  loop
    tup.paddress = address(tup.property_id);
    return next tup;
  end loop;
end;
$$ language plpgsql;

-- select * from properties p join features f on (f.property=p.id) where p.id  = 46423 order by p.list_price, f.feature asc;

-- select 
--       f.property,
--       p.list_price,
--       f.*
--     from properties p
--     join features f on (p.id = f.property)
--     where p.ptype = 'Apartment' and 
--     (f.feature = 'bedrooms' or f.feature = 'bathrooms' or f.feature = 'carspaces')
--     and p.sold_price is null and p.list_price <= 800000 
--     order by p.list_price, f.feature asc