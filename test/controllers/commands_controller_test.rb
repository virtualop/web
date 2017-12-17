require 'test_helper'

class CommandsControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
  end

end
