ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../Gemfile', __dir__)

require 'bundler/setup' # Set up gems listed in the Gemfile.

# Ensure Logger is loaded before Rails for compatibility with newer logger gem
require 'logger'

require 'bootsnap/setup' # Speed up boot time by caching expensive operations.
