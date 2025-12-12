# F1 Predictor 2.0 Database Schema Documentation

## Overview
This document describes the PostgreSQL database schema for the F1 Predictor 2.0 system. The schema is designed to support:
- Historical race data management (2010-2025+)
- Real-time lap timing ingestion
- ML model training and predictions
- High-performance queries for the frontend UI
- Audit logging and data integrity

## Schema Architecture

### Core Entities

#### 1. **Season**
- Represents a Formula 1 championship season (year)
- Tracks rounds/races per season
- Links all season-specific data together

#### 2. **Driver**
- Individual driver profile (name, nationality, code, number)
- `code`: 3-character racing identifier (VER, HAM, LEC)
- `driver_number`: Can change season-to-season; stored here for history
- `license_number`: FIA license, naturally unique identifier

#### 3. **Team**
- Constructor/team information (name, colors, headquarters)
- Links to drivers via `driver_team` junction table
- Supports team rebranding/name changes via season affiliation

#### 4. **Driver_Team**
- **Many-to-many relationship** between drivers and teams
- Why separate table? Drivers switch teams; teams sign different drivers each season
- `UNIQUE(driver_id, season_id)` ensures one primary team per driver per season
- Stores role (race_driver, reserve, test_driver) and date range

#### 5. **Track**
- Physical circuit information (Monza, Monaco, etc.)
- Stores location, length, corners, DRS zones
- Latitude/longitude for mapping

#### 6. **Race**
- Race event: occurs at a Track, in a Season, on a specific Round
- Tracks sprint races separately via `sprint_race` flag
- Composite unique constraint prevents duplicate races

### Session & Timing

#### 7. **Session**
- Practice 1-3, Qualifying, Race, Sprint
- Stores session-level metadata (weather, temperatures, status)
- Links lap timing and results to sessions

#### 8. **Tire_Compound**
- FIA tire compounds (soft, medium, hard, wet, intermediate)
- Stores color codes for UI visualization
- Reference table (few rows, updated rarely)

#### 9. **Lap_Time** (LARGEST TABLE)
- **Expected scale**: 30+ million rows per season
- Individual lap timing data with driver, race, session
- Stores sector times for granular analysis
- `is_fastest_lap`, `pit_stop` flags for fast filtering
- Indexed heavily for common queries (race+driver, session, lap_number)
- `recorded_at` for temporal queries

### Results

#### 10. **Qualifying_Result**
- Per-driver qualifying position and times (Q1, Q2, Q3)
- One row per driver per race
- Unique constraints ensure no duplicate positions

#### 11. **Race_Result**
- Final race outcomes: position, points, laps, DNF/DSQ status
- Stores grid position, fastest lap indicator
- `time_behind_leader_ms` in milliseconds for precise analysis
- Unique constraints prevent position/driver duplicates

### Predictions & ML

#### 12. **Model_Version**
- Versioning for ML models (v1.0, v2.0, etc.)
- Stores training date range, model type, performance metrics
- `metrics` JSONB for flexible metric storage
- `is_active` flag for selecting current model

#### 13. **Prediction**
- ML predictions: qualifying position, race position, points, probabilities
- Tied to model version, race, and driver
- Stores confidence scores and probability distributions
- `extra_data` JSONB for full prediction details (e.g., per-driver probability distribution)
- Unique constraint prevents duplicate predictions per model/race/driver/timestamp

### Performance Caches

#### 14. **Season_Standings_Cache**
- Pre-aggregated championship standings
- Updated nightly after model refresh
- Avoids expensive SUM/GROUP BY queries on every page load
- Stores wins, podiums, races completed

#### 15. **Top3_Cache**
- Stores top 3 drivers by points
- Refreshed after predictions generated
- Enables instant render of front page top section

#### 16. **Race_Prediction_Summary**
- Quick metadata about predictions for a race
- Total predictions generated, average confidence
- Enables fast lookup of prediction availability

### Audit & Logging

#### 17. **Audit_Log**
- Track all significant INSERT/UPDATE/DELETE operations
- Stores old and new JSONB values for audits
- Helps with compliance and debugging

#### 18. **Model_Run_Log**
- Log each time the model generates predictions
- Tracks execution time, error messages, predictions generated count
- Useful for monitoring and performance analysis

## Design Decisions

### 1. Surrogate Keys vs Natural Keys
**Decision**: Use `SERIAL` surrogate keys for all primary keys.
**Rationale**: 
- Faster joins and foreign key references (int vs large text/uuid)
- Easier to renumber/reorganize data
- Simpler for Alembic migrations
- Natural keys exist as unique constraints (driver.code, team.name, track.name)

### 2. Driver_Team Junction Table
**Decision**: Separate table instead of `team_id` column on `driver`.
**Rationale**:
- Drivers change teams mid-season (career moves)
- Teams sign different drivers each year
- Need to track historical affiliations per season
- Supports roles (reserve driver vs race driver)

### 3. Lap_Time Scale & Partitioning
**Decision**: Use `BIGSERIAL` for `id`; consider partitioning by `race_id` or by season.
**Rationale**:
- 30+ million rows per season
- BIGSERIAL prevents wraparound
- Composite index `(race_id, driver_id)` for common queries
- Future: partition by season or race for archive/performance

### 4. JSONB for Flexible Storage
**Decision**: Use JSONB columns for `metrics`, `extra_data`, `old_values`/`new_values`.
**Rationale**:
- ML models generate variable metadata (confidence distributions, feature importance)
- Audit logs need to capture schema changes over time
- Avoids over-normalization for rarely-queried data
- GIN indexes can be added on JSONB for search

### 5. Timestamp Strategies
**Decision**: 
- `created_at`: set once, immutable
- `updated_at`: auto-updated via trigger on every change
- `recorded_at`: user-provided or system timestamp for business logic (e.g., when lap recorded)
**Rationale**:
- Tracks insertion time and modification time separately
- Enables audit trails and cache invalidation
- Business timestamp independent of DB operations

### 6. Caching Strategy
**Decision**: Separate cache tables instead of materialized views.
**Rationale**:
- More explicit control over refresh timing
- Easier to debug and troubleshoot
- Enables incremental updates after each race
- Supports real-time updates during prediction refresh

### 7. Unique Constraints
**Decision**: Define multi-column unique constraints carefully.
**Examples**:
- `UNIQUE(season_id, round)`: One race per round per season
- `UNIQUE(driver_id, season_id)`: One primary team per driver per season
- `UNIQUE(race_id, driver_id)`: One result per driver per race
- `UNIQUE(model_version_id, race_id, driver_id, generated_at)`: One prediction per model/race/driver/timestamp

**Rationale**:
- Prevents duplicate data at the database level
- Faster than application-level validation
- Clear business logic enforced in schema

## Indexes Strategy

### High-Performance Query Patterns

**Pattern 1**: Get top 3 drivers (front page)
```sql
SELECT * FROM season_standings_cache WHERE season_id = ? ORDER BY position LIMIT 3;
```
**Index**: `idx_standings_cache_position ON season_standings_cache(season_id, position)`

**Pattern 2**: Get all lap times for a race and driver
```sql
SELECT * FROM lap_time WHERE race_id = ? AND driver_id = ? ORDER BY lap_number;
```
**Index**: `idx_lap_time_race_driver ON lap_time(race_id, driver_id)`

**Pattern 3**: Get predictions for a race
```sql
SELECT * FROM prediction WHERE race_id = ? AND model_version_id = ? ORDER BY predicted_race_position;
```
**Index**: `idx_prediction_model_race_driver ON prediction(model_version_id, race_id, driver_id)`

**Pattern 4**: Get race results for driver history
```sql
SELECT * FROM race_result WHERE driver_id = ? ORDER BY race_id DESC;
```
**Index**: `idx_race_result_driver ON race_result(driver_id)`

**Pattern 5**: Get driver standings with team info
```sql
SELECT dt.*, t.team_color FROM driver_team dt 
  JOIN team t ON dt.team_id = t.id 
  WHERE dt.season_id = ? AND dt.driver_id = ?;
```
**Indexes**: `idx_driver_team_driver_season`, `(team.id)` (PK)

### Index Types Used
- **B-tree** (default): Most columns, range queries
- **GIN**: JSONB columns (`metrics`, `extra_data`) for complex searches
- **Partial indexes**: `idx_lap_time_fastest WHERE is_fastest_lap = TRUE` to filter rare values

### Index Maintenance
- PostgreSQL auto-vacuums and analyzes tables
- Monitor bloat with `pgstattuple` extension
- Rebuild bloated indexes during maintenance windows
- Use `EXPLAIN ANALYZE` to verify index usage

## Data Retention & Archival

### Hot Data (Current Season)
- All tables for current season on fast SSD storage
- Full backups daily
- Query response time: < 500ms

### Warm Data (Previous 5 Seasons)
- On standard HDD storage
- Incremental backups
- Archive to cloud storage after 2 years
- Query response time: < 2 seconds acceptable

### Cold Data (> 5 Years)
- Archive to S3 or cold storage
- Keep for historical analysis and ML training
- Restore on demand for reporting
- Not indexed; expected slow query times

### Partitioning Strategy for lap_time
```sql
-- Partition by season (or by race for finer granularity)
CREATE TABLE lap_time_2024 PARTITION OF lap_time
  FOR VALUES FROM ('2024-01-01') TO ('2025-01-01');

CREATE TABLE lap_time_2025 PARTITION OF lap_time
  FOR VALUES FROM ('2025-01-01') TO ('2026-01-01');
```

## Security & Access Control

### Role-Based Access (PostgreSQL Roles)
```sql
-- Read-only role for frontend application
CREATE ROLE app_readonly;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO app_readonly;

-- Write role for data ingestion pipeline
CREATE ROLE app_write;
GRANT SELECT, INSERT, UPDATE ON ALL TABLES IN SCHEMA public TO app_write;

-- Admin role
CREATE ROLE db_admin WITH CREATEROLE;
GRANT ALL ON ALL TABLES IN SCHEMA public TO db_admin;
```

### Audit & Logging
- All schema changes logged in `audit_log`
- All model prediction runs logged in `model_run_log`
- Regular backups verified and tested

## Migration & Deployment

### Tools Recommended
- **Alembic** (Python): Version control for schema changes
- **Flyway** (Java/polyglot): SQL-based migrations
- **Liquibase**: Complex schema versioning

### Migration Workflow
1. Write SQL migration file (numbered, e.g., `001_init_schema.sql`)
2. Test in development environment
3. Run on staging with production copy
4. Deploy to production with zero-downtime migration if possible
5. Rollback plan documented

### Zero-Downtime Strategies
- Add new columns as nullable with defaults
- Drop constraints in separate migration
- Use `ALTER TABLE ... ADD CONSTRAINT ... NOT VALID` then `VALIDATE`

## Performance Tuning Checklist

- [ ] Set `shared_buffers` to 25% of system RAM
- [ ] Set `effective_cache_size` to 50-75% of system RAM
- [ ] Enable `autovacuum` for all tables
- [ ] Monitor with `pg_stat_statements` extension
- [ ] Use `EXPLAIN ANALYZE` for slow queries
- [ ] Monitor index bloat with `pgstattuple`
- [ ] Use connection pooling (PgBouncer) in production
- [ ] Set up replication for backup and high availability

## Sample Queries

### 1. Championship Standings with Driver & Team Info
```sql
SELECT 
  sc.position,
  d.full_name,
  d.code,
  t.name as team_name,
  sc.total_points,
  sc.wins,
  sc.podiums
FROM season_standings_cache sc
  JOIN driver d ON sc.driver_id = d.id
  JOIN team t ON sc.team_id = t.id
WHERE sc.season_id = 1
ORDER BY sc.position;
```

### 2. Driver Career History
```sql
SELECT 
  r.race_date,
  rk.name as track_name,
  rr.grid_position,
  rr.finish_position,
  rr.points_awarded,
  rr.race_status
FROM race_result rr
  JOIN race r ON rr.race_id = r.id
  JOIN track rk ON r.track_id = rk.id
WHERE rr.driver_id = ?
ORDER BY r.race_date DESC;
```

### 3. Race Predictions vs Actual Results
```sql
SELECT 
  d.full_name,
  p.predicted_race_position,
  rr.finish_position,
  CASE 
    WHEN p.predicted_race_position = rr.finish_position THEN 'EXACT'
    WHEN ABS(p.predicted_race_position - rr.finish_position) <= 2 THEN 'CLOSE'
    ELSE 'MISS'
  END as accuracy
FROM prediction p
  JOIN race_result rr ON p.race_id = rr.race_id AND p.driver_id = rr.driver_id
  JOIN driver d ON p.driver_id = d.id
WHERE p.race_id = ? AND p.model_version_id = ?
ORDER BY rr.finish_position;
```

### 4. Average Lap Time by Driver at Track
```sql
SELECT 
  d.full_name,
  t.name as track_name,
  AVG(lt.lap_time_ms) as avg_lap_time_ms,
  MIN(lt.lap_time_ms) as best_lap_ms,
  COUNT(lt.id) as lap_count
FROM lap_time lt
  JOIN driver d ON lt.driver_id = d.id
  JOIN race r ON lt.race_id = r.id
  JOIN track t ON r.track_id = t.id
WHERE t.id = ? AND lt.status = 'valid'
GROUP BY d.id, d.full_name, t.id, t.name
ORDER BY avg_lap_time_ms;
```

## Future Enhancements

1. **TimescaleDB Extension**: For better time-series querying on lap_time table
2. **pgvector Extension**: Store and query model embeddings for feature importance
3. **Partitioning**: Implement range partitioning on lap_time by season/race
4. **Incremental Updates**: Add CDC (Change Data Capture) for real-time data sync
5. **Data Warehouse**: Consider separate OLAP database for analytics queries
