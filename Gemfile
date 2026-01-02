source 'https://rubygems.org'

ruby '3.2.9'

# Rails 7.0
gem 'rails', '~> 7.0.8.6'

# Database (PostgreSQL with PostGIS)
gem 'pg', '~> 1.5'
gem 'activerecord-postgis-adapter', '~> 8.0'
gem 'rgeo', '~> 3.0'
gem 'rgeo-activerecord', '~> 7.0'

# Asset Pipeline
gem 'sprockets-rails'
gem 'jbuilder', '~> 2.11.0'

# Server
gem 'puma', '~> 6.0'

# Background Jobs
gem 'sidekiq', '~> 7.0'

# Performance
gem 'bootsnap', require: false

# Utilities
gem 'ffi'
gem 'net-ssh-gateway'
gem 'nokogiri'
gem 'httparty'

group :development, :test do
  gem 'byebug', '~> 11.0', platforms: [:mri]
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

  # Type checking
  gem 'steep', '~> 1.6'
  gem 'rbs', '~> 3.4'
end

group :test do
  gem 'minitest', '~> 5.14.0'
  gem 'minitest-reporters'
  gem 'webmock'
  gem 'mocha'
  gem 'database_cleaner'
end
