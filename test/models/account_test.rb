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
end
