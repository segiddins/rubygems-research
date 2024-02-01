require "test_helper"

class RubygemsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @rubygem = rubygems(:one)
  end

  test "should get index" do
    get rubygems_url
    assert_response :success
  end

  test "should get new" do
    get new_rubygem_url
    assert_response :success
  end

  test "should create rubygem" do
    assert_difference("Rubygem.count") do
      post rubygems_url, params: { rubygem: { name: @rubygem.name, server_id: @rubygem.server_id } }
    end

    assert_redirected_to rubygem_url(Rubygem.last)
  end

  test "should show rubygem" do
    get rubygem_url(@rubygem)
    assert_response :success
  end

  test "should get edit" do
    get edit_rubygem_url(@rubygem)
    assert_response :success
  end

  test "should update rubygem" do
    patch rubygem_url(@rubygem), params: { rubygem: { name: @rubygem.name, server_id: @rubygem.server_id } }
    assert_redirected_to rubygem_url(@rubygem)
  end

  test "should destroy rubygem" do
    assert_difference("Rubygem.count", -1) do
      delete rubygem_url(@rubygem)
    end

    assert_redirected_to rubygems_url
  end
end
