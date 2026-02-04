ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...

    # Helper to sign in a user for integration tests
    def sign_in(user)
      post login_url, params: { session: { email: user.email, password: "password123" } }
    end

    # Helper to sign out current user
    def sign_out
      delete logout_url
    end
  end
end
