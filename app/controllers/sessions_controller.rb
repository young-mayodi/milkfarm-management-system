class SessionsController < ApplicationController
  skip_before_action :authenticate_user!, only: [:new, :create, :test]
  skip_before_action :verify_authenticity_token, only: [:create]
  layout false, only: [:new, :test]
  
  def new
    html = <<~HTML
      <!DOCTYPE html>
      <html>
      <head>
        <title>Login - Dairy Farm</title>
        <meta name="viewport" content="width=device-width,initial-scale=1">
        <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
        <style>
          body {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
          }
          .login-card {
            max-width: 400px;
            width: 100%;
            background: white;
            border-radius: 15px;
            box-shadow: 0 10px 30px rgba(0, 0, 0, 0.2);
            overflow: hidden;
          }
        </style>
      </head>
      <body>
        <div class="login-card">
          <div class="card-header text-center py-4">
            <h3>🥛 Dairy Farm Management</h3>
            <p class="mb-0 text-muted">Sign in to your account</p>
          </div>
          <div class="card-body p-4">
            <form action="/login" method="POST">
              <input type="hidden" name="authenticity_token" value="#{form_authenticity_token}">
              <div class="mb-3">
                <label for="email" class="form-label">Email</label>
                <input type="email" name="email" id="email" class="form-control" required>
              </div>
              <div class="mb-3">
                <label for="password" class="form-label">Password</label>
                <input type="password" name="password" id="password" class="form-control" required>
              </div>
              <div class="d-grid">
                <button type="submit" class="btn btn-primary">Sign In</button>
              </div>
            </form>
          </div>
        </div>
      </body>
      </html>
    HTML
    
    render html: html.html_safe
  end
  
  def test
    # Quick login for testing
    if params[:quick_login] == 'true'
      user = User.first
      if user
        session[:user_id] = user.id
        redirect_to dashboard_path, notice: "Quick login successful! Logged in as #{user.first_name}"
      else
        redirect_to login_path, alert: "No users found. Please create a user first."
      end
    else
      render layout: false
    end
  end
  
  def create
    user = User.find_by(email: params[:email]&.downcase)
    
    if user&.authenticate(params[:password])
      session[:user_id] = user.id
      user.update_last_sign_in!
      redirect_to dashboard_path, notice: "Welcome back, #{user.first_name}!"
    else
      render_login_with_error("Invalid email or password")
    end
  end
  
  def destroy
    session[:user_id] = nil
    redirect_to login_path, notice: "Logged out successfully"
  end
  
  private
  
  def render_login_with_error(error_message)
    html = <<~HTML
      <!DOCTYPE html>
      <html>
      <head>
        <title>Login - Dairy Farm</title>
        <meta name="viewport" content="width=device-width,initial-scale=1">
        <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
        <style>
          body {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
          }
          .login-card {
            max-width: 400px;
            width: 100%;
            background: white;
            border-radius: 15px;
            box-shadow: 0 10px 30px rgba(0, 0, 0, 0.2);
            overflow: hidden;
          }
        </style>
      </head>
      <body>
        <div class="login-card">
          <div class="card-header text-center py-4">
            <h3>🥛 Dairy Farm Management</h3>
            <p class="mb-0 text-muted">Sign in to your account</p>
          </div>
          <div class="card-body p-4">
            <div class="alert alert-danger" role="alert">
              <i class="bi bi-exclamation-triangle-fill me-2"></i>
              #{error_message}
            </div>
            <form action="/login" method="POST">
              <input type="hidden" name="authenticity_token" value="#{form_authenticity_token}">
              <div class="mb-3">
                <label for="email" class="form-label">Email</label>
                <input type="email" name="email" id="email" class="form-control" value="#{params[:email]}" required>
              </div>
              <div class="mb-3">
                <label for="password" class="form-label">Password</label>
                <input type="password" name="password" id="password" class="form-control" required>
              </div>
              <div class="d-grid">
                <button type="submit" class="btn btn-primary">Sign In</button>
              </div>
            </form>
          </div>
        </div>
      </body>
      </html>
    HTML
    
    render html: html.html_safe
  end
end
