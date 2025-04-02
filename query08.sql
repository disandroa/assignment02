/*
  With a query, find out how many census block groups Penn's main campus
  fully contains. Discuss which dataset you chose for defining Penn's campus.
*/

/*
  My idea:
  1. take all parcels with univ of penn as owner1
  2. keep only those that are within the university city neighborhood
  3. join all parcels as one big geographical area + add 100m buffer and define this as Penn's campus.
  4. count all blockgroups that are at least 90% inside this area (my definition of Penn's campus is a rough estimate so I'm leaving some wiggle room).
*/

with ucity as (
    select n.geog
    from phl.neighborhoods as n
    where n.name = 'UNIVERSITY_CITY'
),

upenn_parcels as (
    select
        pwd.objectid,
        pwd.parcelid,
        pwd.geog
    from phl.pwd_parcels as pwd
    inner join ucity
        on st_intersects(ucity.geog, pwd.geog)
    where (pwd.owner1 like '%UNIV OF PENN%') or (pwd.owner1 like '%UNIV PENN%') or (pwd.owner1 like '%TRUSTEES OF THE U OF%') or (pwd.owner1 like '%TRUSTEES OF THE UNIV%') or (pwd.owner1 like '%TRUSTEES OF UNI%') or (pwd.owner1 like '%TRUSTEES UNIV%') or (pwd.owner1 like '%UNI PENN%') or (pwd.owner1 like '%UNI-PENN%') or (pwd.owner1 like '%UNIVERSITY OF PENN%')
),

penn_campus as (
    select st_union(st_buffer(upenn_parcels.geog, 100)::geometry)::geography as geog
    from upenn_parcels
),

blockgroups as (
    select
        bg.geoid,
        st_area(bg.geog) as new_area
    from census.blockgroups_2020 as bg
),

penn_campus_blockgroups as (
    select
        bg20.geoid,
        bg.new_area,
        st_area(st_transform(st_intersection(penn_campus.geog::geometry, bg20.geog::geometry), 26918)) as intersection_area
    from census.blockgroups_2020 as bg20
    left join blockgroups as bg
        on bg20.geoid = bg.geoid
    inner join penn_campus
        on st_intersects(penn_campus.geog::geometry, bg20.geog::geometry)
)

select count(*)::numeric as count_block_groups
from penn_campus_blockgroups
where intersection_area / new_area >= 0.9;
