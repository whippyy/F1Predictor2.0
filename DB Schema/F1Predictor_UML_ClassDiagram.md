# F1 Predictor 2.0 - UML Class Diagram

## Entity-Relationship Diagram (ERD)

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                    F1 PREDICTOR 2.0 DATABASE SCHEMA UML                         │
└─────────────────────────────────────────────────────────────────────────────────┘

CORE ENTITIES
═════════════════════════════════════════════════════════════════════════════════

┌──────────────────┐          ┌──────────────────┐          ┌──────────────────┐
│     Season       │          │     Driver       │          │      Team        │
├──────────────────┤          ├──────────────────┤          ├──────────────────┤
│ + id: INT PK     │          │ + id: INT PK     │          │ + id: INT PK     │
│ + year: INT      │          │ + full_name: STR │          │ + name: STR      │
│ + name: STR      │          │ + code: STR(3)   │          │ + short_name: STR│
│ + rounds: INT    │          │ + driver_number  │          │ + team_color: HEX│
│ + created_at     │          │ + date_of_birth  │          │ + logo_url: URL  │
│ + updated_at     │          │ + nationality    │          │ + headquarters   │
└──────────────────┘          │ + headshot_url   │          │ + founded_year   │
       │                       │ + license_number │          │ + created_at     │
       │ 1:N                   │ + created_at     │          │ + updated_at     │
       │                       │ + updated_at     │          └──────────────────┘
       └─────────────────┬─────┴──────────────────┘                  ▲
             ┌───────────┴──────────────┐                            │ N:M
             │                          │                            │ (season)
             │  ┌──────────────────────────────────┐                │
             │  │     Driver_Team (N:M Join)       │                │
             │  ├──────────────────────────────────┤                │
             │  │ + id: INT PK                     │                │
             │  │ + driver_id: FK → Driver         │────────────────┘
             │  │ + team_id: FK → Team             │────┐
             │  │ + season_id: FK → Season         │    │
             │  │ + start_date: DATE               │    │
             │  │ + end_date: DATE                 │    │
             │  │ + role: STR                      │    │
             │  │ + created_at                     │    │
             │  │ + updated_at                     │    │
             │  └──────────────────────────────────┘    │
             │                                          │
             └──────────────────────────────────────────┘


┌──────────────────┐          ┌──────────────────┐
│      Track       │          │      Race        │
├──────────────────┤          ├──────────────────┤
│ + id: INT PK     │ 1:N      │ + id: INT PK     │
│ + name: STR      │◄─────────│ + season_id: FK  │
│ + country: STR   │          │ + track_id: FK   │
│ + city: STR      │          │ + round: INT     │
│ + location: STR  │          │ + name: STR      │
│ + length_m: FLOAT│          │ + race_date: DATE│
│ + turns: INT     │          │ + sprint_race    │
│ + corners: INT   │          │ + wiki_url: URL  │
│ + drs_zones: INT │          │ + created_at     │
│ + latitude: FLOAT│          │ + updated_at     │
│ + longitude      │          └──────────────────┘
│ + circuit_url    │                  │ 1:N
│ + created_at     │                  │
│ + updated_at     │                  │
└──────────────────┘                  │


SESSION & TIMING ENTITIES
═════════════════════════════════════════════════════════════════════════════════

             ┌──────────────────────────────────┐
             │      Session                     │
             ├──────────────────────────────────┤
             │ + id: INT PK                     │
    ┌─────── │ + race_id: FK → Race             │
    │        │ + session_type: STR              │
    │        │ + started_at: TIMESTAMP          │
    │        │ + ended_at: TIMESTAMP            │
    │        │ + weather_condition: STR         │
    │        │ + track_temperature_c: FLOAT     │
    │        │ + air_temperature_c: FLOAT       │
    │        │ + status: STR                    │
    │        │ + created_at                     │
    │        │ + updated_at                     │
    │        └──────────────────────────────────┘
    │                   │
    │ 1:N              │ 1:N
    │                  │
    └─────┐      ┌──────┘
          │      │
          │      ▼
    ┌──────────────────────────────────┐
    │      Lap_Time                    │
    ├──────────────────────────────────┤
    │ + id: BIGSERIAL PK               │
    │ + race_id: FK → Race             │
    │ + session_id: FK → Session       │
    │ + driver_id: FK → Driver         │
    │ + lap_number: INT                │
    │ + lap_time_ms: INT               │
    │ + sector1_ms: INT                │
    │ + sector2_ms: INT                │
    │ + sector3_ms: INT                │
    │ + tire_compound_id: FK → Compound│
    │ + pit_stop: BOOLEAN              │
    │ + pit_loss_ms: INT               │
    │ + is_fastest_lap: BOOLEAN        │
    │ + status: STR                    │
    │ + recorded_at: TIMESTAMP         │
    │ + created_at                     │
    └──────────────────────────────────┘

┌──────────────────────────────┐
│   Tire_Compound              │
├──────────────────────────────┤
│ + id: INT PK                 │
│ + name: STR                  │
│ + code: STR(5)               │
│ + color: HEX                 │
│ + created_at: TIMESTAMP      │
└──────────────────────────────┘


RESULTS ENTITIES
═════════════════════════════════════════════════════════════════════════════════

              ┌─────────────────────────────────────┐
              │    Qualifying_Result                │
              ├─────────────────────────────────────┤
              │ + id: BIGSERIAL PK                  │
              │ + race_id: FK → Race                │
              │ + driver_id: FK → Driver            │
              │ + q1_time_ms: INT                   │
              │ + q2_time_ms: INT                   │
              │ + q3_time_ms: INT                   │
              │ + qualifying_position: INT          │
              │ + status: STR                       │
              │ + created_at: TIMESTAMP             │
              │ + updated_at: TIMESTAMP             │
              └─────────────────────────────────────┘

              ┌─────────────────────────────────────┐
              │    Race_Result                      │
              ├─────────────────────────────────────┤
              │ + id: BIGSERIAL PK                  │
              │ + race_id: FK → Race                │
              │ + driver_id: FK → Driver            │
              │ + grid_position: INT                │
              │ + finish_position: INT              │
              │ + points_awarded: FLOAT             │
              │ + laps_completed: INT               │
              │ + race_status: STR                  │
              │ + fastest_lap: BOOLEAN              │
              │ + pit_stops: INT                    │
              │ + total_race_time: STR              │
              │ + time_behind_leader_ms: INT        │
              │ + created_at: TIMESTAMP             │
              │ + updated_at: TIMESTAMP             │
              └─────────────────────────────────────┘


PREDICTION & MODEL ENTITIES
═════════════════════════════════════════════════════════════════════════════════

┌──────────────────────────────────┐
│    Model_Version                 │
├──────────────────────────────────┤
│ + id: INT PK                     │
│ + name: STR                      │
│ + version: STR                   │
│ + description: TEXT              │
│ + model_type: STR                │
│ + training_data_start_year: INT  │
│ + training_data_end_year: INT    │
│ + trained_at: TIMESTAMP          │
│ + accuracy: FLOAT                │
│ + precision: FLOAT               │
│ + recall: FLOAT                  │
│ + f1_score: FLOAT                │
│ + metrics: JSONB                 │
│ + is_active: BOOLEAN             │
│ + created_at: TIMESTAMP          │
│ + updated_at: TIMESTAMP          │
└──────────────────────────────────┘
           │
           │ 1:N
           │
           ▼
┌──────────────────────────────────────────┐
│         Prediction                       │
├──────────────────────────────────────────┤
│ + id: BIGSERIAL PK                       │
│ + model_version_id: FK → Model_Version   │
│ + race_id: FK → Race                     │
│ + driver_id: FK → Driver                 │
│ + predicted_qualifying_position: INT     │
│ + predicted_race_position: INT           │
│ + predicted_points: FLOAT                │
│ + win_probability: FLOAT (0.0-1.0)       │
│ + podium_probability: FLOAT              │
│ + confidence_score: FLOAT (0.0-1.0)      │
│ + qualifying_confidence: FLOAT           │
│ + race_confidence: FLOAT                 │
│ + extra_data: JSONB                      │
│ + generated_at: TIMESTAMP                │
│ + created_at: TIMESTAMP                  │
│ + updated_at: TIMESTAMP                  │
│ UNIQUE(model_version_id, race_id,        │
│        driver_id, generated_at)          │
└──────────────────────────────────────────┘


CACHE & MATERIALIZED VIEW ENTITIES
═════════════════════════════════════════════════════════════════════════════════

┌──────────────────────────────────────────┐
│   Season_Standings_Cache                 │
├──────────────────────────────────────────┤
│ + id: INT PK                             │
│ + season_id: FK → Season                 │
│ + driver_id: FK → Driver                 │
│ + team_id: FK → Team (optional)          │
│ + position: INT                          │
│ + total_points: FLOAT                    │
│ + wins: INT                              │
│ + podiums: INT                           │
│ + races_completed: INT                   │
│ + cached_at: TIMESTAMP                   │
│ + updated_at: TIMESTAMP                  │
│ UNIQUE(season_id, driver_id)             │
└──────────────────────────────────────────┘

┌──────────────────────────────────────────┐
│      Top3_Cache                          │
├──────────────────────────────────────────┤
│ + id: INT PK                             │
│ + season_id: FK → Season                 │
│ + rank: INT (1-3)                        │
│ + driver_id: FK → Driver                 │
│ + team_id: FK → Team (optional)          │
│ + total_points: FLOAT                    │
│ + wins: INT                              │
│ + cached_at: TIMESTAMP                   │
│ UNIQUE(season_id, rank)                  │
└──────────────────────────────────────────┘

┌──────────────────────────────────────────┐
│  Race_Prediction_Summary                 │
├──────────────────────────────────────────┤
│ + id: INT PK                             │
│ + model_version_id: FK → Model_Version   │
│ + race_id: FK → Race                     │
│ + total_predictions: INT                 │
│ + avg_confidence: FLOAT                  │
│ + generated_at: TIMESTAMP                │
│ + cached_at: TIMESTAMP                   │
│ UNIQUE(model_version_id, race_id,        │
│        generated_at)                     │
└──────────────────────────────────────────┘


AUDIT & LOGGING ENTITIES
═════════════════════════════════════════════════════════════════════════════════

┌──────────────────────────────────────┐
│      Audit_Log                       │
├──────────────────────────────────────┤
│ + id: BIGSERIAL PK                   │
│ + table_name: STR                    │
│ + operation: STR (INSERT/UPDATE/DEL) │
│ + record_id: INT                     │
│ + old_values: JSONB                  │
│ + new_values: JSONB                  │
│ + changed_by: STR                    │
│ + changed_at: TIMESTAMP              │
└──────────────────────────────────────┘

┌──────────────────────────────────────┐
│    Model_Run_Log                     │
├──────────────────────────────────────┤
│ + id: INT PK                         │
│ + model_version_id: FK → Model_Vers. │
│ + started_at: TIMESTAMP              │
│ + completed_at: TIMESTAMP            │
│ + status: STR (running/completed/err)│
│ + predictions_generated: INT         │
│ + error_message: TEXT                │
│ + execution_time_seconds: FLOAT      │
│ + created_at: TIMESTAMP              │
└──────────────────────────────────────┘


RELATIONSHIP SUMMARY
═════════════════════════════════════════════════════════════════════════════════

1:N Relationships:
─────────────────
• Season → Race (1:N)
• Track → Race (1:N)
• Race → Session (1:N)
• Race → Lap_Time (1:N)
• Race → Qualifying_Result (1:N)
• Race → Race_Result (1:N)
• Race → Prediction (1:N)
• Driver → Driver_Team (1:N)
• Team → Driver_Team (1:N)
• Season → Driver_Team (1:N)
• Session → Lap_Time (1:N)
• Driver → Lap_Time (1:N)
• Tire_Compound → Lap_Time (1:N)
• Driver → Qualifying_Result (1:N)
• Driver → Race_Result (1:N)
• Model_Version → Prediction (1:N)
• Model_Version → Model_Run_Log (1:N)
• Model_Version → Race_Prediction_Summary (1:N)

N:M Relationships (with join table):
────────────────────────────────────
• Driver ↔ Team (via Driver_Team, scoped to Season)

UNIQUE CONSTRAINTS (preventing duplicates):
──────────────────────────────────────────
• Season: (year)
• Driver: (code), (license_number)
• Team: (name), (short_name)
• Track: (name)
• Race: (season_id, round), (season_id, track_id, race_date)
• Driver_Team: (driver_id, season_id)
• Lap_Time: None (high-volume table)
• Qualifying_Result: (race_id, driver_id), (race_id, qualifying_position)
• Race_Result: (race_id, driver_id), (race_id, finish_position)
• Tire_Compound: (name)
• Model_Version: (version)
• Prediction: (model_version_id, race_id, driver_id, generated_at)
• Season_Standings_Cache: (season_id, driver_id)
• Top3_Cache: (season_id, rank)
• Race_Prediction_Summary: (model_version_id, race_id, generated_at)

FOREIGN KEY CONSTRAINTS:
───────────────────────
ON DELETE RESTRICT (prevents deletion if referenced):
• race(season_id) → season
• driver_team(driver_id) → driver
• driver_team(team_id) → team
• driver_team(season_id) → season
• race(track_id) → track
• lap_time(driver_id) → driver
• session(race_id) → race
• lap_time(tire_compound_id) → tire_compound
• qualifying_result(driver_id) → driver
• race_result(driver_id) → driver
• prediction(model_version_id) → model_version
• prediction(driver_id) → driver

ON DELETE CASCADE (deletes dependent records):
• lap_time(race_id) → race
• lap_time(session_id) → session
• session(race_id) → race
• qualifying_result(race_id) → race
• race_result(race_id) → race
• prediction(race_id) → race
• All cache/log tables


KEY INDEXES FOR PERFORMANCE:
───────────────────────────
Critical Composite Indexes:
• idx_driver_team_driver_season: (driver_id, season_id)
• idx_lap_time_race_driver: (race_id, driver_id)
• idx_lap_time_lap_number: (race_id, lap_number)
• idx_prediction_model_race_driver: (model_version_id, race_id, driver_id)
• idx_race_season_round: (season_id, round)
• idx_race_result_position: (race_id, finish_position)

Partial Indexes:
• idx_lap_time_fastest: (is_fastest_lap) WHERE is_fastest_lap = TRUE
• idx_model_version_active: (is_active) WHERE is_active = TRUE

```

## Cardinality Analysis

### Core Entity Relationships

| From | To | Type | Cardinality | Notes |
|------|-----|------|-------------|-------|
| Season | Race | 1:N | One season has many races | Multiple rounds per season |
| Track | Race | 1:N | One track hosts multiple races | Same circuit in different seasons |
| Race | Session | 1:N | One race has multiple sessions | FP1, FP2, FP3, Q, Race, Sprint |
| Race | Driver (via results) | N:M | Multiple drivers per race | Many drivers complete a race |
| Driver | Team | N:M | Driver changes teams over seasons | Via Driver_Team junction table |
| Session | Lap_Time | 1:N | One session has millions of laps | Largest high-volume table |
| Driver | Lap_Time | 1:N | One driver produces many lap times | Multiple sessions per season |
| Model_Version | Prediction | 1:N | One model generates predictions | Multiple predictions per model run |
| Race | Prediction | 1:N | Multiple predictions per race | One per driver per model |
| Season | Cache Tables | 1:N | Season generates cache records | Updated after each race |

## Data Volume Estimates

| Table | Records/Season | Growth Pattern | Notes |
|-------|-----------------|-----------------|-------|
| Season | 1 | Yearly | One per calendar year |
| Driver | ~600 | Annual additions | Includes current + historical |
| Team | ~150 | Annual updates | Main + reserve teams |
| Driver_Team | ~800 | Annual | ~4 drivers per team per season |
| Track | ~50 | Stable | Few changes year-to-year |
| Race | ~24 | Stable | Standard F1 calendar |
| Session | ~168 | Stable | 7 sessions per race × 24 races |
| Lap_Time | ~10-15M | Very High | **Primary scaling concern** |
| Qualifying_Result | ~1,200 | Stable | 50 drivers × 24 races |
| Race_Result | ~1,200 | Stable | 50 finishers × 24 races |
| Prediction | ~2.4M | High | 100 drivers × 24 races × 1M model runs |
| Audit_Log | Variable | Moderate | Depends on update frequency |

---

**UML Diagram Version**: 1.0  
**Database Version**: PostgreSQL 12+  
**Last Updated**: 2025-12-17  
**Schema Definition**: [schema.sql](../database/schema.sql)
