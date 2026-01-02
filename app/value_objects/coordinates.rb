# Immutable value object representing geographic coordinates
# Validates and normalizes latitude/longitude values
class Coordinates
  attr_reader :latitude, :longitude

  INVALID_COORDS = [
    [0.0, 0.0],
    [-99999.0, -99999.0]
  ].freeze

  class InvalidCoordinatesError < StandardError; end

  def initialize(latitude, longitude)
    @latitude = normalize_coordinate(latitude)
    @longitude = normalize_coordinate(longitude)
    validate!
    freeze
  end

  def valid?
    return false if @latitude.nil? || @longitude.nil?
    return false if INVALID_COORDS.include?([@latitude, @longitude])
    return false unless @latitude.between?(-90, 90)
    return false unless @longitude.between?(-180, 180)
    true
  end

  def to_s
    "#{@latitude},#{@longitude}"
  end

  def to_a
    [@latitude, @longitude]
  end

  def to_h
    { latitude: @latitude, longitude: @longitude }
  end

  def ==(other)
    return false unless other.is_a?(Coordinates)
    @latitude == other.latitude && @longitude == other.longitude
  end
  alias eql? ==

  def hash
    [@latitude, @longitude].hash
  end

  def to_rgeo_point(factory: nil)
    factory ||= RGeo::Geographic.spherical_factory(srid: 4326)
    factory.point(@longitude, @latitude)
  end

  private

  def normalize_coordinate(value)
    case value
    when String then value.to_f
    when Numeric then value.to_f
    else nil
    end
  end

  def validate!
    raise InvalidCoordinatesError, "Invalid coordinates: #{self}" unless valid?
  end
end
