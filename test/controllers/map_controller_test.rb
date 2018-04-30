require 'test_helper'

class MapControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get map_index_url
    assert_response :success
  end

  test "should get group" do
    get map_group_url
    assert_response :success
  end

  test "should get host" do
    get map_host_url
    assert_response :success
  end

  test "should get host_fragment" do
    get map_host_fragment_url
    assert_response :success
  end

end
