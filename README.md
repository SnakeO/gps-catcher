# GPS Catcher

A robust GPS tracking and geofencing platform built with Ruby on Rails. Receives location data from multiple GPS device types, stores it in PostgreSQL with PostGIS, and provides real-time geofence monitoring with webhook alerts.

## Features

- **Multi-Device Support**: Unified ingestion for 8+ GPS device protocols
- **Real-Time Geofencing**: PostGIS-powered spatial queries with enter/exit detection
- **Webhook Alerts**: Automatic notifications when devices cross geofence boundaries
- **Background Processing**: Sidekiq-powered message queue for reliable data processing
- **Clean Architecture**: Modular design with decoders, services, and repositories

## Supported Devices

| Device | Protocol | Endpoint |
|--------|----------|----------|
| Globalstar SmartOne | Binary STU/PRV | `POST /globalstar/stu`, `POST /globalstar/prv` |
| Queclink GL200 | CSV | `POST /gl200/msg` |
| Queclink GL300 | CSV | `POST /gl300/msg` |
| Queclink GL300MA | CSV | `POST /gl300ma/msg` |
| SPOT Trace | XML | `POST /spot_trace/msg` |
| GPS306A | NMEA CSV | `POST /gps306a/msg` |
| Xexun TK1022 | CSV | `POST /xexun_tk1022/msg` |
| Smart BDGPS | CSV | `POST /smart_bdgps/msg` |

## Tech Stack

- **Ruby**: 3.2.9
- **Rails**: 7.0.8
- **Database**: PostgreSQL 15+ with PostGIS 3.3
- **Background Jobs**: Sidekiq 7.0
- **Web Server**: Puma 6.0
- **Geospatial**: RGeo, activerecord-postgis-adapter
- **Type Checking**: RBS (Ruby Signature)

## Architecture

```
app/
├── controllers/          # HTTP endpoints for device data ingestion
├── decoders/             # Protocol-specific message parsers
│   ├── base_decoder.rb       # Abstract base with common methods
│   ├── globalstar_decoder.rb # Binary payload decoding
│   ├── gl200_decoder.rb      # Queclink CSV parsing
│   ├── spot_trace_decoder.rb # XML message parsing
│   └── gps306a_decoder.rb    # NMEA coordinate conversion
├── factories/            # Object creation patterns
│   └── parsed_message_factory.rb
├── models/               # ActiveRecord models
│   ├── parsed_message.rb     # Unified message storage
│   ├── location_msg.rb       # Location data with PostGIS
│   ├── geofence.rb           # PostGIS polygon boundaries
│   ├── fence_state.rb        # Device-to-fence state tracking
│   └── fence_alert.rb        # Alert history
├── repositories/         # Data access patterns
│   └── fence_state_repository.rb
├── services/             # Business logic
│   ├── geofence_check_service.rb  # Fence boundary algorithm
│   └── xml_response_builder.rb   # Globalstar XML responses
├── value_objects/        # Immutable data containers
│   └── coordinates.rb
└── workers/              # Sidekiq background jobs
    ├── globalstar_worker.rb
    ├── gl200_worker.rb
    ├── spot_trace_worker.rb
    ├── gps306a_worker.rb
    └── fence_alert_worker.rb
sig/                      # RBS type signatures
├── coordinates.rbs
├── base_decoder.rbs
├── globalstar_decoder.rbs
├── gl200_decoder.rbs
├── spot_trace_decoder.rbs
├── gps306a_decoder.rbs
├── parsed_message_factory.rbs
├── fence_state_repository.rbs
├── geofence_check_service.rbs
└── xml_response_builder.rbs
```

## Type Checking

This project uses RBS (Ruby Signature) for static type definitions. Type signatures are in the `sig/` directory.

### Validate type signatures

```bash
bundle exec rbs -I sig validate
```

### Type signature example

```ruby
# sig/coordinates.rbs
class Coordinates
  attr_reader latitude: Float?
  attr_reader longitude: Float?

  def initialize: (Float | String | nil, Float | String | nil) -> void
  def valid?: () -> bool
  def to_s: () -> String
  def to_rgeo_point: (?factory: untyped?) -> untyped
end
```

### Covered classes

| Class | Signature File |
|-------|----------------|
| `Coordinates` | `sig/coordinates.rbs` |
| `BaseDecoder` | `sig/base_decoder.rbs` |
| `GlobalstarDecoder` | `sig/globalstar_decoder.rbs` |
| `Gl200Decoder` | `sig/gl200_decoder.rbs` |
| `SpotTraceDecoder` | `sig/spot_trace_decoder.rbs` |
| `Gps306aDecoder` | `sig/gps306a_decoder.rbs` |
| `ParsedMessageFactory` | `sig/parsed_message_factory.rbs` |
| `FenceStateRepository` | `sig/fence_state_repository.rbs` |
| `GeofenceCheckService` | `sig/geofence_check_service.rbs` |
| `XmlResponseBuilder` | `sig/xml_response_builder.rbs` |

## Prerequisites

- Ruby 3.2.9
- PostgreSQL 15+ with PostGIS extension
- Redis (for Sidekiq)

## Installation

### 1. Clone the repository

```bash
git clone git@github.com:your-org/gps-catcher.git
cd gps-catcher
```

### 2. Install dependencies

```bash
bundle install
```

### 3. Configure database

Create `.env` or set environment variables:

```bash
export DATABASE_HOST=localhost
export DATABASE_USERNAME=your_username
export DATABASE_PASSWORD=your_password
export DATABASE_NAME=gps
```

### 4. Setup database

```bash
# Create database with PostGIS extension
psql -c "CREATE DATABASE gps_development;"
psql -d gps_development -c "CREATE EXTENSION postgis;"

# Run migrations
bin/rails db:migrate
```

### 5. Start services

```bash
# Terminal 1: Rails server
bin/rails server

# Terminal 2: Sidekiq worker
bundle exec sidekiq
```

## Configuration

### Database (config/database.yml)

```yaml
production:
  adapter: postgis
  encoding: unicode
  pool: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>
  host: <%= ENV["DATABASE_HOST"] %>
  database: <%= ENV.fetch("DATABASE_NAME") { "gps" } %>
  username: <%= ENV["DATABASE_USERNAME"] %>
  password: <%= ENV["DATABASE_PASSWORD"] %>
```

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `DATABASE_HOST` | PostgreSQL host | `localhost` |
| `DATABASE_USERNAME` | Database user | System user |
| `DATABASE_PASSWORD` | Database password | - |
| `DATABASE_NAME` | Database name | `gps` |
| `RAILS_MAX_THREADS` | Connection pool size | `5` |
| `REDIS_URL` | Redis URL for Sidekiq | `redis://localhost:6379` |

## API Endpoints

### Device Message Ingestion

All device endpoints accept POST requests with raw device data:

```bash
# Globalstar STU message
curl -X POST https://your-server/globalstar/stu \
  -H "Content-Type: application/xml" \
  -d @stu_message.xml

# GL200 location message
curl -X POST https://your-server/gl200/msg \
  -d "message=+RESP:GTFRI,..."
```

### Geofence Check

```bash
# Check if ESN is inside/outside fences
curl "https://your-server/geofence/check?esn=DEVICE_ESN"
```

### Decode API (for testing)

```bash
# Decode GL200 message without storing
curl "https://your-server/v1/device/gl200/decode?msg=+RESP:GTFRI,..."

# Decode SPOT message
curl "https://your-server/v1/device/spot/decode" \
  -H "Content-Type: application/xml" \
  -d @spot_message.xml
```

## Testing

### Run all tests

```bash
bin/rails test
```

### Run specific test files

```bash
bin/rails test test/decoders/globalstar_decoder_test.rb
bin/rails test test/services/geofence_check_service_test.rb
```

### Test with coverage

```bash
COVERAGE=true bin/rails test
```

### Test Categories

| Directory | Coverage |
|-----------|----------|
| `test/decoders/` | Protocol parsing, coordinate conversion |
| `test/services/` | Geofence algorithm, XML building |
| `test/repositories/` | Data access patterns |
| `test/models/` | ActiveRecord validations |
| `test/controllers/` | HTTP endpoints |

## Deployment

### Production with Puma

```bash
# config/puma.rb is pre-configured
bundle exec puma -C config/puma.rb
```

### Systemd Services

**Puma Service** (`/etc/systemd/system/puma.service`):

```ini
[Unit]
Description=Puma HTTP Server
After=network.target

[Service]
Type=simple
User=deploy
WorkingDirectory=/var/www/gps-catcher
ExecStart=/usr/local/bin/bundle exec puma -C config/puma.rb
Restart=always

[Install]
WantedBy=multi-user.target
```

**Sidekiq Service** (`/etc/systemd/system/sidekiq.service`):

```ini
[Unit]
Description=Sidekiq
After=network.target

[Service]
Type=simple
User=deploy
WorkingDirectory=/var/www/gps-catcher
ExecStart=/usr/local/bin/bundle exec sidekiq
Restart=always

[Install]
WantedBy=multi-user.target
```

### Nginx Reverse Proxy

```nginx
upstream puma {
    server unix:/var/www/gps-catcher/tmp/sockets/puma.sock;
}

server {
    listen 80;
    server_name gps.example.com;

    location / {
        proxy_pass http://puma;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

## CI/CD

GitHub Actions workflow runs on every push:

```yaml
# .github/workflows/ci.yml
- Tests against PostgreSQL 15 with PostGIS 3.3
- Ruby 3.2.9 with bundler caching
- Security audit with bundler-audit
```

[![CI](https://github.com/your-org/gps-catcher/actions/workflows/ci.yml/badge.svg)](https://github.com/your-org/gps-catcher/actions/workflows/ci.yml)

## Data Flow

```
Device → Controller → Worker → Decoder → ParsedMessage → PostgreSQL
                                              ↓
                                      GeofenceCheckService
                                              ↓
                                      FenceAlertWorker → Webhook
```

1. **Device** sends location data via HTTP POST
2. **Controller** validates request, queues for processing
3. **Worker** (Sidekiq) processes message asynchronously
4. **Decoder** parses protocol-specific format into unified structure
5. **ParsedMessage** deduplicates and stores in PostgreSQL
6. **GeofenceCheckService** evaluates position against active fences
7. **FenceAlertWorker** sends webhook on state transitions

## Geofence Algorithm

The geofence system detects when devices enter or exit defined boundaries:

1. Query active geofences for the device ESN
2. For each fence, check if coordinates are inside (PostGIS `ST_Contains`)
3. Compare current state with previous state
4. On state change (enter/exit), create alert and trigger webhook

```ruby
# Example: Check if point is inside geofence
geofence.contains?(latitude, longitude)
# Uses PostGIS: ST_Contains(boundary, ST_Point(lng, lat))
```

## Message Deduplication

Messages are deduplicated using a composite hash:

```ruby
message_id = Digest::MD5.hexdigest("#{esn}#{source}#{value}#{occurred_at}")
```

Duplicate messages return the existing record instead of creating duplicates.

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/new-device`)
3. Write tests first
4. Implement the feature
5. Ensure all tests pass (`bin/rails test`)
6. Submit a pull request

## License

Proprietary - All rights reserved.
