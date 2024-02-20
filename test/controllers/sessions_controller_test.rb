# frozen_string_literal: true

require 'test_helper'
require_relative 'application_controller_test'

class SessionsControllerTest < ApplicationControllerTest
  test "the sign-in button should mention using your A2N account" do
    sign_out
    get :new
    assert_select(
      '.sign-in_button',
      /Acts/i,
      "No mention of Acts 2 Network made on the sign in button."
    )
  end

  test "the sign-in page should redirect the user to the songs index if already signed in" do
    setup
    get :new
    assert_redirected_to songs_path
  end

  test "signing out redirects to the sign-in page" do
    get :destroy
    assert_redirected_to sign_in_path
  end

  test "signing in should set user fields in the session and redirect to songs index" do
    sign_out
    name = "A2N Member"
    email = "gpmember@acts2.network"
    # manually mock the info that would be sent by Google servers
    request.env['omniauth.auth'] = {
      "info" => {
        "name" => name,
        "email" => email
      }
    }
    get :create, params: { provider: "google_oauth2" }
    assert_equal(email, session[:user_email], "Email not set correctly in the session")
    assert_not_nil(session[:name], "Name not set in the session")
    assert_includes(Role::VALID_ROLES, session[:role], "A valid role was not set in the session")

    assert_redirected_to songs_path
  end

  test "a failed sign-in should redirect the user to the sign in path" do
    get :error
    assert_redirected_to sign_in_path
  end

  test "create should create never-before-seen users as Readers" do
    sign_out
    email = "never-before-seen@acts2.network"
    request.env['omniauth.auth'] = {
      "info" => {
        "name" => "Never before seen",
        "email" => email
      }
    }
    assert_difference('User.count', 1, "No new user was created") do
      get :create, params: { provider: "google_oauth2" }
    end
    assert_equal(Role::READER, User.find(email).role, "New users should have a role of Reader")
  end

  test "destroy should clear the user's cookie" do
    get :destroy
    assert_nil(session[:user_email], "Destroy did not clear the user's cookie")
  end
end
