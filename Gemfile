source 'https://rubygems.org'

# Rails 5.0
gem 'rails', '~> 5.0.7.2'

# Database
gem 'sqlite3', '~> 1.3.6'
# gem 'mysql2', '~> 0.4.10'  # Removed: consolidating to PostgreSQL
gem 'pg', '~> 1.2.0'
gem 'activerecord-postgis-adapter', '~> 4.0'
gem 'rgeo', '~> 0.5.0'
gem 'rgeo-activerecord', '~> 5.0.0'

# Asset Pipeline
gem 'sass-rails', '~> 5.0'
gem 'uglifier', '>= 1.3.0'
gem 'coffee-rails', '~> 4.2'
gem 'jquery-rails'
gem 'turbolinks', '~> 5'
gem 'jbuilder', '~> 2.11.0'
gem 'sdoc', '~> 0.4.0', group: :doc

# Server
gem 'puma', '~> 3.12'

# Background Jobs
gem 'sidekiq', '~> 5.2'

# Utilities
gem 'ffi', '~> 1.16.0'
gem 'net-ssh-gateway'
gem 'execjs'
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
  gem 'listen', '~> 3.1.0'
  gem 'spring', '~> 2.1'
  gem 'spring-watcher-listen', '~> 2.0.0'
end

group :test do
  gem 'minitest', '~> 5.14.0'  # Pin for Rails 5.0 compatibility
  gem 'minitest-reporters'
  gem 'webmock'
  gem 'mocha'
  gem 'database_cleaner'
end
