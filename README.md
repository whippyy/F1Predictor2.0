# F1 Predictor 2.0

A machine learning-based Formula 1 race prediction system for the 2025 season.

## Database Schema

The project uses PostgreSQL with a comprehensive database schema. For detailed information:

- **[schema.sql](./database/schema.sql)** - Complete SQL schema with all tables, indexes, and triggers
- **[SCHEMA_DOCUMENTATION.md](./database/SCHEMA_DOCUMENTATION.md)** - In-depth documentation of design decisions, entity relationships, and performance considerations
- **[QUICK_REFERENCE.md](./database/QUICK_REFERENCE.md)** - Quick reference for common queries and operations
- **[seed_data.sql](./database/seed_data.sql)** - Sample data for testing and development

### Quick Start

```bash
# Make setup script executable
chmod +x database/setup_database.sh

# Run initial setup
database/setup_database.sh f1predictor f1_app localhost 5432

# Load sample data (optional)
psql -h localhost -U f1_app -d f1predictor -f database/seed_data.sql
```

## Problem Statement

The core problem this project aims to solve is:
> To create an accurate prediction system for Formula 1 race outcomes by analyzing historical data and current season performance metrics, while accounting for the complex variables that influence race results.

### Problem Boundaries

1. **Scope Inclusions**:
   - Race position predictions
   - Qualifying position predictions
   - Driver performance analysis
   - Track-specific performance metrics
   - Current season (2025) data integration

2. **Scope Exclusions**:
   - Weather prediction
   - Team strategy predictions
   - Car development forecasts
   - Financial performance analysis

## 2. Analysis

### 2.1 Data Requirements Analysis

#### 2.1.1 Input Data Specification

**Historical Data Sources**
- **Race Results Data**
  - Source: Previous seasons (2010-2024) F1 championship data
  - Format: CSV files with race position, points, DNF status
  - Frequency: Seasonal import
  - Fields: Driver ID, Race ID, Qualifying Position, Race Position, Points, Laps Completed, Fastest Lap

- **Qualifying Data**
  - Source: Official FIA records
  - Format: CSV with lap times from each qualifying session (Q1, Q2, Q3)
  - Frequency: One set per race weekend
  - Fields: Driver ID, Track ID, Session Type, Lap Time, Position, Status

- **Lap Time Data**
  - Source: Race timing feeds
  - Format: CSV with individual lap times
  - Granularity: Lap-by-lap timing data
  - Fields: Driver ID, Lap Number, Lap Time, Tire Compound, Pit Stop Info

- **Track Information**
  - Source: Circuit specifications database
  - Data: Track length, number of corners, DRS zones, safety car frequency
  - Format: JSON/CSV database records
  - Update Frequency: Seasonal or as circuits change

- **Driver Historical Performance**
  - Source: Career statistics database
  - Data: Driver experience, previous championships, podium finishes, DNF rate
  - Format: Structured database records
  - Retention: Complete career history

**Real-time Data Feeds**
- **Live Timing API**
  - Protocol: WebSocket/REST API
  - Frequency: Real-time updates during F1 sessions
  - Data Points: Current position, gap to leader, sector times, tire information
  - Latency Requirement: < 2 seconds

- **Current Season Statistics**
  - Championship standings
  - Driver current points tally
  - Team standings
  - Update Frequency: After every race event

- **Environmental Data**
  - Track conditions (Dry/Wet/Damp)
  - Temperature readings
  - Weather forecasts for race weekends
  - Source: Official FIA data + Weather APIs

#### 2.1.2 Data Quality Requirements
- **Accuracy**: 99.5% accuracy for historical data
- **Completeness**: 100% coverage of race weekends from 2010 onwards
- **Consistency**: Standardized format across all data sources
- **Timeliness**: Real-time feeds updated within 2-second intervals
- **Validation**: Duplicate detection and anomaly identification

### 2.2 Processing Requirements Analysis

#### 2.2.1 Computational Specifications

**Hardware Requirements**
- **Server CPU**: Multi-core processor (minimum 8 cores, recommended 16+)
  - Processing: Real-time prediction calculations
  - Model Training: Parallel batch processing
  - Requirement: Intel Xeon/AMD EPYC or equivalent

- **GPU Support**
  - Type: NVIDIA GPU with CUDA support
  - VRAM: Minimum 6GB, recommended 12GB+
  - Purpose: Model training acceleration
  - Benefit: 10-50x faster training compared to CPU-only

- **System RAM**
  - Minimum: 16GB
  - Recommended: 32GB+
  - Allocation: 60% for model data, 25% for cache, 15% for system operations

- **Storage**
  - SSD Primary: 500GB (OS, models, active data)
  - HDD Backup: 2TB (historical data archive)
  - Requirement: Random access latency < 5ms

**Network Requirements**
- **Bandwidth**: Minimum 100 Mbps for data feeds
- **Latency**: < 50ms to data provider API
- **Uptime**: 99.9% availability
- **Concurrent Connections**: Support 1000+ concurrent API calls

#### 2.2.2 Data Processing Pipeline

**Data Ingestion Stage**
1. **Validation Layer**: Check data format, completeness, and integrity
2. **Normalization**: Convert all data to standard units and formats
3. **Deduplication**: Remove redundant records
4. **Storage**: Save to PostgreSQL with backup archival
5. **Processing Time**: Batch jobs run nightly, real-time updates every 60 seconds

**Feature Engineering Stage**
- **Statistical Features**
  - Rolling averages (3-race, season average lap times)
  - Volatility metrics (performance variance)
  - Trend analysis (improving/declining performance)

- **Comparative Features**
  - Driver-vs-Track historical matching
  - Team performance indices
  - Relative performance to teammates

- **Temporal Features**
  - Season progression (early/mid/late season form)
  - Track familiarization (first visit vs. repeat visits)
  - Weather adaptation metrics

**Model Training Pipeline**
- **Frequency**: Weekly updates with latest race data
- **Validation**: 80/20 train-test split with cross-validation
- **Batch Size**: 32-64 samples per batch
- **Epochs**: 50-100 training epochs
- **Training Time**: 4-8 hours on GPU, 24-48 hours on CPU

**Prediction Generation**
- **Batch Processing**: Generate predictions for all upcoming races nightly
- **Real-time Updates**: Update predictions as qualifying/practice data becomes available
- **Output Generation**: Create JSON predictions for API consumption
- **Latency Requirement**: Predictions available within 2 minutes of latest data input

### 2.3 Memory Management Specifications

#### 2.3.1 Runtime Memory Architecture

**Cache Management**
- **L1 Cache**: Most frequently accessed driver profiles (Top 10 drivers)
  - Size: 512MB
  - TTL: 1 hour
  - Eviction Policy: LRU (Least Recently Used)

- **L2 Cache**: Historical race data for current season
  - Size: 2GB
  - TTL: 24 hours
  - Eviction Policy: Time-based expiration

- **L3 Cache**: Pre-computed predictions
  - Size: 1GB
  - TTL: 6 hours
  - Refresh: Updated after new qualifying/practice sessions

**Memory Pooling Strategy**
- Pre-allocate buffers for concurrent predictions
- Connection pooling for database access (minimum 20 connections)
- Thread pool for parallel processing (8-16 threads)
- Memory reuse to minimize garbage collection overhead

#### 2.3.2 Storage Requirements

**Database Schema**
- **Drivers Table**: 1,000 records × 50 columns ≈ 5MB
- **Races Table**: 75 races per season × 50 columns ≈ 2MB
- **Race Results**: 1,500 records per season × 30 columns ≈ 50MB
- **Lap Times**: 30,000,000+ lap records ≈ 2GB
- **Predictions**: 5,000 predictions × 100 columns ≈ 500MB
- **Total Active Database**: ~2.5GB

**Data Archival Policy**
- Current Season: Keep in fast SSD storage
- Past 5 Years: Keep in warm storage (HDD)
- Older Data: Archive to cloud storage
- Retention Period: Minimum 10 years

**Backup Strategy**
- Daily incremental backups (1GB per day)
- Weekly full backups (2.5GB per week)
- Redundancy: 3 copies maintained across different locations
- Recovery Time Objective (RTO): 4 hours
- Recovery Point Objective (RPO): 1 hour

### 2.4 Error Handling & Validation

#### 2.4.1 Data Validation Framework

**Input Validation**
- **Schema Validation**: Verify data structure matches expected format
- **Type Checking**: Ensure numeric fields contain valid numbers (not strings)
- **Range Validation**: Check values are within acceptable ranges
  - Lap times: > 60 seconds and < 300 seconds
  - Positions: 1-20 for valid finishes
  - Points: 0-25 per race
- **Temporal Validation**: Verify timestamps are logically sequential

**Data Consistency Checks**
- **Referential Integrity**: Foreign key validation (Driver exists before referencing)
- **Duplicate Detection**: Identify and flag duplicate entries
- **Cross-field Validation**: Ensure related fields are logically consistent
  - If DNF flag set, Race Position should be >20
  - If fastest lap awarded, must be in top 10
- **Audit Trail**: Log all validation failures with timestamps

**Anomaly Detection**
- **Statistical Outliers**: Flag lap times > 3 standard deviations
- **Missing Data Handler**:
  - Missing qualifying times: Use historical average for that driver/track
  - Missing practice data: Use previous season equivalent
  - Missing race data: Mark as DNF if not reported
- **Business Logic Validation**: Verify points calculations match FIA rules

#### 2.4.2 System Error Handling

**Error Classification**
- **Critical Errors** (System Down)
  - Database connection failure
  - Model loading failure
  - API authentication failure
  - Action: Immediate alert to admin, activate backup system

- **High Priority Errors** (Reduced Functionality)
  - Real-time feed delay > 5 minutes
  - Prediction accuracy < 70%
  - Cache miss rate > 50%
  - Action: Log error, attempt recovery, notify operations team

- **Medium Priority Errors** (Degraded Performance)
  - Individual API call timeout
  - Single data source unavailable
  - Memory usage > 90%
  - Action: Log error, trigger automatic recovery

- **Low Priority Errors** (Informational)
  - Cache miss (non-critical)
  - User input validation failure
  - Deprecated API call
  - Action: Log for monitoring, no user impact

**Recovery Procedures**
- **Automatic Retry**: Exponential backoff (1s, 2s, 4s, 8s, 16s) for transient failures
- **Circuit Breaker Pattern**: Disable failing service for 5 minutes, retry periodically
- **Fallback Data**: Use cached/historical data when real-time sources unavailable
- **Graceful Degradation**: Show historical predictions if current models unavailable

**Monitoring & Alerting**
- **Real-time Dashboards**: System health status, error rates, performance metrics
- **Alert Thresholds**:
  - Error rate > 5%: Warning alert
  - Error rate > 10%: Critical alert
  - Response time > 5 seconds: Warning
  - Response time > 10 seconds: Critical
- **Logging**: All errors logged with severity, timestamp, context, and resolution
- **Reporting**: Daily error summary, weekly trends analysis

### 2.5 Interface & Integration Requirements

#### 2.5.1 External System Integration

**F1 Data Provider API**
- **Endpoint**: Official FIA Live Timing API or third-party provider (Ergast API)
- **Authentication**: API key-based authentication
- **Rate Limits**: 100 requests per minute
- **Data Format**: JSON responses
- **Endpoints Required**:
  - Driver standings (GET /drivers/standings)
  - Race schedule (GET /races)
  - Race results (GET /races/{raceId}/results)
  - Qualifying results (GET /races/{raceId}/qualifying)

**Weather Data Services**
- **Provider**: OpenWeatherMap or WeatherAPI
- **Data Points**: Temperature, precipitation, wind speed, humidity
- **Update Frequency**: Every 30 minutes
- **Accuracy**: ±1°C temperature precision

**Time Synchronization**
- **NTP Server**: Use pool.ntp.org for system clock sync
- **Frequency**: Continuous sync with 5-minute checks
- **Tolerance**: ±100ms deviation acceptable

**Authentication Services**
- **User Authentication**: OAuth 2.0 or JWT tokens
- **Session Management**: 24-hour expiration for security
- **Role-Based Access**: Admin, Editor, Viewer roles

#### 2.5.2 Frontend Interface Requirements

**UI Framework**
- **Technology Stack**: React.js (v18+) or Vue.js
- **State Management**: Redux or Vuex for predictable state
- **Responsive Design**: Mobile-first approach, support 320px to 4K displays
- **Accessibility**: WCAG 2.1 AA compliance

**Component Specifications**
- **Dashboard Components**:
  - Championship standings table (sortable, filterable)
  - Driver card component (click-to-expand detailed view)
  - Race card component (upcoming and completed races)
  - Prediction confidence indicator (visual gauge 0-100%)
  - Lap time graph (interactive line chart with hover details)

- **Performance Requirements**:
  - Page load time: < 3 seconds
  - API response time: < 500ms
  - Driver card click-to-detail: < 1 second
  - Chart rendering: < 2 seconds

- **Real-time Updates**:
  - WebSocket connection for live updates
  - Auto-refresh every 60 seconds when idle
  - Immediate refresh on user interaction

#### 2.5.3 Backend API Specification

**API Endpoints**

| Method | Endpoint | Purpose | Response Time |
|--------|----------|---------|----------------|
| GET | /api/standings | Get current championship standings | 200ms |
| GET | /api/drivers/{id}/predictions | Get driver season predictions | 500ms |
| GET | /api/races/{id}/predictions | Get specific race predictions | 500ms |
| GET | /api/races/{id}/results | Get race results | 300ms |
| POST | /api/predictions/refresh | Trigger prediction refresh | 5000ms |
| GET | /api/health | System health check | 100ms |

**Response Format (JSON)**
```json
{
  "status": "success|error",
  "data": {},
  "timestamp": "ISO8601",
  "confidence": "0-100",
  "cached": "boolean"
}
```

**Error Response**
```json
{
  "status": "error",
  "error_code": "ERR_CODE",
  "message": "Human readable error",
  "timestamp": "ISO8601"
}
```

### 2.6 Output Format & Display Requirements

#### 2.6.1 Prediction Output Formats

**API Output (JSON)**
- Structured prediction data for programmatic consumption
- Includes confidence intervals and model version
- Timestamp of prediction generation
- Data lineage (which training data was used)

**Web Visualization Output**
- Interactive charts and graphs
- Responsive design for all screen sizes
- Real-time updates via WebSocket
- Export to PNG/PDF capability

**CSV Export Format**
- Driver predictions by race
- Historical accuracy tracking
- Season summary statistics
- Shareable with stakeholders

**PDF Report Format**
- Professional formatting
- Executive summary section
- Detailed predictions with confidence levels
- Methodology explanation

#### 2.6.2 Display Specifications

**Championship Standings Display**
```
Position | Driver Name    | Team           | Points | Trend
---------|----------------|----------------|--------|-------
   1     | Max Verstappen | Oracle Red Bull|  380   |  ↑↑↑
   2     | Charles Leclerc| Scuderia Ferrari|350    |  ↑↑
   3     | Lewis Hamilton | Mercedes       | 340    |  ↓
```

**Driver Prediction Card Display**
- Driver name and team logo
- Current points and position
- Season win probability (%)
- Championship probability (%)
- Next race prediction
- Recent form indicator (5-race trend)

**Race Prediction Display**
- Qualifying position predictions (ranked 1-20)
- Race finish position predictions (ranked 1-20)
- Predicted fastest lap driver
- Confidence interval for each prediction
- Historical accuracy for this specific driver-track combination

**Lap Time Predictions**
- Line graph showing predicted lap times across season
- Comparison with historical averages
- Track-by-track breakdown
- Seasonal trend analysis

#### 2.6.3 Data Visualization Standards

**Color Coding Scheme**
- Top 3 Drivers: Gold, Silver, Bronze
- Point Leaders by Team: Team brand colors
- Positive Trend: Green
- Negative Trend: Red
- Neutral: Gray

**Chart Types**
- Time Series: Line graphs with hover tooltips
- Comparisons: Bar charts for side-by-side analysis
- Distributions: Histograms for probability ranges
- Rankings: Ranked tables with sorting/filtering

**Tooltip Specifications**
- Hover delay: 300ms
- Display information: Value, date, confidence interval
- Format: Decimal precision based on data type
- Mobile: Tap-to-show tooltips (30-second display timeout)

## Core Requirements

### Functional Requirements

1. **Data Collection & Processing**
   - Historical race data integration
   - Real-time 2025 season data updates
   - Track-specific performance metrics
   - Qualifying and race results
   - Lap time data

2. **Prediction Capabilities**
   - Qualifying position predictions
   - Race position predictions
   - Lap time estimations
   - Points calculations

3. **User Interface**
   - Driver standings dashboard
   - Interactive driver cards with detailed race history
   - Track-specific result views
   - Performance visualization

### Technical Requirements

1. **Model Requirements**
   - TensorFlow-based prediction model
   - Historical data training capabilities
   - Real-time data integration
   - Accuracy metrics and validation

2. **Data Storage**
   - PostgreSQL database implementation
   - Efficient data loader for CSV processing
   - Real-time data update mechanism

3. **Performance Requirements**
   - Quick prediction generation
   - Responsive user interface
   - Regular model updates
   - Historical data analysis

## Success Metrics

1. **Prediction Accuracy**
   - Qualifying position prediction accuracy
   - Race position prediction accuracy
   - Points prediction accuracy

2. **System Performance**
   - Response time for predictions
   - Data processing efficiency
   - User interface responsiveness

## Challenges and Considerations

1. **Car Performance Variability**
   - Different cars have varying performance levels
   - Need to normalize lap times across different car specifications
   - Account for car development throughout the season

2. **Track-Specific Factors**
   - Different track characteristics
   - Historical performance patterns
   - Track evolution during race weekends

3. **Driver-Specific Factors**
   - Individual driving styles
   - Experience on specific tracks
   - Historical performance patterns

## Future Enhancements

- Integration with additional data sources
- Advanced visualization features
- Mobile application development
- Real-time race predictions
- Strategy simulation capabilities

## User Interface Flow

### Main Page Layout
```
+------------------------------------------+
|              F1 Predictor 2.0            |
+------------------------------------------+
|                                          |
|  +----------------------------------+    |
|  |           Top 3 Drivers          |    |
|  |----------------------------------|    |
|  | 1. [Driver Name]     [Points]    |    |
|  | 2. [Driver Name]     [Points]    |    |
|  | 3. [Driver Name]     [Points]    |    |
|  +----------------------------------+    |
|                                          |
|  +----------------------------------+    |
|  |         Remaining Drivers        |    |
|  |----------------------------------|    |
|  | 4. [Driver Name]     [Points]    |    |
|  | 5. [Driver Name]     [Points]    |    |
|  |            ...                   |    |
|  | 20.[Driver Name]     [Points]    |    |
|  +----------------------------------+    |
|                                          |
+------------------------------------------+
```

### User Interaction Flow
```
                    Main Page
                       |
            +---------+---------+
            |                   |
     Click Driver Card    Click Race Card
            |                   |
    +-------+-------+    +-----+-----+
    |               |    |           |
Driver Predictions  |    |  Race     |
- Season Overview   |    |  Results  |
- Qualifying Pred.  |    |  - Grid   |
- Race Predictions  |    |  - Result |
- Points Projection |    |  - Times  |
    |               |    |           |
    +-------+-------+    +-----------+
            |
    Click Specific Race
            |
    +-------+-------+
    |               |
Detailed Analysis
- Qual Prediction
- Race Prediction
- Lap Time Pred.
- Position Changes
```

### Interactive Elements

1. **Driver Cards**
   ```
   +-------------------------+
   |     [Driver Photo]      |
   |   [Driver Name]        |
   |   [Team]              |
   |   [Current Points]    |
   |   [Current Position]  |
   +-------------------------+
   ```
   - Clickable to view detailed predictions
   - Color-coded by team
   - Dynamic updates with new predictions

2. **Race Cards**
   ```
   +-------------------------+
   |     [Circuit Layout]    |
   |   [Race Name]          |
   |   [Date]              |
   |   [Prediction Status]  |
   +-------------------------+
   ```
   - Shows upcoming/completed status
   - Displays prediction confidence
   - Links to detailed race analysis

3. **Detailed Race View**
   ```
   +--------------------------------+
   |        [Circuit Name]          |
   |--------------------------------|
   | Qualifying    Race      Points |
   | Prediction    Prediction       |
   |                               |
   | [Timeline of Position Changes] |
   |                               |
   | [Lap Time Predictions Graph]   |
   +--------------------------------+
   ```

### Navigation Flow
1. **Entry Point**
   - User lands on main page showing championship standings
   - Top 3 drivers prominently displayed
   - Remaining drivers listed below

2. **Driver Details Flow**
   - Click on driver card
   - View season predictions
   - Navigate through race-by-race analysis
   - Access historical performance data

3. **Race Details Flow**
   - Click on race card
   - View complete race weekend predictions
   - Access detailed timing information
   - Compare driver performances

4. **Update Cycle**
   - Real-time updates after each session
   - Prediction adjustments based on new data
   - Historical accuracy tracking
