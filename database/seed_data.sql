-- F1 Predictor 2.0 Sample Data
-- This file contains example data to help understand the schema structure
-- and can be used to test the database after initial setup

-- Insert sample season
INSERT INTO season (year, name, rounds)
VALUES (2025, 'Formula 1 World Championship 2025', 24)
ON CONFLICT DO NOTHING;

-- Insert sample teams
INSERT INTO team (name, short_name, team_color, founded_year)
VALUES
  ('Oracle Red Bull Racing', 'RBR', '#0082FA', 2005),
  ('Scuderia Ferrari', 'FER', '#DC0000', 1950),
  ('Mercedes-AMG Petronas F1 Team', 'MER', '#00D2BE', 1954),
  ('McLaren F1 Team', 'MCL', '#FF8700', 1966),
  ('BWT Alpine F1 Team', 'ALP', '#0082FA', 2021)
ON CONFLICT (name) DO NOTHING;

-- Insert sample drivers
INSERT INTO driver (full_name, code, driver_number, nationality, date_of_birth)
VALUES
  ('Max Verstappen', 'VER', 1, 'Dutch', '1997-12-30'),
  ('Charles Leclerc', 'LEC', 16, 'Monégasque', '1997-10-16'),
  ('Lewis Hamilton', 'HAM', 44, 'British', '1985-01-07'),
  ('Lando Norris', 'NOR', 4, 'British', '1999-11-13'),
  ('Carlos Sainz', 'SAI', 55, 'Spanish', '1994-09-01')
ON CONFLICT (code) DO NOTHING;

-- Insert sample driver-team affiliations for 2025
INSERT INTO driver_team (driver_id, team_id, season_id, start_date, role)
SELECT
  (SELECT id FROM driver WHERE code = 'VER'),
  (SELECT id FROM team WHERE short_name = 'RBR'),
  (SELECT id FROM season WHERE year = 2025),
  '2025-01-01',
  'race_driver'
WHERE NOT EXISTS (
  SELECT 1 FROM driver_team 
  WHERE driver_id = (SELECT id FROM driver WHERE code = 'VER')
  AND season_id = (SELECT id FROM season WHERE year = 2025)
);

INSERT INTO driver_team (driver_id, team_id, season_id, start_date, role)
SELECT
  (SELECT id FROM driver WHERE code = 'LEC'),
  (SELECT id FROM team WHERE short_name = 'FER'),
  (SELECT id FROM season WHERE year = 2025),
  '2025-01-01',
  'race_driver'
WHERE NOT EXISTS (
  SELECT 1 FROM driver_team 
  WHERE driver_id = (SELECT id FROM driver WHERE code = 'LEC')
  AND season_id = (SELECT id FROM season WHERE year = 2025)
);

INSERT INTO driver_team (driver_id, team_id, season_id, start_date, role)
SELECT
  (SELECT id FROM driver WHERE code = 'HAM'),
  (SELECT id FROM team WHERE short_name = 'FER'),
  (SELECT id FROM season WHERE year = 2025),
  '2025-01-01',
  'race_driver'
WHERE NOT EXISTS (
  SELECT 1 FROM driver_team 
  WHERE driver_id = (SELECT id FROM driver WHERE code = 'HAM')
  AND season_id = (SELECT id FROM season WHERE year = 2025)
);

-- Insert sample tracks
INSERT INTO track (name, country, city, length_m, turns, drs_zones)
VALUES
  ('Albert Park', 'Australia', 'Melbourne', 5303, 16, 3),
  ('Circuit de Monaco', 'Monaco', 'Monte Carlo', 3337, 19, 0),
  ('Autodromo Nazionale di Monza', 'Italy', 'Monza', 5793, 11, 4),
  ('Silverstone Circuit', 'United Kingdom', 'Northampton', 5891, 18, 6)
ON CONFLICT (name) DO NOTHING;

-- Insert sample races
INSERT INTO race (season_id, track_id, round, name, race_date)
SELECT
  (SELECT id FROM season WHERE year = 2025),
  (SELECT id FROM track WHERE name = 'Albert Park'),
  1,
  'Australian Grand Prix',
  '2025-03-16'
WHERE NOT EXISTS (
  SELECT 1 FROM race 
  WHERE season_id = (SELECT id FROM season WHERE year = 2025)
  AND round = 1
);

INSERT INTO race (season_id, track_id, round, name, race_date)
SELECT
  (SELECT id FROM season WHERE year = 2025),
  (SELECT id FROM track WHERE name = 'Circuit de Monaco'),
  2,
  'Monaco Grand Prix',
  '2025-05-25'
WHERE NOT EXISTS (
  SELECT 1 FROM race 
  WHERE season_id = (SELECT id FROM season WHERE year = 2025)
  AND round = 2
);

-- Insert sample tire compounds
INSERT INTO tire_compound (name, code, color)
VALUES
  ('Soft', 'S', '#E81818'),
  ('Medium', 'M', '#FDB71A'),
  ('Hard', 'H', '#F0F0F0'),
  ('Wet', 'W', '#0082FA'),
  ('Intermediate', 'I', '#76B82A')
ON CONFLICT (name) DO NOTHING;

-- Insert sample sessions
INSERT INTO session (race_id, session_type, weather_condition, track_temperature_c)
SELECT
  (SELECT id FROM race WHERE name = 'Australian Grand Prix' AND (SELECT year FROM season WHERE id = season_id) = 2025),
  'practice1',
  'dry',
  25.0
WHERE NOT EXISTS (
  SELECT 1 FROM session 
  WHERE race_id = (SELECT id FROM race WHERE name = 'Australian Grand Prix')
  AND session_type = 'practice1'
);

INSERT INTO session (race_id, session_type, weather_condition, track_temperature_c, status)
SELECT
  (SELECT id FROM race WHERE name = 'Australian Grand Prix' AND (SELECT year FROM season WHERE id = season_id) = 2025),
  'qualifying',
  'dry',
  28.0,
  'completed'
WHERE NOT EXISTS (
  SELECT 1 FROM session 
  WHERE race_id = (SELECT id FROM race WHERE name = 'Australian Grand Prix')
  AND session_type = 'qualifying'
);

-- Insert sample model version
INSERT INTO model_version (name, version, description, model_type, trained_at, accuracy, is_active)
VALUES
  ('F1 Predictor v1', 'v1.0.0', 'Initial model trained on 2018-2024 data', 'tensorflow', CURRENT_TIMESTAMP, 0.73, true)
ON CONFLICT (version) DO NOTHING;

-- Insert sample predictions
INSERT INTO prediction (
  model_version_id, race_id, driver_id,
  predicted_qualifying_position, predicted_race_position,
  predicted_points, win_probability, podium_probability,
  confidence_score, qualifying_confidence, race_confidence
)
SELECT
  (SELECT id FROM model_version WHERE version = 'v1.0.0'),
  (SELECT id FROM race WHERE name = 'Australian Grand Prix'),
  (SELECT id FROM driver WHERE code = 'VER'),
  1, 1, 25.0, 0.45, 0.78, 0.82, 0.85, 0.80
WHERE NOT EXISTS (
  SELECT 1 FROM prediction
  WHERE model_version_id = (SELECT id FROM model_version WHERE version = 'v1.0.0')
  AND race_id = (SELECT id FROM race WHERE name = 'Australian Grand Prix')
  AND driver_id = (SELECT id FROM driver WHERE code = 'VER')
);

-- Insert sample qualifying result
INSERT INTO qualifying_result (race_id, driver_id, q1_time_ms, q2_time_ms, q3_time_ms, qualifying_position)
SELECT
  (SELECT id FROM race WHERE name = 'Australian Grand Prix'),
  (SELECT id FROM driver WHERE code = 'VER'),
  85000, 84500, 84200, 1
WHERE NOT EXISTS (
  SELECT 1 FROM qualifying_result
  WHERE race_id = (SELECT id FROM race WHERE name = 'Australian Grand Prix')
  AND driver_id = (SELECT id FROM driver WHERE code = 'VER')
);

-- Insert sample race result
INSERT INTO race_result (race_id, driver_id, grid_position, finish_position, points_awarded, laps_completed, race_status, fastest_lap)
SELECT
  (SELECT id FROM race WHERE name = 'Australian Grand Prix'),
  (SELECT id FROM driver WHERE code = 'VER'),
  1, 1, 25.0, 58, 'finished', true
WHERE NOT EXISTS (
  SELECT 1 FROM race_result
  WHERE race_id = (SELECT id FROM race WHERE name = 'Australian Grand Prix')
  AND driver_id = (SELECT id FROM driver WHERE code = 'VER')
);

-- Insert sample lap times
INSERT INTO lap_time (
  race_id, session_id, driver_id, lap_number,
  lap_time_ms, tire_compound_id, status
)
SELECT
  (SELECT id FROM race WHERE name = 'Australian Grand Prix'),
  (SELECT id FROM session WHERE race_id = (SELECT id FROM race WHERE name = 'Australian Grand Prix') AND session_type = 'practice1'),
  (SELECT id FROM driver WHERE code = 'VER'),
  1, 85000,
  (SELECT id FROM tire_compound WHERE code = 'S'),
  'valid'
WHERE NOT EXISTS (
  SELECT 1 FROM lap_time
  WHERE race_id = (SELECT id FROM race WHERE name = 'Australian Grand Prix')
  AND driver_id = (SELECT id FROM driver WHERE code = 'VER')
  AND lap_number = 1
);

-- Insert sample standings cache
INSERT INTO season_standings_cache (season_id, driver_id, team_id, position, total_points, wins, podiums)
SELECT
  (SELECT id FROM season WHERE year = 2025),
  (SELECT id FROM driver WHERE code = 'VER'),
  (SELECT id FROM team WHERE short_name = 'RBR'),
  1, 25.0, 1, 1
WHERE NOT EXISTS (
  SELECT 1 FROM season_standings_cache
  WHERE season_id = (SELECT id FROM season WHERE year = 2025)
  AND driver_id = (SELECT id FROM driver WHERE code = 'VER')
);

-- Verify data insertion
SELECT '=== Sample Data Verification ===' as info;
SELECT COUNT(*) as season_count FROM season;
SELECT COUNT(*) as driver_count FROM driver;
SELECT COUNT(*) as team_count FROM team;
SELECT COUNT(*) as race_count FROM race;
SELECT COUNT(*) as prediction_count FROM prediction;
SELECT COUNT(*) as lap_time_count FROM lap_time;

-- Display championship standings
SELECT
  'Current Standings' as info;
SELECT 
  ssc.position,
  d.full_name,
  t.name as team,
  ssc.total_points,
  ssc.wins,
  ssc.podiums
FROM season_standings_cache ssc
  JOIN driver d ON ssc.driver_id = d.id
  JOIN team t ON ssc.team_id = t.id
  JOIN season s ON ssc.season_id = s.id
WHERE s.year = 2025
ORDER BY ssc.position;
