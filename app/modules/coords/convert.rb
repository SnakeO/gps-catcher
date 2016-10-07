module Coords
	class Convert

      # input hours, minutes (as string, mmm can contain a decimal) to a pure decimal representation
      def self.hhmmmToLatLng(hh, mmm, hemisphere)
         dec = hh.to_i + (mmm.to_f/60.0)
         return (hemisphere == 'S' || hemisphere == 'W') ? -dec : dec
      end

	end
end