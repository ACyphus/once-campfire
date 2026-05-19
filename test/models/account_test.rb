require "test_helper"

class AccountTest < ActiveSupport::TestCase
  test "settings" do
    accounts(:signal).settings.restrict_room_creation_to_administrators = true
    assert accounts(:signal).settings.restrict_room_creation_to_administrators?
    assert_equal true, accounts(:signal)[:settings]["restrict_room_creation_to_administrators"]

    accounts(:signal).update!(settings: { "restrict_room_creation_to_administrators" => "true" })
    assert accounts(:signal).reload.settings.restrict_room_creation_to_administrators?

    accounts(:signal).settings.restrict_room_creation_to_administrators = false
    assert_not accounts(:signal).settings.restrict_room_creation_to_administrators?
    assert_equal false, accounts(:signal)[:settings]["restrict_room_creation_to_administrators"]
    accounts(:signal).update!(settings: { "restrict_room_creation_to_administrators" => "false" })
    assert_not accounts(:signal).reload.settings.restrict_room_creation_to_administrators?
  end

  test "restrict_invite_to_administrators setting" do
    accounts(:signal).settings.restrict_invite_to_administrators = true
    assert accounts(:signal).settings.restrict_invite_to_administrators?
    assert_equal true, accounts(:signal)[:settings]["restrict_invite_to_administrators"]

    accounts(:signal).update!(settings: { "restrict_invite_to_administrators" => "true" })
    assert accounts(:signal).reload.settings.restrict_invite_to_administrators?

    accounts(:signal).settings.restrict_invite_to_administrators = false
    assert_not accounts(:signal).settings.restrict_invite_to_administrators?
    assert_equal false, accounts(:signal)[:settings]["restrict_invite_to_administrators"]

    accounts(:signal).update!(settings: { "restrict_invite_to_administrators" => "false" })
    assert_not accounts(:signal).reload.settings.restrict_invite_to_administrators?
  end

  test "restrict_invite_to_administrators defaults to false" do
    assert_not accounts(:signal).settings.restrict_invite_to_administrators?
  end

  test "help_contact_name and help_contact_email default to nil" do
    assert_nil accounts(:signal).settings.help_contact_name
    assert_nil accounts(:signal).settings.help_contact_email
  end

  test "help_contact falls back to first administrator when overrides are blank" do
    admin = User.administrator.first
    contact = accounts(:signal).help_contact

    assert_equal admin.name,          contact.name
    assert_equal admin.email_address, contact.email_address
  end

  test "help_contact uses settings overrides when set" do
    accounts(:signal).update!(settings: {
      "help_contact_name" => "Support Team", "help_contact_email" => "support@example.com" })

    contact = accounts(:signal).reload.help_contact

    assert_equal "Support Team",        contact.name
    assert_equal "support@example.com", contact.email_address
  end

  test "help_contact falls back per-field when only one override is set" do
    admin = User.administrator.first
    accounts(:signal).update!(settings: { "help_contact_email" => "support@example.com" })

    contact = accounts(:signal).reload.help_contact

    assert_equal admin.name,            contact.name
    assert_equal "support@example.com", contact.email_address
  end

  test "help_contact treats empty-string overrides as blank and falls back" do
    admin = User.administrator.first
    accounts(:signal).update!(settings: {
      "help_contact_name" => "", "help_contact_email" => "" })

    contact = accounts(:signal).reload.help_contact

    assert_equal admin.name,          contact.name
    assert_equal admin.email_address, contact.email_address
  end

  test "help_contact returns nils when no administrator exists and no override is set" do
    User.administrator.destroy_all

    contact = accounts(:signal).help_contact

    assert_nil contact.name
    assert_nil contact.email_address
  end

  test "code_of_conduct_url and minimum_age default to nil" do
    assert_nil accounts(:signal).settings.code_of_conduct_url
    assert_nil accounts(:signal).settings.minimum_age
  end

  test "code_of_conduct_url and minimum_age round-trip" do
    accounts(:signal).update!(settings: {
      "code_of_conduct_url" => "https://example.com/coc",
      "minimum_age" => "21" })

    accounts(:signal).reload
    assert_equal "https://example.com/coc", accounts(:signal).settings.code_of_conduct_url
    assert_equal 21, accounts(:signal).settings.minimum_age
  end

  test "code_of_conduct_url rejects javascript: and other non-http(s) schemes" do
    [ "javascript:alert(1)", "data:text/html,<script>", "file:///etc/passwd", "ftp://example.com/" ].each do |bad|
      account = accounts(:signal)
      account.settings.code_of_conduct_url = bad

      assert_not account.valid?, "#{bad.inspect} should be rejected"
      assert_match(/Code of conduct URL/, account.errors.full_messages.to_sentence)
    end
  end

  test "code_of_conduct_url accepts http and https" do
    [ "http://example.com/coc", "https://example.com/coc" ].each do |good|
      account = accounts(:signal)
      account.settings.code_of_conduct_url = good
      assert account.valid?, "#{good.inspect} should be accepted (errors: #{account.errors.full_messages})"
    end
  end

  test "code_of_conduct_url with whitespace-only value is treated as blank and valid" do
    account = accounts(:signal)
    account.settings.code_of_conduct_url = "   "
    assert account.valid?
  end
end
