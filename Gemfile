source 'https://rubygems.org'

# Rails 5.2
gem 'rails', '~> 5.2.8.1'

# Database
gem 'sqlite3', '~> 1.3.6'
gem 'pg', '~> 1.2.3'  # Last version compatible with Ruby 2.7
gem 'activerecord-postgis-adapter', '~> 5.2'
gem 'rgeo', '~> 2.0'
gem 'rgeo-activerecord', '~> 6.0'

# Asset Pipeline
gem 'sass-rails', '~> 5.0'
gem 'uglifier', '>= 1.3.0'
gem 'coffee-rails', '~> 4.2'
gem 'jquery-rails'
gem 'turbolinks', '~> 5'
gem 'jbuilder', '~> 2.11.0'
gem 'sdoc', '~> 1.0', group: :doc

# Server
gem 'puma', '~> 4.3'

# Background Jobs
gem 'sidekiq', '~> 5.2'

# Performance
gem 'bootsnap', '>= 1.1.0', require: false

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
  gem 'listen', '~> 3.3'
  gem 'spring', '~> 2.1'
  gem 'spring-watcher-listen', '~> 2.0.0'
end

group :test do
  gem 'minitest', '~> 5.14.0'
  gem 'minitest-reporters'
  gem 'webmock'
  gem 'mocha'
  gem 'database_cleaner'
end
