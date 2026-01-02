source 'https://rubygems.org'

# Rails 6.1
gem 'rails', '~> 6.1.7.10'

# Database (PostgreSQL with PostGIS - consolidated in Phase 6)
gem 'pg', '~> 1.4'
gem 'activerecord-postgis-adapter', '~> 7.0'
gem 'rgeo', '~> 3.0'
gem 'rgeo-activerecord', '~> 7.0'

# Asset Pipeline
gem 'sass-rails', '>= 6'
gem 'uglifier', '>= 1.3.0'
gem 'webpacker', '~> 4.0'
gem 'turbolinks', '~> 5'
gem 'jbuilder', '~> 2.11.0'

# Server
gem 'puma', '~> 5.0'

# Background Jobs
gem 'sidekiq', '~> 6.5'

# Performance
gem 'bootsnap', '>= 1.4.2', require: false

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
end

group :test do
  gem 'minitest', '~> 5.14.0'
  gem 'minitest-reporters'
  gem 'webmock'
  gem 'mocha'
  gem 'database_cleaner'
end
