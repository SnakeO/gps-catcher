class Geofence < ActiveRecord::Base
	establish_connection :pg

   has_many :fence_alerts
   has_many :fence_states

   # does this fence contain the point?
   def contains(lat, lng)
      query = "
         SELECT ST_Contains(
            geofences.fence::geometry, 
            (SELECT ST_GeomFromText('POINT(#{lng} #{lat})',4326))
         ) AS is_inside 
         FROM geofences 
         WHERE geofences.id = #{self.id}"

      res = Geofence.connection.execute(query) 
      res.first['is_inside'] == 't'
   end
end
