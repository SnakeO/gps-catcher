require 'test_helper'

class CoordinatesTest < ActiveSupport::TestCase
  test "creates valid coordinates" do
    coords = Coordinates.new(32.7428, -97.1471)
    assert_equal 32.7428, coords.latitude
    assert_equal(-97.1471, coords.longitude)
  end

  test "accepts string coordinates" do
    coords = Coordinates.new("32.7428", "-97.1471")
    assert_equal 32.7428, coords.latitude
    assert_equal(-97.1471, coords.longitude)
  end

  test "is immutable" do
    coords = Coordinates.new(32.7428, -97.1471)
    assert coords.frozen?
  end

  test "rejects zero coordinates" do
    assert_raises(Coordinates::InvalidCoordinatesError) do
      Coordinates.new(0.0, 0.0)
    end
  end

  test "rejects sentinel invalid coordinates" do
    assert_raises(Coordinates::InvalidCoordinatesError) do
      Coordinates.new(-99999.0, -99999.0)
    end
  end

  test "rejects out of range latitude" do
    assert_raises(Coordinates::InvalidCoordinatesError) do
      Coordinates.new(91, 0)
    end
  end

  test "rejects out of range longitude" do
    assert_raises(Coordinates::InvalidCoordinatesError) do
      Coordinates.new(0, 181)
    end
  end

  test "to_s returns comma-separated string" do
    coords = Coordinates.new(32.7428, -97.1471)
    assert_equal "32.7428,-97.1471", coords.to_s
  end

  test "to_a returns array" do
    coords = Coordinates.new(32.7428, -97.1471)
    assert_equal [32.7428, -97.1471], coords.to_a
  end

  test "to_h returns hash" do
    coords = Coordinates.new(32.7428, -97.1471)
    assert_equal({ latitude: 32.7428, longitude: -97.1471 }, coords.to_h)
  end

  test "equality comparison" do
    coords1 = Coordinates.new(32.7428, -97.1471)
    coords2 = Coordinates.new(32.7428, -97.1471)
    coords3 = Coordinates.new(32.7429, -97.1471)

    assert_equal coords1, coords2
    refute_equal coords1, coords3
  end

  test "can be used as hash key" do
    coords1 = Coordinates.new(32.7428, -97.1471)
    coords2 = Coordinates.new(32.7428, -97.1471)

    hash = { coords1 => "value" }
    assert_equal "value", hash[coords2]
  end

  test "creates RGeo point" do
    coords = Coordinates.new(32.7428, -97.1471)
    point = coords.to_rgeo_point

    assert_equal(-97.1471, point.x)
    assert_equal 32.7428, point.y
  end
end
