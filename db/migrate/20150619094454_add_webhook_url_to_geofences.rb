class AddWebhookUrlToGeofences < ActiveRecord::Migration
  def connection
     Geofence.connection
   end

  def change
    add_column :geofences, :webhook_url, :string
  end
end
