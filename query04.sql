-- Active: 1738184738894@@localhost@5432@assignment02
/*
  Using the bus_shapes, bus_routes, and bus_trips tables from GTFS bus feed,
  find the two routes with the longest trips.

  HINT: The ST_MakeLine function is useful here. You can see an example of how
  you could use it at this MobilityData walkthrough on using GTFS data.

  HINT: Use the query planner (EXPLAIN) to see if there might be opportunities
  to speed up your query with indexes. For reference, I got this query to run in
  about 15 seconds.

  HINT: The row_number window function could also be useful here. You can read
  more about window functions in the PostgreSQL documentation. That documentation
  page uses the rank function, which is very similar to row_number.

  answer structure:
  route_short_name text,  -- The short name of the route
  trip_headsign text,  -- Headsign of the trip
  shape_geog geography,  -- The shape of the trip
  shape_length numeric  -- Length of the trip in meters, rounded to the nearest whole number
*/

with busroute_shapes as (
    select
        routes.route_short_name,
        trips.trip_headsign,
        shapes.shape_id,
        st_makeline(array_agg(st_setsrid(st_makepoint(shapes.shape_pt_lon, shapes.shape_pt_lat), 4326) order by shapes.shape_pt_sequence)) as shape_geog
    from septa.bus_shapes as shapes
    left join septa.bus_trips as trips
        on shapes.shape_id = trips.shape_id
    left join septa.bus_routes as routes
        on trips.route_id = routes.route_id
    group by shapes.shape_id, trips.trip_headsign, routes.route_short_name
)

select
    route_short_name,
    trip_headsign,
    shape_id,
    shape_geog,
    round(st_length(shape_geog::geography)::numeric, 2) as shape_length
from busroute_shapes
order by shape_length desc
limit 2;

-- show search_path;
-- SET search_path TO public;
