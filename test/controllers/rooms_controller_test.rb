require "test_helper"

class RoomsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in :david
  end

  test "index redirects to the user's last room" do
    get rooms_url
    assert_redirected_to room_url(users(:david).rooms.last)
  end

  test "show" do
    get room_url(users(:david).rooms.last)
    assert_response :success
  end

  test "shows records the last room visited in a cookie" do
    get room_url(users(:david).rooms.last)
    assert response.cookies[:last_room] = users(:david).rooms.last.id
  end

  test "destroy" do
    assert_turbo_stream_broadcasts :rooms, count: 1 do
      assert_difference -> { Room.count }, -1 do
        delete room_url(rooms(:designers))
      end
    end
  end

  test "destroy only allowed for creators or those who can administer" do
    sign_in :jz

    assert_no_difference -> { Room.count } do
      delete room_url(rooms(:designers))
      assert_response :forbidden
    end

    rooms(:designers).update! creator: users(:jz)

    assert_difference -> { Room.count }, -1 do
      delete room_url(rooms(:designers))
    end
  end

  test "show displays welcome invite in original room for admin" do
    accounts(:signal).update!(settings: { "restrict_invite_to_administrators" => "true" })

    get room_url(Room.original)
    assert_response :success
    assert_match "system_welcome", response.body
  end

  test "show displays welcome invite in original room for member when unrestricted" do
    sign_in :kevin
    Room.original.memberships.find_or_create_by!(user: users(:kevin))

    get room_url(Room.original)
    assert_response :success
    assert_match "system_welcome", response.body
  end

  test "show hides welcome invite in original room for member when restricted" do
    accounts(:signal).update!(settings: { "restrict_invite_to_administrators" => "true" })

    sign_in :kevin
    Room.original.memberships.find_or_create_by!(user: users(:kevin))

    get room_url(Room.original)
    assert_response :success
    assert_no_match "system_welcome", response.body
  end
end
