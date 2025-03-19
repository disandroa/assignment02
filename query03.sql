/*
  Using the Philadelphia Water Department Stormwater Billing Parcels dataset,
  pair each parcel with its closest bus stop. The final result should give the
  parcel address, bus stop name, and distance apart in meters, rounded to two
  decimals. Order by distance (largest on top).
*/

select
    pwd.address as parcel_address,
    stops.stop_name,
    round(stops.distance::numeric, 2) as distance
from phl.pwd_parcels as pwd
cross join lateral (
    select
        stops.stop_name,
        stops.geog,
        stops.geog <-> pwd.geog as distance
    from septa.bus_stops as stops
    order by distance
    limit 1
) as stops;
