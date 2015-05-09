# == Schema Information
#
# Table name: prv_messages
#
#  id         :integer          not null, primary key
#  raw        :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class PrvMessage < ActiveRecord::Base
end
