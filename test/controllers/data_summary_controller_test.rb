require "test_helper"

class DataSummaryControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get data_summary_index_url
    assert_response :success
  end
end
