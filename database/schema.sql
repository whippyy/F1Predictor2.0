-- F1 Predictor 2.0 Database Schema
-- PostgreSQL Database Design for Formula 1 Race Prediction System
-- Version: 1.0
-- Last Updated: 2025-12-11

-- ============================================================================
-- FOUNDATIONAL TABLES
-- ============================================================================

-- Season: Represents a Formula 1 season (e.g., 2024, 2025)
CREATE TABLE IF NOT EXISTS season (
  id SERIAL PRIMARY KEY,
  year INT NOT NULL UNIQUE,
  name VARCHAR(50) NOT NULL,
  rounds INT NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Driver: Individual F1 driver information
CREATE TABLE IF NOT EXISTS driver (
  id SERIAL PRIMARY KEY,
  full_name VARCHAR(255) NOT NULL,
  code VARCHAR(3) UNIQUE NOT NULL, -- Racing code (e.g., VER, HAM, LEC)
  driver_number INT,
  date_of_birth DATE,
  nationality VARCHAR(100),
  headshot_url VARCHAR(500),
  license_number VARCHAR(50) UNIQUE,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Team: F1 team/constructor information
CREATE TABLE IF NOT EXISTS team (
  id SERIAL PRIMARY KEY,
  name VARCHAR(255) NOT NULL UNIQUE,
  short_name VARCHAR(50) NOT NULL UNIQUE,
  team_color VARCHAR(7), -- Hex color code
  logo_url VARCHAR(500),
  headquarters VARCHAR(255),
  founded_year INT,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Driver_Team: Many-to-many relationship between drivers and teams per season
-- Tracks which driver belonged to which team for a given season
CREATE TABLE IF NOT EXISTS driver_team (
  id SERIAL PRIMARY KEY,
  driver_id INT NOT NULL REFERENCES driver(id) ON DELETE RESTRICT,
  team_id INT NOT NULL REFERENCES team(id) ON DELETE RESTRICT,
  season_id INT NOT NULL REFERENCES season(id) ON DELETE RESTRICT,
  start_date DATE NOT NULL,
  end_date DATE,
  role VARCHAR(50) NOT NULL DEFAULT 'race_driver', -- race_driver, reserve, test_driver
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(driver_id, season_id) -- One primary team per driver per season
);

-- Track: Physical F1 circuit/racetrack information
CREATE TABLE IF NOT EXISTS track (
  id SERIAL PRIMARY KEY,
  name VARCHAR(255) NOT NULL UNIQUE,
  country VARCHAR(100) NOT NULL,
  city VARCHAR(100),
  location VARCHAR(255),
  length_m FLOAT NOT NULL, -- Track length in meters
  turns INT,
  corners INT,
  drs_zones INT,
  latitude FLOAT,
  longitude FLOAT,
  circuit_url VARCHAR(500),
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Race: Formula 1 race event (e.g., Monaco GP 2025)
CREATE TABLE IF NOT EXISTS race (
  id SERIAL PRIMARY KEY,
  season_id INT NOT NULL REFERENCES season(id) ON DELETE RESTRICT,
  track_id INT NOT NULL REFERENCES track(id) ON DELETE RESTRICT,
  round INT NOT NULL,
  name VARCHAR(255) NOT NULL,
  race_date DATE NOT NULL,
  sprint_race BOOLEAN DEFAULT FALSE,
  wiki_url VARCHAR(500),
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(season_id, round), -- One race per round per season
  UNIQUE(season_id, track_id, race_date) -- Prevent duplicate races
);

-- ============================================================================
-- SESSION & TIMING TABLES
-- ============================================================================

-- Session: Practice, Qualifying, or Race session within a race event
CREATE TABLE IF NOT EXISTS session (
  id SERIAL PRIMARY KEY,
  race_id INT NOT NULL REFERENCES race(id) ON DELETE CASCADE,
  session_type VARCHAR(50) NOT NULL, -- 'practice1', 'practice2', 'practice3', 'qualifying', 'race', 'sprint'
  started_at TIMESTAMP,
  ended_at TIMESTAMP,
  weather_condition VARCHAR(50), -- 'dry', 'wet', 'damp'
  track_temperature_c FLOAT,
  air_temperature_c FLOAT,
  status VARCHAR(50) DEFAULT 'scheduled', -- scheduled, ongoing, completed, cancelled
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Tire_Compound: FIA tire compounds (soft, medium, hard, wet, intermediate)
CREATE TABLE IF NOT EXISTS tire_compound (
  id SERIAL PRIMARY KEY,
  name VARCHAR(50) NOT NULL UNIQUE,
  code VARCHAR(5),
  color VARCHAR(7), -- Hex color for visualization
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Lap_Time: Individual lap timing data for each driver during each session
CREATE TABLE IF NOT EXISTS lap_time (
  id BIGSERIAL PRIMARY KEY,
  race_id INT NOT NULL REFERENCES race(id) ON DELETE CASCADE,
  session_id INT NOT NULL REFERENCES session(id) ON DELETE CASCADE,
  driver_id INT NOT NULL REFERENCES driver(id) ON DELETE RESTRICT,
  lap_number INT NOT NULL,
  lap_time_ms INT, -- Lap time in milliseconds
  sector1_ms INT,
  sector2_ms INT,
  sector3_ms INT,
  tire_compound_id INT REFERENCES tire_compound(id),
  pit_stop BOOLEAN DEFAULT FALSE,
  pit_loss_ms INT, -- Time lost in pit stop
  is_fastest_lap BOOLEAN DEFAULT FALSE,
  status VARCHAR(50), -- 'valid', 'invalid', 'outlap', 'inlap'
  recorded_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- RESULTS TABLES
-- ============================================================================

-- Qualifying_Result: Qualifying session results for each driver per race
CREATE TABLE IF NOT EXISTS qualifying_result (
  id BIGSERIAL PRIMARY KEY,
  race_id INT NOT NULL REFERENCES race(id) ON DELETE CASCADE,
  driver_id INT NOT NULL REFERENCES driver(id) ON DELETE RESTRICT,
  q1_time_ms INT,
  q2_time_ms INT,
  q3_time_ms INT,
  qualifying_position INT NOT NULL,
  status VARCHAR(50), -- 'complete', 'dnf', 'dsq'
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(race_id, driver_id),
  UNIQUE(race_id, qualifying_position)
);

-- Race_Result: Main race session results for each driver
CREATE TABLE IF NOT EXISTS race_result (
  id BIGSERIAL PRIMARY KEY,
  race_id INT NOT NULL REFERENCES race(id) ON DELETE CASCADE,
  driver_id INT NOT NULL REFERENCES driver(id) ON DELETE RESTRICT,
  grid_position INT NOT NULL,
  finish_position INT,
  points_awarded FLOAT DEFAULT 0,
  laps_completed INT,
  race_status VARCHAR(50), -- 'finished', 'dnf', 'dsq', 'not_classified'
  fastest_lap BOOLEAN DEFAULT FALSE,
  pit_stops INT DEFAULT 0,
  total_race_time VARCHAR(50), -- Formatted time string
  time_behind_leader_ms INT,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(race_id, driver_id),
  UNIQUE(race_id, finish_position) -- No two drivers can have same position
);

-- ============================================================================
-- PREDICTION & MODEL TABLES
-- ============================================================================

-- Model_Version: Tracks different versions of the ML model
CREATE TABLE IF NOT EXISTS model_version (
  id SERIAL PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  version VARCHAR(50) NOT NULL UNIQUE,
  description TEXT,
  model_type VARCHAR(100), -- 'tensorflow', 'xgboost', 'ensemble', etc.
  training_data_start_year INT,
  training_data_end_year INT,
  trained_at TIMESTAMP NOT NULL,
  accuracy FLOAT,
  precision FLOAT,
  recall FLOAT,
  f1_score FLOAT,
  metrics JSONB, -- Store additional metrics as JSON
  is_active BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Prediction: Race outcome predictions from ML model
CREATE TABLE IF NOT EXISTS prediction (
  id BIGSERIAL PRIMARY KEY,
  model_version_id INT NOT NULL REFERENCES model_version(id) ON DELETE RESTRICT,
  race_id INT NOT NULL REFERENCES race(id) ON DELETE CASCADE,
  driver_id INT NOT NULL REFERENCES driver(id) ON DELETE RESTRICT,
  predicted_qualifying_position INT,
  predicted_race_position INT,
  predicted_points FLOAT,
  win_probability FLOAT, -- 0.0 to 1.0
  podium_probability FLOAT,
  confidence_score FLOAT, -- Overall confidence 0.0 to 1.0
  qualifying_confidence FLOAT,
  race_confidence FLOAT,
  extra_data JSONB, -- Store full probability distribution or other metadata
  generated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(model_version_id, race_id, driver_id, generated_at)
);

-- ============================================================================
-- MATERIALIZED VIEWS FOR PERFORMANCE
-- ============================================================================

-- Season_Standings: Cached championship standings (updated nightly)
CREATE TABLE IF NOT EXISTS season_standings_cache (
  id SERIAL PRIMARY KEY,
  season_id INT NOT NULL REFERENCES season(id) ON DELETE CASCADE,
  driver_id INT NOT NULL REFERENCES driver(id) ON DELETE CASCADE,
  team_id INT REFERENCES team(id),
  position INT NOT NULL,
  total_points FLOAT NOT NULL,
  wins INT DEFAULT 0,
  podiums INT DEFAULT 0,
  races_completed INT DEFAULT 0,
  cached_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(season_id, driver_id)
);

-- Top3_Cache: Cache for top 3 drivers (refreshed after each race)
CREATE TABLE IF NOT EXISTS top3_cache (
  id SERIAL PRIMARY KEY,
  season_id INT NOT NULL REFERENCES season(id) ON DELETE CASCADE,
  rank INT NOT NULL CHECK (rank >= 1 AND rank <= 3),
  driver_id INT NOT NULL REFERENCES driver(id) ON DELETE CASCADE,
  team_id INT REFERENCES team(id),
  total_points FLOAT NOT NULL,
  wins INT,
  cached_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(season_id, rank)
);

-- Race_Prediction_Summary: Quick access cache for race predictions
CREATE TABLE IF NOT EXISTS race_prediction_summary (
  id SERIAL PRIMARY KEY,
  model_version_id INT NOT NULL REFERENCES model_version(id),
  race_id INT NOT NULL REFERENCES race(id) ON DELETE CASCADE,
  total_predictions INT,
  avg_confidence FLOAT,
  generated_at TIMESTAMP NOT NULL,
  cached_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(model_version_id, race_id, generated_at)
);

-- ============================================================================
-- AUDIT & LOGGING TABLES
-- ============================================================================

-- Audit_Log: Track all significant database changes
CREATE TABLE IF NOT EXISTS audit_log (
  id BIGSERIAL PRIMARY KEY,
  table_name VARCHAR(255) NOT NULL,
  operation VARCHAR(50) NOT NULL, -- 'INSERT', 'UPDATE', 'DELETE'
  record_id INT,
  old_values JSONB,
  new_values JSONB,
  changed_by VARCHAR(255),
  changed_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Model_Run_Log: Track each model prediction generation run
CREATE TABLE IF NOT EXISTS model_run_log (
  id SERIAL PRIMARY KEY,
  model_version_id INT NOT NULL REFERENCES model_version(id),
  started_at TIMESTAMP NOT NULL,
  completed_at TIMESTAMP,
  status VARCHAR(50), -- 'running', 'completed', 'failed'
  predictions_generated INT,
  error_message TEXT,
  execution_time_seconds FLOAT,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- INDEXES FOR PERFORMANCE
-- ============================================================================

-- Season indexes
CREATE INDEX idx_season_year ON season(year);

-- Driver indexes
CREATE INDEX idx_driver_code ON driver(code);
CREATE INDEX idx_driver_nationality ON driver(nationality);

-- Team indexes
CREATE INDEX idx_team_short_name ON team(short_name);

-- Driver_Team indexes
CREATE INDEX idx_driver_team_season ON driver_team(season_id);
CREATE INDEX idx_driver_team_driver_season ON driver_team(driver_id, season_id);
CREATE INDEX idx_driver_team_team_season ON driver_team(team_id, season_id);

-- Track indexes
CREATE INDEX idx_track_country ON track(country);
CREATE INDEX idx_track_location ON track(latitude, longitude);

-- Race indexes
CREATE INDEX idx_race_season ON race(season_id);
CREATE INDEX idx_race_track ON race(track_id);
CREATE INDEX idx_race_date ON race(race_date);
CREATE INDEX idx_race_season_round ON race(season_id, round);

-- Session indexes
CREATE INDEX idx_session_race ON session(race_id);
CREATE INDEX idx_session_type ON session(session_type);

-- Lap_Time indexes (critical for large table)
CREATE INDEX idx_lap_time_race_driver ON lap_time(race_id, driver_id);
CREATE INDEX idx_lap_time_session ON lap_time(session_id);
CREATE INDEX idx_lap_time_driver ON lap_time(driver_id);
CREATE INDEX idx_lap_time_lap_number ON lap_time(race_id, lap_number);
CREATE INDEX idx_lap_time_recorded ON lap_time(recorded_at);
CREATE INDEX idx_lap_time_fastest ON lap_time(is_fastest_lap) WHERE is_fastest_lap = TRUE;

-- Qualifying_Result indexes
CREATE INDEX idx_qualifying_race ON qualifying_result(race_id);
CREATE INDEX idx_qualifying_driver ON qualifying_result(driver_id);
CREATE INDEX idx_qualifying_position ON qualifying_result(race_id, qualifying_position);

-- Race_Result indexes
CREATE INDEX idx_race_result_race ON race_result(race_id);
CREATE INDEX idx_race_result_driver ON race_result(driver_id);
CREATE INDEX idx_race_result_position ON race_result(race_id, finish_position);
CREATE INDEX idx_race_result_points ON race_result(race_id, points_awarded DESC);

-- Prediction indexes
CREATE INDEX idx_prediction_model ON prediction(model_version_id);
CREATE INDEX idx_prediction_race ON prediction(race_id);
CREATE INDEX idx_prediction_driver ON prediction(driver_id);
CREATE INDEX idx_prediction_confidence ON prediction(confidence_score DESC);
CREATE INDEX idx_prediction_generated ON prediction(generated_at);
CREATE INDEX idx_prediction_model_race_driver ON prediction(model_version_id, race_id, driver_id);

-- Model_Version indexes
CREATE INDEX idx_model_version_active ON model_version(is_active) WHERE is_active = TRUE;
CREATE INDEX idx_model_version_trained ON model_version(trained_at);

-- Cache indexes
CREATE INDEX idx_standings_cache_season ON season_standings_cache(season_id);
CREATE INDEX idx_standings_cache_position ON season_standings_cache(season_id, position);
CREATE INDEX idx_top3_cache_season_rank ON top3_cache(season_id, rank);

-- Audit indexes
CREATE INDEX idx_audit_log_table ON audit_log(table_name);
CREATE INDEX idx_audit_log_timestamp ON audit_log(changed_at);

-- ============================================================================
-- CONSTRAINTS & TRIGGERS
-- ============================================================================

-- Update timestamp trigger function
CREATE OR REPLACE FUNCTION update_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = CURRENT_TIMESTAMP;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply update_timestamp trigger to relevant tables
CREATE TRIGGER update_season_timestamp BEFORE UPDATE ON season
FOR EACH ROW EXECUTE FUNCTION update_timestamp();

CREATE TRIGGER update_driver_timestamp BEFORE UPDATE ON driver
FOR EACH ROW EXECUTE FUNCTION update_timestamp();

CREATE TRIGGER update_team_timestamp BEFORE UPDATE ON team
FOR EACH ROW EXECUTE FUNCTION update_timestamp();

CREATE TRIGGER update_track_timestamp BEFORE UPDATE ON track
FOR EACH ROW EXECUTE FUNCTION update_timestamp();

CREATE TRIGGER update_race_timestamp BEFORE UPDATE ON race
FOR EACH ROW EXECUTE FUNCTION update_timestamp();

CREATE TRIGGER update_session_timestamp BEFORE UPDATE ON session
FOR EACH ROW EXECUTE FUNCTION update_timestamp();

CREATE TRIGGER update_prediction_timestamp BEFORE UPDATE ON prediction
FOR EACH ROW EXECUTE FUNCTION update_timestamp();

CREATE TRIGGER update_model_version_timestamp BEFORE UPDATE ON model_version
FOR EACH ROW EXECUTE FUNCTION update_timestamp();

-- ============================================================================
-- COMMENTS FOR DOCUMENTATION
-- ============================================================================

COMMENT ON TABLE season IS 'Represents a Formula 1 season (e.g., 2024, 2025)';
COMMENT ON TABLE driver IS 'Individual F1 driver information with code, number, and nationality';
COMMENT ON TABLE team IS 'F1 team/constructor information including colors and branding';
COMMENT ON TABLE driver_team IS 'Tracks which driver belonged to which team for each season';
COMMENT ON TABLE track IS 'Physical F1 circuit information including location and specifications';
COMMENT ON TABLE race IS 'F1 race event at a specific track, round, and date';
COMMENT ON TABLE session IS 'Practice, qualifying, or race session within a race event';
COMMENT ON TABLE lap_time IS 'Individual lap timing data - largest table with millions of rows';
COMMENT ON TABLE qualifying_result IS 'Qualifying session results with position and times';
COMMENT ON TABLE race_result IS 'Main race results with finishing positions and points';
COMMENT ON TABLE model_version IS 'Tracks ML model versions, training dates, and performance metrics';
COMMENT ON TABLE prediction IS 'Race outcome predictions generated by ML models';
COMMENT ON TABLE season_standings_cache IS 'Cached championship standings updated nightly';
COMMENT ON TABLE top3_cache IS 'Cache for top 3 drivers updated after each prediction/race';
COMMENT ON TABLE audit_log IS 'Audit trail for significant database changes';
COMMENT ON TABLE model_run_log IS 'Log of model prediction generation runs and execution times';

COMMENT ON COLUMN lap_time.lap_time_ms IS 'Lap time in milliseconds - primary metric for timing';
COMMENT ON COLUMN prediction.confidence_score IS 'Overall confidence 0.0-1.0 for the prediction';
COMMENT ON COLUMN prediction.extra_data IS 'JSONB column for full probability distributions and metadata';
COMMENT ON COLUMN race_result.time_behind_leader_ms IS 'Gap to race leader in milliseconds, NULL if DNF';
