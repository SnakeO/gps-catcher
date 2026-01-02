source 'https://rubygems.org'

# Rails 6.0
gem 'rails', '~> 6.0.6.1'

# Database (PostgreSQL with PostGIS - consolidated in Phase 6)
gem 'pg', '~> 1.2.3'  # Compatible with Ruby 2.7
gem 'activerecord-postgis-adapter', '~> 6.0'
gem 'rgeo', '~> 2.0'
gem 'rgeo-activerecord', '~> 6.0'

# Asset Pipeline
gem 'sass-rails', '>= 6'
gem 'uglifier', '>= 1.3.0'
gem 'webpacker', '~> 4.0'
gem 'turbolinks', '~> 5'
gem 'jbuilder', '~> 2.11.0'

# Server
gem 'puma', '~> 5.0'

# Background Jobs
gem 'sidekiq', '~> 6.0'

# Performance
gem 'bootsnap', '>= 1.4.2', require: false

# Utilities
gem 'ffi', '~> 1.16.0'
gem 'net-ssh-gateway'
gem 'nokogiri', '~> 1.13.0'
gem 'httparty', '~> 0.17'

group :development, :test do
  gem 'byebug', '~> 11.0', platforms: [:mri, :mingw, :x64_mingw]
  gem 'awesome_print', require: 'ap'
  gem 'better_errors'
  gem 'binding_of_caller'
  gem 'pry'
  gem 'pry-rails'
end

group :development do
  gem 'web-console', '>= 3.3.0'
  gem 'listen', '~> 3.3'
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.0.0'
end

group :test do
  gem 'minitest', '~> 5.14.0'
  gem 'minitest-reporters'
  gem 'webmock'
  gem 'mocha'
  gem 'database_cleaner'
end
