require "test_helper"

class FileHistoryControllerTest < ActionDispatch::IntegrationTest
  test "should get show" do
    get file_history_show_url
    assert_response :success
  end
end
