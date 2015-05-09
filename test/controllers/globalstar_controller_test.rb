require 'test_helper'

class GlobalstarControllerTest < ActionController::TestCase
  test "should get stu" do
    get :stu
    assert_response :success
  end

end
