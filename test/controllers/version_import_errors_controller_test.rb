require "test_helper"

class VersionImportErrorsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get version_import_errors_index_url
    assert_response :success
  end
end
