Main issues to address (learn-by-doing style)

Relationships are modeled as columns containing other table names (e.g., team_drivers driver, season_drivers driver, season_races track). In a relational model you represent relationships with foreign keys or separate join tables for many-to-many relationships — not by embedding a table type as a column.
Question for you: which relationships are 1:1, 1:N, or N:M? (e.g., a Team has many Drivers (1:N), a Driver may race for different Teams across seasons (N:M with season context)).
Ambiguous entity definitions:
race vs track — you want track = circuit (Monza), and race = event (Italian GP 2025) that occurs at a track on a date. Ask: do you need both? Why?
Missing important columns for real use:
driver should include identifiers (country, code), and history of numbers and team affiliation per season.
lap_time needs race_id, session_id, driver_id, lap_number, lap_time_ms, tire_compound, timestamp, not just track and time.
race_result and qualifying_result should record driver_id, race_id, position, time, points, status (Finished/DNF), not username/role.
Team-driver changes over time:
Drivers switch teams; you need a driver_team affiliation table with season (or date range) to track which team a driver belonged to for a given race.
Predictions should be tied to a model/version and include confidence and timestamp:
Store model_version_id, generated_at, predicted_position, probability, possibly full JSON for per-driver-per-race probability distributions.
Keys and types:
Decide surrogate keys (serial/UUID) vs natural keys. Surrogates (int or UUID) are easier; natural keys are useful only if stable.
Use appropriate DBML types: int, varchar, timestamp, float, boolean, jsonb (if DBML supports it).
Normalization vs denormalization:
For reads (UI top-3, standings) it's helpful to maintain materialized views or denormalized cache tables rather than recompute heavy aggregates.