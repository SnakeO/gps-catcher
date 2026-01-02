# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

GPS Catcher is a Ruby on Rails 4.2.1 API application that receives, decodes, and stores GPS tracking messages from various satellite/cellular tracking devices. It acts as a message broker between GPS devices (via their provider APIs) and a PostgreSQL/PostGIS database for geolocation storage.

## Common Commands

```bash
# Start development server (Puma)
bundle exec rails server

# Run all tests
bundle exec rake test

# Run a single test file
bundle exec ruby -I test test/models/stu_message_test.rb

# Start Sidekiq worker (required for background jobs)
bundle exec sidekiq

# Database commands
bundle exec rake db:migrate
bundle exec rake db:schema:load

# View routes
bundle exec rake routes

# Rails console
bundle exec rails console
```

## Architecture

### Dual Database Architecture

The app uses two databases simultaneously:
- **MySQL (default)**: Stores raw incoming messages and parsed intermediate data (`stu_messages`, `prv_messages`, `parsed_messages`)
- **PostgreSQL with PostGIS** (`pg` connection): Stores final location data with geospatial support (`location_msgs`, `info_msgs`, `geofences`, `fence_states`)

Models using PostGIS specify their connection with `establish_connection :pg` (see `app/models/location_msg.rb`).

### Message Processing Pipeline

1. **Controller** receives raw message from device provider webhook
2. Raw message stored in MySQL (`StuMessage`, `Gl200Message`, etc.)
3. **Sidekiq Worker** processes asynchronously, calling device-specific **Decoder**
4. Decoder parses binary/CSV payload into `ParsedMessage` objects (location, battery, motion, etc.)
5. `ParsedMessage#sendToPostgres` writes final data to PostGIS as `LocationMsg` or `InfoMsg`

### Device Modules

Each GPS device type has its own module under `app/modules/`:
- `globalstar/` - SmartOne devices (binary 72-bit payload decoding)
- `gl200/` - Queclink GL200/GL300 (CSV-based protocol)
- `spot_trace/` - SPOT Trace devices
- `gps306a/` - GPS306A trackers
- `xexun/tk1022/` - Xexun TK1022 devices
- `smart/bdgps/` - Smart BDGPS devices
- `queclink/` - Queclink common functionality

Each module typically contains:
- `decoder.rb` - Parses raw device protocol into ParsedMessages
- `worker.rb` - Sidekiq job for async processing
- `message.rb` - Device-specific message model (if needed)

### API Endpoints

Two types of endpoints:
1. **Webhook receivers** (`POST /globalstar/stu`, `/gl200/msg`, etc.) - receive raw messages from device providers
2. **Decode API** (`/v1/device/{type}/decode`) - stateless message decoding without storage

### Geofencing

The `geofences` table stores PostGIS geometries. `Geofence#contains(lat, lng)` uses `ST_Contains` for point-in-polygon checks. The `FenceAlertWorker` sends webhook notifications when devices enter/exit geofences.

### String Extensions

`lib/core_ext/string.rb` adds methods for binary manipulation used in protocol decoding:
- `flipBits()` - invert bits in a binary string
- `convert_base(from, to)` - convert between number bases (binary/hex/decimal)
