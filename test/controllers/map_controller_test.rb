require 'test_helper'

class MapControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
  end

  test "should get account" do
    get :account
    assert_response :success
  end

  test "should get host" do
    get :host
    assert_response :success
  end

end
