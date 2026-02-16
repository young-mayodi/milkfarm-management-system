module Api
  class AuthController < Api::ApplicationController
    skip_before_action :authenticate_request!, only: [:login]
    
    def login
      user = User.find_by(email: params[:email])
      
      if user && user.authenticate(params[:password])
        # Generate token
        token = SecureRandom.hex(32)
        user.update(auth_token: token)
        
        render json: {
          success: true,
          user: user_json(user),
          token: token
        }
      else
        render json: { error: 'Invalid credentials' }, status: :unauthorized
      end
    end

    def logout
      current_user&.update(auth_token: nil)
      render json: { success: true }
    end

    def user
      render json: {
        user: user_json(current_user)
      }
    end

    private

    def user_json(user)
      {
        id: user.id,
        email: user.email,
        first_name: user.first_name,
        last_name: user.last_name,
        role: user.role,
        farm_id: user.farm_id
      }
    end
  end
end
