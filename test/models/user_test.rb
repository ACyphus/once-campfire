require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "user does not prevent very long passwords" do
    users(:david).update(password: "secret" * 50)
    assert users(:david).valid?
  end

  test "creating users grants membership to the open rooms" do
    assert_difference -> { Membership.count }, +Rooms::Open.count do
      create_new_user
    end
  end

  test "deactivating a user deletes push subscriptions, searches, memberships for non-direct rooms, and changes their email address" do
    assert_difference -> { Membership.count }, -users(:david).memberships.without_direct_rooms.count do
    assert_difference -> { Push::Subscription.count }, -users(:david).push_subscriptions.count do
    assert_difference -> { Search.count }, -users(:david).searches.count do
      SecureRandom.stubs(:uuid).returns("2e7de450-cf04-4fa8-9b02-ff5ab2d733e7")
      users(:david).deactivate
      assert_equal "david-deactivated-2e7de450-cf04-4fa8-9b02-ff5ab2d733e7@37signals.com", users(:david).reload.email_address
    end
    end
    end
  end

  test "deactivating a user deletes their sessions" do
    assert_changes -> { users(:david).sessions.count }, from: 1, to: 0 do
      users(:david).deactivate
    end
  end

  test "signup-context validations don't fire on normal updates" do
    accounts(:signal).update!(settings: {
      "code_of_conduct_url" => "https://example.com/coc", "minimum_age" => "18" })

    # users(:kevin) signed up before the requirements were configured (grandfathered)
    assert users(:kevin).update(bio: "Updated bio"), users(:kevin).errors.full_messages.inspect
  end

  test "signup validation fails when code of conduct URL is set and checkbox is not accepted" do
    accounts(:signal).update!(settings: { "code_of_conduct_url" => "https://example.com/coc" })

    user = User.new(name: "Sam", email_address: "sam@example.com", password: "secret123456",
      attested_minimum_age: "1")

    assert_not user.save(context: :signup)
    assert_match(/code of conduct/, user.errors.full_messages.to_sentence)
  end

  test "signup validation passes when code of conduct URL is set and checkbox is accepted" do
    accounts(:signal).update!(settings: { "code_of_conduct_url" => "https://example.com/coc" })

    user = User.new(name: "Sam", email_address: "sam@example.com", password: "secret123456",
      agreed_to_code_of_conduct: "1")

    assert user.save(context: :signup), user.errors.full_messages.inspect
  end

  test "signup validation fails when minimum age is set and checkbox is not accepted" do
    accounts(:signal).update!(settings: { "minimum_age" => "18" })

    user = User.new(name: "Sam", email_address: "sam@example.com", password: "secret123456")

    assert_not user.save(context: :signup)
    assert_match(/minimum age/, user.errors.full_messages.to_sentence)
  end

  test "signup validation passes when minimum age is set and checkbox is accepted" do
    accounts(:signal).update!(settings: { "minimum_age" => "18" })

    user = User.new(name: "Sam", email_address: "sam@example.com", password: "secret123456",
      attested_minimum_age: "1")

    assert user.save(context: :signup), user.errors.full_messages.inspect
  end

  test "signup validation passes when no requirements are configured even without checkboxes" do
    # No CoC URL, no minimum age in settings
    user = User.new(name: "Sam", email_address: "sam@example.com", password: "secret123456")
    assert user.save(context: :signup), user.errors.full_messages.inspect
  end

  test "signup validation fails when both are required and only one checkbox is accepted" do
    accounts(:signal).update!(settings: {
      "code_of_conduct_url" => "https://example.com/coc", "minimum_age" => "18" })

    user = User.new(name: "Sam", email_address: "sam@example.com", password: "secret123456",
      agreed_to_code_of_conduct: "1") # missing attested_minimum_age

    assert_not user.save(context: :signup)
    assert_match(/minimum age/, user.errors.full_messages.to_sentence)
  end

  test "minimum_age of 0 disables the age requirement" do
    accounts(:signal).update!(settings: { "minimum_age" => "0" })

    user = User.new(name: "Sam", email_address: "sam@example.com", password: "secret123456")
    assert user.save(context: :signup), user.errors.full_messages.inspect
  end

  test "whitespace-only code_of_conduct_url disables the CoC requirement" do
    accounts(:signal).update!(settings: { "code_of_conduct_url" => "   " })

    user = User.new(name: "Sam", email_address: "sam@example.com", password: "secret123456")
    assert user.save(context: :signup), user.errors.full_messages.inspect
  end

  private
    def create_new_user
      User.create!(name: "User", email_address: "user@example.com", password: "secret123456")
    end
end
