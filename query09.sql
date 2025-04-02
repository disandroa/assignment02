/*
  With a query involving PWD parcels and census block groups, find the geo_id
  of the block group that contains Meyerson Hall. ST_MakePoint() and functions
  like that are not allowed.
*/

/*
  The exact address for Meyerson Hall wasn't in the list of addresses, so I used
  the 220-230 S 34th St. parcel to narrow down the block group that includes
  Meyerson Hall.
*/

select *
from phl.pwd_parcels as pwd
where pwd.address like '210 %'
order by pwd.address;

with penn_parcels as (
    select
        pwd.objectid,
        pwd.parcelid,
        pwd.geog,
        pwd.address
    from phl.pwd_parcels as pwd
    where pwd.address like '220-30%'
)

select bg.geoid as geo_id
from penn_parcels as parcels
inner join census.blockgroups_2020 as bg
    on st_intersects(bg.geog::geometry, parcels.geog::geometry);