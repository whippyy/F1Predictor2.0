#!/bin/bash

# F1 Predictor 2.0 Database Quick Reference
# Usage: View this file for common database operations

# ============================================================================
# DATABASE SETUP
# ============================================================================

# Make setup script executable
chmod +x setup_database.sh

# Run initial setup (creates database, user, schema, and .env file)
./setup_database.sh f1predictor f1_app localhost 5432

# Load sample data (optional)
psql -h localhost -U f1_app -d f1predictor -f seed_data.sql

# ============================================================================
# COMMON PSQL COMMANDS
# ============================================================================

# Connect to the database
psql -h localhost -U f1_app -d f1predictor

# List all tables
\dt

# List all indexes
\di

# Describe a table structure
\d lap_time
\d race_result

# Show table size
SELECT schemaname, tablename, pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename))
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;

# View active connections
SELECT * FROM pg_stat_activity;

# Exit psql
\q

# ============================================================================
# USEFUL SQL QUERIES
# ============================================================================

# 1. Get current championship standings
SELECT 
  ssc.position,
  d.full_name,
  d.code,
  t.name,
  ssc.total_points,
  ssc.wins,
  ssc.podiums
FROM season_standings_cache ssc
  JOIN driver d ON ssc.driver_id = d.id
  JOIN team t ON ssc.team_id = t.id
WHERE ssc.season_id = 1
ORDER BY ssc.position;

# 2. Get driver race history
SELECT 
  r.race_date,
  r.name,
  t.name as track,
  rr.grid_position,
  rr.finish_position,
  rr.points_awarded,
  rr.race_status
FROM race_result rr
  JOIN race r ON rr.race_id = r.id
  JOIN track t ON r.track_id = t.id
WHERE rr.driver_id = (SELECT id FROM driver WHERE code = 'VER')
ORDER BY r.race_date DESC;

# 3. Get predictions for upcoming race
SELECT 
  d.full_name,
  d.code,
  p.predicted_qualifying_position,
  p.predicted_race_position,
  p.predicted_points,
  p.win_probability,
  p.confidence_score
FROM prediction p
  JOIN driver d ON p.driver_id = d.id
WHERE p.race_id = ? AND p.model_version_id = ?
ORDER BY p.predicted_race_position;

# 4. Compare prediction accuracy
SELECT 
  d.full_name,
  p.predicted_race_position,
  rr.finish_position,
  CASE 
    WHEN p.predicted_race_position = rr.finish_position THEN 'EXACT'
    WHEN ABS(p.predicted_race_position - rr.finish_position) <= 2 THEN 'CLOSE'
    ELSE 'MISS'
  END as accuracy,
  ABS(p.predicted_race_position - rr.finish_position) as position_diff
FROM prediction p
  JOIN race_result rr ON p.race_id = rr.race_id AND p.driver_id = rr.driver_id
  JOIN driver d ON p.driver_id = d.id
WHERE p.race_id = ? AND p.model_version_id = ?
ORDER BY position_diff;

# 5. Get lap times for race analysis
SELECT 
  d.full_name,
  s.session_type,
  lt.lap_number,
  lt.lap_time_ms,
  tc.name as tire,
  lt.is_fastest_lap
FROM lap_time lt
  JOIN driver d ON lt.driver_id = d.id
  JOIN session s ON lt.session_id = s.id
  JOIN tire_compound tc ON lt.tire_compound_id = tc.id
WHERE lt.race_id = ? AND lt.session_type = 'race'
ORDER BY d.id, lt.lap_number;

# 6. Average lap time by driver at track
SELECT 
  d.full_name,
  t.name as track,
  ROUND(AVG(lt.lap_time_ms)::numeric, 2) as avg_lap_ms,
  ROUND(MIN(lt.lap_time_ms)::numeric, 2) as best_lap_ms,
  COUNT(lt.id) as lap_count
FROM lap_time lt
  JOIN driver d ON lt.driver_id = d.id
  JOIN race r ON lt.race_id = r.id
  JOIN track t ON r.track_id = t.id
WHERE t.id = ? AND lt.status = 'valid'
GROUP BY d.id, d.full_name, t.id, t.name
ORDER BY avg_lap_ms;

# 7. Driver-Team affiliations
SELECT 
  s.year,
  d.full_name,
  d.code,
  t.name,
  dt.role
FROM driver_team dt
  JOIN driver d ON dt.driver_id = d.id
  JOIN team t ON dt.team_id = t.id
  JOIN season s ON dt.season_id = s.id
WHERE s.year = 2025
ORDER BY d.full_name;

# 8. Model performance metrics
SELECT 
  name,
  version,
  trained_at,
  accuracy,
  precision,
  recall,
  f1_score,
  is_active
FROM model_version
ORDER BY trained_at DESC;

# 9. Recent predictions
SELECT 
  mv.version,
  r.name,
  t.name as track,
  COUNT(p.id) as prediction_count,
  ROUND(AVG(p.confidence_score)::numeric, 3) as avg_confidence,
  MAX(p.generated_at) as latest_prediction
FROM prediction p
  JOIN model_version mv ON p.model_version_id = mv.id
  JOIN race r ON p.race_id = r.id
  JOIN track t ON r.track_id = t.id
GROUP BY mv.id, mv.version, r.id, r.name, t.id, t.name
ORDER BY p.generated_at DESC
LIMIT 10;

# 10. Database statistics
SELECT 
  schemaname,
  tablename,
  pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) as size,
  n_live_tup as row_count
FROM pg_stat_user_tables
WHERE schemaname = 'public'
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;

# ============================================================================
# MAINTENANCE COMMANDS
# ============================================================================

# Analyze query performance
EXPLAIN ANALYZE
SELECT * FROM lap_time 
WHERE race_id = 1 AND driver_id = 2
ORDER BY lap_number;

# Vacuum and analyze (maintenance)
VACUUM ANALYZE;

# Reindex a specific table
REINDEX TABLE lap_time;

# Check index bloat
SELECT 
  current_database(),
  schemaname,
  tablename,
  ROUND(100 * (OTTA - pageno) / OTTA::numeric) AS table_bloat_pct,
  CASE WHEN relpages - otta > 0 THEN pg_size_pretty((relpages - otta)::bigint * 8192)
       ELSE '0 bytes' END AS table_bloat_size,
  ROUND(100 * (OTTA - pageno) / OTTA::numeric) AS index_bloat_pct
FROM pgstattuple_approx('public.lap_time');

# View slow queries (requires pg_stat_statements extension)
SELECT 
  query,
  calls,
  total_time,
  mean_time,
  max_time
FROM pg_stat_statements
WHERE mean_time > 100
ORDER BY mean_time DESC
LIMIT 10;

# ============================================================================
# BACKUP & RESTORE
# ============================================================================

# Backup entire database
pg_dump -h localhost -U f1_app -d f1predictor -F c > f1predictor_backup.dump

# Backup specific tables
pg_dump -h localhost -U f1_app -d f1predictor -t race_result -t race > races_backup.sql

# Restore from backup
pg_restore -h localhost -U f1_app -d f1predictor f1predictor_backup.dump

# Backup with compression
pg_dump -h localhost -U f1_app -d f1predictor | gzip > f1predictor_backup.sql.gz

# Restore from compressed backup
gunzip -c f1predictor_backup.sql.gz | psql -h localhost -U f1_app -d f1predictor

# ============================================================================
# PERFORMANCE TUNING
# ============================================================================

# Check PostgreSQL configuration
SHOW max_connections;
SHOW shared_buffers;
SHOW effective_cache_size;
SHOW work_mem;
SHOW maintenance_work_mem;

# List missing indexes (useful query)
SELECT 
  schemaname,
  tablename,
  attname,
  n_distinct,
  correlation
FROM pg_stats
WHERE schemaname = 'public'
  AND n_distinct > 100
  AND correlation < 0.1
ORDER BY abs(correlation) ASC;

# ============================================================================
# MONITORING
# ============================================================================

# Active connections and their queries
SELECT 
  pid,
  usename,
  application_name,
  state,
  query,
  state_change
FROM pg_stat_activity
WHERE datname = 'f1predictor'
ORDER BY state_change;

# Table size growth over time (if you track it)
SELECT 
  tablename,
  pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) as size
FROM pg_tables t
  JOIN pg_stat_user_tables s ON s.relname = t.tablename
WHERE schemaname = 'public'
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;

# ============================================================================
# HELPFUL FILES
# ============================================================================

# schema.sql - Complete database schema with all tables and indexes
# seed_data.sql - Sample data for testing
# SCHEMA_DOCUMENTATION.md - Comprehensive documentation
# setup_database.sh - Automated setup script
