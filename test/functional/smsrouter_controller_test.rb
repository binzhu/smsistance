require 'test_helper'

class SmsrouterControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
  end

  test "should get api" do
    get :api
    assert_response :success
  end

end
