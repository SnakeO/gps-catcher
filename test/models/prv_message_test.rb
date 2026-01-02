# frozen_string_literal: true
#
# == Schema Information
#
# Table name: prv_messages
#
#  id         :integer          not null, primary key
#  raw        :text(65535)
#  status     :string(255)
#  extra      :string(255)
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

require 'test_helper'

class PrvMessageTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
