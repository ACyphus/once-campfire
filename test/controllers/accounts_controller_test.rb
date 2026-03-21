require "test_helper"

class AccountsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in :david
  end

  test "edit" do
    get edit_account_url
    assert_response :ok
  end

  test "edit groups administrators separately from members with a divider" do
    get edit_account_url

    assert_response :ok

    # Verify the divider exists between administrator and member sections
    assert_select "turbo-frame#account_users hr.separator.full-width"

    # Verify administrators appear before the divider and members appear after
    # by checking the order of user names in the response body
    administrators = users(:david, :jason).map(&:name)
    members = users(:jz, :kevin).map(&:name)

    response_body = response.body

    # Find positions of divider and user names
    divider_position = response_body.index('hr class="separator full-width"')
    assert divider_position, "Divider should exist in the response"

    administrators.each do |name|
      name_position = response_body.index("<strong>#{name}</strong>")
      assert name_position, "Administrator #{name} should appear in the response"
      assert name_position < divider_position, "Administrator #{name} should appear before the divider"
    end

    members.each do |name|
      name_position = response_body.index("<strong>#{name}</strong>")
      assert name_position, "Member #{name} should appear in the response"
      assert name_position > divider_position, "Member #{name} should appear after the divider"
    end
  end

  test "update" do
    assert users(:david).administrator?

    put account_url, params: { account: { name: "Different" } }

    assert_redirected_to edit_account_url
    assert_equal accounts(:signal).name, "Different"
  end

  test "non-admins cannot update" do
    sign_in :kevin
    assert users(:kevin).member?

    put account_url, params: { account: { name: "Different" } }
    assert_response :forbidden
  end

  test "edit shows invite link to admin" do
    get edit_account_url
    assert_response :ok
    assert_match "invite_url", response.body
  end

  test "edit shows invite link to admin even when restricted" do
    accounts(:signal).update!(settings: { "restrict_invite_to_administrators" => "true" })

    get edit_account_url
    assert_response :ok
    assert_match "invite_url", response.body
  end

  test "edit shows invite link to member when unrestricted" do
    sign_in :kevin
    get edit_account_url
    assert_response :ok
    assert_match "invite_url", response.body
    assert_match "margin-block separator full-width", response.body
  end

  test "edit hides invite link and divider from member when restricted" do
    accounts(:signal).update!(settings: { "restrict_invite_to_administrators" => "true" })

    sign_in :kevin
    get edit_account_url
    assert_response :ok
    assert_no_match "invite_url", response.body
    assert_no_match "margin-block separator full-width", response.body
  end

  test "admin can toggle restrict_invite_to_administrators setting" do
    assert_not accounts(:signal).settings.restrict_invite_to_administrators?

    put account_url, params: { account: { settings: { restrict_invite_to_administrators: "true" } } }
    assert_redirected_to edit_account_url
    assert accounts(:signal).reload.settings.restrict_invite_to_administrators?

    put account_url, params: { account: { settings: { restrict_invite_to_administrators: "false" } } }
    assert_redirected_to edit_account_url
    assert_not accounts(:signal).reload.settings.restrict_invite_to_administrators?
  end

  test "admin sees restrict invite toggle in settings" do
    get edit_account_url
    assert_response :ok
    assert_match "Must be admin to share invite link", response.body
  end

  test "non-admin does not see restrict invite toggle" do
    sign_in :kevin
    get edit_account_url
    assert_response :ok
    assert_no_match "Must be admin to share invite link", response.body
  end
end
