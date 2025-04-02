/*
  Which eight bus stops have the smallest population above 500 people inside of Philadelphia
  within 800 meters of the stop (Philadelphia county block groups have a geoid prefix
  of 42101 -- that's 42 for the state of PA, and 101 for Philadelphia county)?
*/

with
septa_bus_stop_blockgroups as (
    select
        stops.stop_id,
        '1500000US' || bg.geoid as geoid
    from septa.bus_stops as stops
    inner join census.blockgroups_2020 as bg
        on st_dwithin(stops.geog, bg.geog, 800)
),

septa_bus_stop_surrounding_population as (
    select
        stops.stop_id,
        sum(pop.total) as estimated_pop_800m
    from septa_bus_stop_blockgroups as stops
    inner join census.population_2020 as pop using (geoid)
    group by stops.stop_id, stops.geoid
    having sum(pop.total) > 500 and stops.geoid like '1500000US42101%'
)

select
    stops.stop_name,
    pop.estimated_pop_800m,
    stops.geog
from septa_bus_stop_surrounding_population as pop
inner join septa.bus_stops as stops using (stop_id)
order by pop.estimated_pop_800m
limit 8;
