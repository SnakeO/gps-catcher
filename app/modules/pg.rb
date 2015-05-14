require 'pg'
require 'rubygems'

# http://exposinggotchas.blogspot.com/2011/02/activerecord-migrations-without-rails.html
class PGConn

   @@conn = nil

	def self.get()
		self.init() if @@conn.nil?
		@@conn
	end

	def self.init()
		@@conn = PG.connect({
			host: 'gps.websitesonwheels.net', 
			dbname: 'gps', 
			port: 5432, 
			user:'gps', 
			password: 'Track.all.the.things!'
		})

		at_exit { @@conn.close() }
	end

	def self.close()
		@@conn.close() if not @@conn.nil?
	end

end

