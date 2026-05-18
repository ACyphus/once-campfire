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

  test "admin can set help_contact_name and help_contact_email" do
    put account_url, params: { account: { settings: {
      help_contact_name: "Support Team", help_contact_email: "support@example.com" } } }

    assert_redirected_to edit_account_url
    assert_equal "Support Team",        accounts(:signal).reload.settings.help_contact_name
    assert_equal "support@example.com", accounts(:signal).reload.settings.help_contact_email
  end

  test "admin can clear help_contact fields to revert to admin default" do
    accounts(:signal).update!(settings: {
      "help_contact_name" => "Support Team", "help_contact_email" => "support@example.com" })

    put account_url, params: { account: { settings: {
      help_contact_name: "", help_contact_email: "" } } }

    assert_redirected_to edit_account_url
    contact = accounts(:signal).reload.help_contact
    assert_equal users(:david).name,          contact.name
    assert_equal users(:david).email_address, contact.email_address
  end

  test "updating help_contact does not clear unrelated settings" do
    accounts(:signal).update!(settings: { "restrict_invite_to_administrators" => "true" })

    put account_url, params: { account: { settings: {
      help_contact_email: "support@example.com" } } }

    assert_redirected_to edit_account_url
    assert accounts(:signal).reload.settings.restrict_invite_to_administrators?
    assert_equal "support@example.com", accounts(:signal).settings.help_contact_email
  end

  test "sign-in page renders help contact override email when set" do
    accounts(:signal).update!(settings: { "help_contact_email" => "support@example.com" })

    get new_session_url
    assert_response :ok
    assert_match "support@example.com", response.body
    assert_match "mailto:support@example.com", response.body
  end

  test "sign-in page hides help contact button when no admin exists and no override is set" do
    User.administrator.destroy_all

    get new_session_url
    assert_response :ok
    assert_no_match "lifebuoy.svg", response.body
  end

  test "admin can set code_of_conduct_url and minimum_age" do
    put account_url, params: { account: { settings: {
      code_of_conduct_url: "https://example.com/coc", minimum_age: "18" } } }

    assert_redirected_to edit_account_url
    accounts(:signal).reload
    assert_equal "https://example.com/coc", accounts(:signal).settings.code_of_conduct_url
    assert_equal 18, accounts(:signal).settings.minimum_age
  end

  test "admin update is rejected when code_of_conduct_url has a non-http scheme" do
    put account_url, params: { account: { settings: {
      code_of_conduct_url: "javascript:alert(1)" } } }

    assert_redirected_to edit_account_url
    assert_match(/Code of conduct URL/, flash[:alert])
    assert_nil accounts(:signal).reload.settings.code_of_conduct_url
  end

  test "admin sees sign-up requirements fields in settings" do
    get edit_account_url
    assert_response :ok
    assert_match "Sign-up requirements", response.body
    assert_select "input[name='account[settings][code_of_conduct_url]'][type='url']"
    assert_select "input[name='account[settings][minimum_age]'][type='number']"
  end

  test "non-admin does not see sign-up requirements fields" do
    sign_in :kevin
    get edit_account_url
    assert_response :ok
    assert_no_match "Sign-up requirements", response.body
  end
end
