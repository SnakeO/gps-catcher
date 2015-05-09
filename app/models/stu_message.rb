# == Schema Information
#
# Table name: stu_messages
#
#  id         :integer          not null, primary key
#  raw        :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class StuMessage < ActiveRecord::Base
end
