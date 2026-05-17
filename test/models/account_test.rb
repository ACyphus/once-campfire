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
end
