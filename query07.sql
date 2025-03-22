-- Active: 1738184738894@@localhost@5432@assignment02
/*
  What are the bottom five neighborhoods according to your accessibility metric?
*/

with hoodstops as (
    select
        hoods.mapname as neighborhood_name,
        cast(count(stops.wheelchair_boarding) as decimal(9,5)) as total_stops,
        cast(sum(case when stops.wheelchair_boarding = 1 then 1 else 0 end) as decimal(9,5)) as acsbl_stops
    from phl.neighborhoods as hoods
    join septa.bus_stops as stops
        on st_intersects(hoods.geog, stops.geog)
    group by hoods.mapname
),
hoodarea as (
    select
        hoods.mapname as neighborhood_name,
        st_area(hoods.geog) / 1000000 as area_km2
    from phl.neighborhoods as hoods
),
scores as (
    select
        stops.neighborhood_name,
        hoodarea.area_km2,
        round(cast(stops.acsbl_stops / hoodarea.area_km2 as decimal(9,5)), 4) as acsblstops_perarea,
        round(stops.acsbl_stops / stops.total_stops, 4) as pct_accessible
    from hoodstops as stops
    left join hoodarea
        on stops.neighborhood_name = hoodarea.neighborhood_name
),
scaled_scores as (
    select
        scores.neighborhood_name,
        (scores.acsblstops_perarea - min(scores.acsblstops_perarea) over ()) * 1.0 / (max(scores.acsblstops_perarea) over () - min(scores.acsblstops_perarea) over ()) as scaled_acsblstops_perarea
    from scores
)
select
    scores.neighborhood_name,
    0.5 * scores.pct_accessible + 0.5 * scaled_scores.scaled_acsblstops_perarea as accessibility_metric,
    hoodstops.acsbl_stops as num_bus_stops_accessible,
    hoodstops.total_stops - hoodstops.acsbl_stops as num_bus_stops_inaccessible
from scores
left join scaled_scores
    on scores.neighborhood_name = scaled_scores.neighborhood_name
left join hoodstops
    on scores.neighborhood_name = hoodstops.neighborhood_name
order by accessibility_metric
limit 5;
