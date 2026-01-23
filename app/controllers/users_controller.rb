class UsersController < ApplicationController
  before_action :set_user, only: [:show, :edit, :update, :destroy]
  before_action :authorize_farm_management!, except: [:show]
  
  def index
    @users = current_user.farm.users.active.order(:role, :first_name)
    @users = @users.page(params[:page]).per(20)
  end
  
  def show
    # User profile
  end
  
  def new
    @user = current_user.farm.users.build
  end
  
  def create
    @user = current_user.farm.users.build(user_params)
    
    if @user.save
      redirect_to users_path, notice: "User #{@user.full_name} was created successfully"
    else
      render :new, alert: "Error creating user"
    end
  end
  
  def edit
    # Edit user form
  end
  
  def update
    if @user.update(user_params)
      redirect_to @user, notice: "User updated successfully"
    else
      render :edit, alert: "Error updating user"
    end
  end
  
  def destroy
    @user.update(active: false)
    redirect_to users_path, notice: "User deactivated successfully"
  end
  
  def deactivate
    @user.update(active: false)
    redirect_to users_path, notice: "User deactivated successfully"
  end
  
  private
  
  def set_user
    @user = current_user.farm.users.find(params[:id])
  end
  
  def user_params
    params.require(:user).permit(:email, :password, :password_confirmation, 
                                 :first_name, :last_name, :role, :phone)
  end
  
  def authorize_farm_management!
    redirect_to dashboard_path unless current_user.can_manage_farm?
  end
end
