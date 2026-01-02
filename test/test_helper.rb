ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'
require 'minitest/autorun'
require 'minitest/reporters'
require 'webmock/minitest'
require 'mocha/minitest'

# Configure minitest reporters for better output
Minitest::Reporters.use! [Minitest::Reporters::DefaultReporter.new(color: true)]

# Allow localhost connections for testing (Sidekiq, Redis, etc.)
WebMock.disable_net_connect!(allow_localhost: true)

class ActiveSupport::TestCase
  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  fixtures :all

  # Add more helper methods to be used by all tests here...

  # Helper to create sample GPS payload for Queclink devices
  def sample_gl200_payload
    '+RESP:GTFRI,02010D,867844001851958,,0,0,1,2,-1,0,196.5,-97.147099,32.742800,20150526000805,,,,,,91,20150526000956,1291$'
  end

  # Helper to create sample Globalstar STU XML
  def sample_globalstar_stu_xml
    <<~XML
      <?xml version="1.0" encoding="UTF-8"?>
      <stuMessages xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" messageID="test123">
        <stuMessage timeStamp="2015-05-26T00:00:00Z">
          <esn>0-1234567</esn>
          <unixTime>1432598400</unixTime>
          <payload encoding="hex" length="9">002E914EBAEAE84A08</payload>
        </stuMessage>
      </stuMessages>
    XML
  end

  # Helper to create sample SPOT Trace XML
  def sample_spot_trace_xml
    <<~XML
      <?xml version="1.0" encoding="UTF-8"?>
      <message>
        <esn>0-1234567</esn>
        <timestamp>2015-05-26T00:00:00Z</timestamp>
        <latitude>32.742800</latitude>
        <longitude>-97.147099</longitude>
        <messageType>TRACK</messageType>
      </message>
    XML
  end
end

class ActionController::TestCase
  # Include test helpers for controller tests
end

class ActionDispatch::IntegrationTest
  # Include test helpers for integration tests
end
