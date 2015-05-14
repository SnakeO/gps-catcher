# == Schema Information
#
# Table name: parsed_messages
#
#  id                  :integer          not null, primary key
#  origin_message_type :string(255)
#  origin_message_id   :integer
#  esn                 :string(255)
#  source              :string(255)
#  value               :string(255)
#  meta                :string(255)
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#

require 'test_helper'

class ParsedMessageTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
