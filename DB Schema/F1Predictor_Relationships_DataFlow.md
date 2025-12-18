# F1 Predictor 2.0 - Detailed Relationship & Data Flow Diagram

## Visual Data Flow Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                   F1 PREDICTOR 2.0 DATA ARCHITECTURE                        │
└─────────────────────────────────────────────────────────────────────────────┘

                        ┌─── RAW DATA INGESTION ───┐
                        │                          │
                        ▼                          ▼
                   F1 API / CSV              Formula1.com
                        │                          │
                        └─────────────┬────────────┘
                                      │
                                      ▼
                          ┌─────────────────────┐
                          │  Staging/Validation │
                          │  & ETL Processing   │
                          └─────────────────────┘
                                      │
                    ┌─────────────────┴─────────────────┐
                    │                                   │
                    ▼                                   ▼
          ┌──────────────────────┐          ┌──────────────────────┐
          │  FOUNDATIONAL DATA   │          │  TRANSACTIONAL DATA  │
          │  (Reference tables)  │          │  (Event/Results)     │
          │                      │          │                      │
          │  • Season            │          │  • Lap_Time (HIGH    │
          │  • Driver            │          │    VOLUME: 10-15M    │
          │  • Team              │          │    per season)        │
          │  • Track             │          │  • Session           │
          │  • Driver_Team       │          │  • Qualifying_Result │
          │  • Tire_Compound     │          │  • Race_Result       │
          │  • Race              │          │                      │
          └──────────────────────┘          └──────────────────────┘
                    │                                   │
                    │                    ┌──────────────┘
                    │                    │
                    ▼                    ▼
          ┌─────────────────────────────────────────┐
          │   PREDICTION & ML PIPELINE              │
          │                                         │
          │  Input Features:                        │
          │  • Historical lap times                 │
          │  • Driver performance                   │
          │  • Track characteristics                │
          │  • Weather conditions                   │
          │  • Team competitiveness                 │
          │                                         │
          │  Processing:                            │
          │  • Model_Version (tracks ML versions)   │
          │  • Model_Run_Log (execution tracking)   │
          │                                         │
          │  Output: Predictions                    │
          │  • Race_Prediction_Summary (cache)      │
          │  • Prediction table (detailed)          │
          └─────────────────────────────────────────┘
                    │
                    ▼
          ┌─────────────────────────────────────────┐
          │   CACHE & MATERIALIZED VIEWS            │
          │   (Performance Optimization)            │
          │                                         │
          │  • Season_Standings_Cache               │
          │    (Championship standings)             │
          │                                         │
          │  • Top3_Cache                           │
          │    (Quick access top drivers)           │
          │                                         │
          │  • Race_Prediction_Summary              │
          │    (Prediction metadata)                │
          └─────────────────────────────────────────┘
                    │
        ┌───────────┼───────────┐
        │           │           │
        ▼           ▼           ▼
    ┌────────┐  ┌────────┐  ┌────────┐
    │ Web UI │  │ API    │  │Reports │
    │        │  │        │  │        │
    │ Live   │  │ REST   │  │Analytics
    │Standings  │ GraphQL│  │Dashboard
    └────────┘  └────────┘  └────────┘

          ┌────────────────────────────┐
          │  AUDIT & LOGGING           │
          │                            │
          │  • Audit_Log               │
          │  (tracks all changes)      │
          │                            │
          │  • Model_Run_Log           │
          │  (ML execution tracking)   │
          └────────────────────────────┘


```

## Query Pattern Analysis

### Common Query Patterns & Their Relationships

```
PATTERN 1: Championship Standings
─────────────────────────────────
Query: "Get current championship standings for season 2025"
Path:  Season → Race → Race_Result → Driver
                              ↓
Cache:  Season_Standings_Cache (denormalized for performance)
Indexes: idx_standings_cache_season, (season_id, position)

PATTERN 2: Driver Performance History
─────────────────────────────────────
Query: "Get all qualifying results for driver VER in 2025"
Path:  Driver → Qualifying_Result ← Race ← Season
Indexes: idx_qualifying_driver, idx_race_season

PATTERN 3: Lap Time Analysis
────────────────────────────
Query: "Get all lap times for driver in qualifying session at Monaco"
Path:  Track → Race → Session → Lap_Time
              ↓
       filtered by driver_id, session_type, race_date
Indexes: idx_lap_time_race_driver (CRITICAL)
Note:   This query hits the largest table and must be optimized!

PATTERN 4: Race Results & Grid
──────────────────────────────
Query: "Get grid and final positions for all drivers in race R20"
Path:  Race → Race_Result → Driver
           → Qualifying_Result
           → Driver_Team (to get team info)
Indexes: idx_race_result_position, idx_qualifying_position

PATTERN 5: Predictions vs Actual
────────────────────────────────
Query: "Compare model predictions to actual race results"
Path:  Prediction ← Model_Version
       Race_Result
       Joining on (race_id, driver_id)
Indexes: idx_prediction_model_race_driver, idx_race_result_position

PATTERN 6: Tire Strategy Analysis
──────────────────────────────────
Query: "Get tire compounds and pit stops for each driver per lap"
Path:  Lap_Time → Tire_Compound
       filtered by race_id, session_type='race'
Indexes: idx_lap_time_race_driver

PATTERN 7: Top Performers
─────────────────────────
Query: "Get top 3 drivers this season"
Path:  Cache: Top3_Cache (pre-computed)
       Alternative: Season_Standings_Cache ranked by total_points
Indexes: idx_top3_cache_season_rank (trivial with cache)

PATTERN 8: Model Performance Tracking
─────────────────────────────────────
Query: "Compare accuracy of different model versions"
Path:  Model_Version → Prediction ← Race_Result
       Group by model_version, aggregate metrics
Indexes: idx_prediction_model, idx_prediction_generated


```

## Table Dependency Graph

```
LEVEL 0 (Independent reference tables):
────────────────────────────────────────
  Season  ← Foundation (no dependencies)
  Driver  ← Foundation (no dependencies)
  Team    ← Foundation (no dependencies)
  Track   ← Foundation (no dependencies)
  Tire_Compound ← Foundation (no dependencies)
  
  │
  └──────┬──────────┬──────────────────┐
         │          │                  │


LEVEL 1 (Depend on Level 0):
──────────────────────────────
  Driver_Team ← (Driver, Team, Season)
  Race        ← (Season, Track)
  Model_Version ← (Independent but references Level 0 concepts)
  
  │
  ├─────┬─────────┬─────────────────┐
  │     │         │                 │


LEVEL 2 (Depend on Levels 0-1):
──────────────────────────────────
  Session              ← (Race)
  Qualifying_Result    ← (Race, Driver)
  Race_Result          ← (Race, Driver)
  Prediction           ← (Model_Version, Race, Driver)
  
  │
  └───┬─────┬──────────┬──────────────┐
      │     │          │              │


LEVEL 3 (Depend on Levels 0-2):
──────────────────────────────────
  Lap_Time  ← (Race, Session, Driver, Tire_Compound)  [HIGHEST VOLUME]
  
  │
  └────┬──────────────┐
       │              │


LEVEL 4 (Cache/Summary - Depend on Levels 0-3):
─────────────────────────────────────────────────
  Season_Standings_Cache      ← (Season, Driver, Team, Race_Result aggregated)
  Top3_Cache                  ← (Season, Driver, Team, Race_Result aggregated)
  Race_Prediction_Summary     ← (Model_Version, Race, Prediction aggregated)
  
  │
  └────┬────────┬──────────────┐
       │        │              │


LEVEL 5 (Audit/Logging - Capture Levels 0-4):
──────────────────────────────────────────────
  Audit_Log         ← (All tables)
  Model_Run_Log     ← (Model_Version)


DEPENDENCY CRITICAL PATH (for cascading operations):
────────────────────────────────────────────────────
Season → Race → Session → Lap_Time
     ↓      ↓        ↓         ↓
   Races  Results  (cache)  (analytics)

On CASCADE DELETE:
- Deleting Season deletes all related Races
- Deleting Race deletes all Sessions, Lap_Times, Results, Predictions
- This is by design for clean season/race removal

On RESTRICT:
- Cannot delete Driver if they have Race_Results (historical integrity)
- Cannot delete Team if they have Driver_Team records
- Protects historical data integrity

```

## Cardinality Matrix

```
                    │   1:1  │   1:N  │   N:M  │
────────────────────┼────────┼────────┼────────┤
Season              │   N/A  │  Race  │   Team │
                    │        │        │(via DT)│
────────────────────┼────────┼────────┼────────┤
Driver              │   N/A  │Race_R  │  Team  │
                    │        │Pred    │(via DT)│
────────────────────┼────────┼────────┼────────┤
Team                │   N/A  │Drivers │Driver  │
                    │        │(via DT)│(via DT)│
────────────────────┼────────┼────────┼────────┤
Driver_Team         │   N/A  │  N/A   │  N/A   │
(Junction)          │        │        │        │
────────────────────┼────────┼────────┼────────┤
Track               │   N/A  │ Race   │  N/A   │
                    │        │(1:N)   │        │
────────────────────┼────────┼────────┼────────┤
Race                │   N/A  │Session │  N/A   │
                    │        │Result  │        │
                    │        │Predict │        │
────────────────────┼────────┼────────┼────────┤
Session             │   N/A  │Lap_Time│  N/A   │
                    │        │(1:N)   │        │
────────────────────┼────────┼────────┼────────┤
Lap_Time            │   N/A  │  N/A   │  N/A   │
(Leaf node)         │        │        │        │
────────────────────┼────────┼────────┼────────┤
Tire_Compound       │   N/A  │Lap_Time│  N/A   │
                    │        │(1:N)   │        │
────────────────────┼────────┼────────┼────────┤
Model_Version       │   N/A  │Predict │  N/A   │
                    │        │ModelLog│        │
────────────────────┼────────┼────────┼────────┤
Prediction          │   N/A  │  N/A   │  N/A   │
(Leaf node)         │        │        │        │
────────────────────┼────────┼────────┼────────┤

Legend:
N/A  = Not Applicable (no relationship)
Race_R = Race_Result
Pred = Prediction
DT = Driver_Team
```

## Data Integrity & Constraints

### Unique Constraints (Prevent Duplicates)

| Table | Constraint | Purpose |
|-------|-----------|---------|
| season | (year) | Only one season per calendar year |
| driver | (code) | Driver codes must be unique (e.g., VER, HAM) |
| driver | (license_number) | Racing license is unique |
| team | (name), (short_name) | Team names are unique |
| track | (name) | Track names are unique |
| race | (season_id, round) | One race per round per season |
| race | (season_id, track_id, race_date) | Prevent duplicate race events |
| driver_team | (driver_id, season_id) | One primary team per driver per season |
| qualifying_result | (race_id, driver_id) | One qualifying result per driver |
| qualifying_result | (race_id, qualifying_position) | No two drivers same grid position |
| race_result | (race_id, driver_id) | One race result per driver |
| race_result | (race_id, finish_position) | No two drivers same finish position |
| model_version | (version) | Model versions are unique |
| prediction | (model_version_id, race_id, driver_id, generated_at) | Prevent duplicate predictions per model run |
| season_standings_cache | (season_id, driver_id) | One standing per driver per season |
| top3_cache | (season_id, rank) | One driver per rank per season |

### Foreign Key Constraints

| FK Table | References | ON DELETE | Purpose |
|----------|-----------|-----------|---------|
| race | season | RESTRICT | Prevent season deletion with races |
| race | track | RESTRICT | Keep track history |
| driver_team | driver | RESTRICT | Protect driver history |
| driver_team | team | RESTRICT | Protect team history |
| driver_team | season | RESTRICT | Protect season context |
| session | race | CASCADE | Clean session when race deleted |
| lap_time | race | CASCADE | Clean lap data when race deleted |
| lap_time | session | CASCADE | Clean laps when session deleted |
| lap_time | driver | RESTRICT | Protect driver records |
| lap_time | tire_compound | - | Tire reference (no delete action) |
| qualifying_result | race | CASCADE | Clean results when race deleted |
| qualifying_result | driver | RESTRICT | Protect driver history |
| race_result | race | CASCADE | Clean results when race deleted |
| race_result | driver | RESTRICT | Protect driver history |
| prediction | model_version | RESTRICT | Protect model history |
| prediction | race | CASCADE | Clean predictions when race deleted |
| prediction | driver | RESTRICT | Protect driver history |

## Performance Optimization Strategy

### Critical High-Volume Tables

```
TABLE: Lap_Time (10-15M rows per season)
───────────────────────────────────────
Indexes:
  ✓ (race_id, driver_id) - PRIMARY query pattern
  ✓ (race_id, lap_number) - Lap sequence queries
  ✓ (session_id) - Session-based aggregation
  ✓ (driver_id) - Driver statistics
  ✓ (recorded_at) - Time-range queries
  ✓ (is_fastest_lap) partial - Fastest lap identification

Partitioning Strategy:
  OPTION A: Partition by race_id (24 seasons = 24*50K = 1.2M rows per partition)
  OPTION B: Partition by recorded_at (monthly or seasonal)
  OPTION C: Partition by driver_id (50 drivers = 200-300K rows each)
  RECOMMENDED: Option A for race-based analytics


TABLE: Prediction (2.4M rows per season per model)
──────────────────────────────────────────────────
Indexes:
  ✓ (model_version_id, race_id, driver_id) - CRITICAL composite
  ✓ (confidence_score DESC) - Top predictions
  ✓ (generated_at) - Time-based filtering
  ✓ (model_version_id) - Model-specific queries

Partitioning Strategy:
  OPTION A: Partition by model_version_id
  OPTION B: Partition by generated_at (weekly snapshots)
  RECOMMENDED: Option B for time-series analysis


TABLE: Race_Result / Qualifying_Result (~1,200 rows per season)
──────────────────────────────────────────────────────────────
Indexes:
  ✓ (race_id, finish_position/qualifying_position) - CRITICAL
  ✓ (race_id, points_awarded DESC) - Standings queries
  ✓ (driver_id) - Driver result history

No partitioning needed (small table)

```

### Materialized View Strategy

```
PURPOSE: Avoid expensive aggregation queries at runtime

VIEW 1: Season_Standings_Cache
───────────────────────────────
Refresh: After each race
Query: SELECT driver_id, SUM(points_awarded) as total_points, 
              COUNT(*) as races_completed, 
              SUM(CASE WHEN finish_position <= 3 THEN 1 ELSE 0 END) as podiums
       FROM race_result 
       WHERE race_id IN (SELECT id FROM race WHERE season_id = X)
       GROUP BY driver_id

Performance Gain: ~100x faster than real-time aggregation


VIEW 2: Top3_Cache
───────────────────
Refresh: After each race
Query: SELECT TOP 3 drivers by total_points from Season_Standings_Cache
       WHERE season_id = X
       ORDER BY total_points DESC

Performance Gain: O(1) lookup vs. full standings aggregation


VIEW 3: Race_Prediction_Summary
────────────────────────────────
Refresh: After each model run
Query: SELECT COUNT(*), AVG(confidence_score) 
       FROM prediction 
       WHERE model_version_id = X AND race_id = Y

Performance Gain: Instant summary statistics

```

## Data Volume Scaling

```
Estimated Rows by Season (Formula 1):

Small Tables (Reference/Master data):
  Season                    1 row
  Driver                  ~600 rows (includes historical)
  Team                    ~150 rows
  Track                    ~50 rows
  Tire_Compound             5 rows
  Driver_Team             ~800 rows (4 per team per season)
  
  SUBTOTAL:              ~1,600 rows
  
Medium Tables (Per-race data):
  Race                      24 rows (standard calendar)
  Session                  168 rows (7 sessions × 24 races)
  Qualifying_Result      1,200 rows (50 drivers × 24 races)
  Race_Result            1,200 rows (50 finishers × 24 races)
  
  SUBTOTAL:              ~2,600 rows

Large Tables (HIGH-VOLUME):
  Lap_Time          10-15M rows ⚠️ LARGEST
  Prediction         2.4M rows (100 drivers × 24 races × 1M+ model runs)
  
  TOTAL HIGH-VOLUME:   12.4-17.4M rows

Cache/Log Tables (Growth over time):
  Season_Standings_Cache  ~2,000 rows (updates/season)
  Top3_Cache              ~500 rows (updates/race)
  Race_Prediction_Summary ~500 rows (runs/season)
  Audit_Log              Variable (depends on update frequency)
  Model_Run_Log          1,000s rows (multiple runs/season)

TOTAL TABLES: ~25-30M rows per season (excluding audit logs)

Storage Estimates:
  Lap_Time:              ~150-200 GB (with indexes)
  Prediction:            ~25-40 GB (with indexes)
  All other tables:      ~2-5 GB
  ────────────────────────────
  TOTAL:                 ~180-250 GB per season
  
  For 10-year history:   1.8-2.5 TB
  With backups/replicas: 5-7 TB total infrastructure

```

---

**Document Version**: 1.0  
**Last Updated**: 2025-12-17  
**Related Files**:
- [F1Predictor_UML_ClassDiagram.md](./F1Predictor_UML_ClassDiagram.md)
- [F1Predictor_UML_DBML.dbml](./F1Predictor_UML_DBML.dbml) (View at dbdiagram.io)
- [schema.sql](../database/schema.sql)
