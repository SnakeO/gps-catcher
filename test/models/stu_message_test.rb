# == Schema Information
#
# Table name: stu_messages
#
#  id         :integer          not null, primary key
#  raw        :text(65535)
#  status     :string(255)
#  extra      :string(255)
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

require 'test_helper'

class StuMessageTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
