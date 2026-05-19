require "test_helper"

class UsersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @join_code = accounts(:signal).join_code
  end

  test "show" do
    sign_in :david
    get user_url(users(:david))
    assert_response :ok
  end

  test "new" do
    get join_url(@join_code)
    assert_response :success
  end

  test "new does not allow a signed in user" do
    sign_in :david

    get join_url(@join_code)
    assert_redirected_to root_url
  end

  test "new requires a join code" do
    get join_url("not")
    assert_response :not_found
  end

  test "create" do
    assert_difference -> { User.count }, 1 do
      post join_url(@join_code), params: { user: { name: "New Person", email_address: "new@37signals.com", password: "secret123456" } }
    end

    assert_redirected_to root_url

    user = User.last
    assert_equal user.id, Session.find_by(token: parsed_cookies.signed[:session_token]).user.id
    assert_equal Rooms::Open.all, user.rooms
  end

  test "creating a new user with an existing email address will redirect to login screen" do
    assert_no_difference -> { User.count } do
      post join_url(@join_code), params: { user: { name: "Another David", email_address: users(:david).email_address, password: "secret123456" } }
    end

    assert_redirected_to new_session_url(email_address: users(:david).email_address)
  end

  test "create persists both agreement timestamps when both requirements are configured" do
    accounts(:signal).update!(settings: {
      "code_of_conduct_url" => "https://example.com/coc", "minimum_age" => "18" })

    assert_difference -> { User.count }, 1 do
      post join_url(@join_code), params: { user: {
        name: "Sam", email_address: "sam@example.com", password: "secret123456" } }
    end

    assert_redirected_to root_url
    user = User.last
    assert_not_nil user.code_of_conduct_agreed_at
    assert_not_nil user.minimum_age_attested_at
  end

  test "create does not persist timestamps for requirements that are not configured" do
    accounts(:signal).update!(settings: { "minimum_age" => "18" })

    post join_url(@join_code), params: { user: {
      name: "Sam", email_address: "sam@example.com", password: "secret123456" } }

    assert_redirected_to root_url
    user = User.last
    assert_nil user.code_of_conduct_agreed_at
    assert_not_nil user.minimum_age_attested_at
  end

  test "create succeeds and persists no timestamps when no requirements are configured" do
    assert_difference -> { User.count }, 1 do
      post join_url(@join_code), params: { user: {
        name: "Sam", email_address: "sam@example.com", password: "secret123456" } }
    end

    assert_redirected_to root_url
    user = User.last
    assert_nil user.code_of_conduct_agreed_at
    assert_nil user.minimum_age_attested_at
  end

  test "sign-up page renders the code-of-conduct agreement text and link when URL is set" do
    accounts(:signal).update!(settings: { "code_of_conduct_url" => "https://example.com/coc" })

    get join_url(@join_code)

    assert_response :ok
    assert_match "By signing up, you agree to", response.body
    assert_select "a[href='https://example.com/coc'][target='_blank'][rel~='noopener']", text: "code of conduct"
    assert_match accounts(:signal).name, response.body
  end

  test "sign-up page renders the minimum-age agreement text with the configured number when set" do
    accounts(:signal).update!(settings: { "minimum_age" => "21" })

    get join_url(@join_code)

    assert_response :ok
    assert_match "By signing up, you agree to", response.body
    assert_match "21 years old or older", response.body
  end

  test "sign-up page renders no agreement text when neither requirement is configured" do
    get join_url(@join_code)

    assert_response :ok
    assert_no_match "By signing up, you agree to", response.body
  end
end
