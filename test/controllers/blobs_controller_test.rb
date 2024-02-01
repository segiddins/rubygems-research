require "test_helper"

class BlobsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @blob = blobs(:one)
  end

  test "should get index" do
    get blobs_url
    assert_response :success
  end

  test "should get new" do
    get new_blob_url
    assert_response :success
  end

  test "should create blob" do
    assert_difference("Blob.count") do
      post blobs_url, params: { blob: { compression: @blob.compression, contents: @blob.contents, sha256: @blob.sha256, size: @blob.size } }
    end

    assert_redirected_to blob_url(Blob.last)
  end

  test "should show blob" do
    get blob_url(@blob)
    assert_response :success
  end

  test "should get edit" do
    get edit_blob_url(@blob)
    assert_response :success
  end

  test "should update blob" do
    patch blob_url(@blob), params: { blob: { compression: @blob.compression, contents: @blob.contents, sha256: @blob.sha256, size: @blob.size } }
    assert_redirected_to blob_url(@blob)
  end

  test "should destroy blob" do
    assert_difference("Blob.count", -1) do
      delete blob_url(@blob)
    end

    assert_redirected_to blobs_url
  end
end
