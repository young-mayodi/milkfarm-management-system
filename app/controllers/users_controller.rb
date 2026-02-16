class UsersController < ApplicationController
  before_action :set_user, only: [ :show, :edit, :update, :destroy ]
  before_action :authorize_farm_management!, except: [ :show ]

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
      flash.now[:alert] = "Error creating user"
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    # Edit user form
  end

  def update
    if @user.update(filtered_user_params)
      redirect_to @user, notice: "User updated successfully"
    else
      flash.now[:alert] = "Error updating user"
      render :edit, status: :unprocessable_entity
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

  def filtered_user_params
    permitted = user_params
    if permitted[:password].blank? && permitted[:password_confirmation].blank?
      permitted.delete(:password)
      permitted.delete(:password_confirmation)
    end
    permitted
  end

  def authorize_farm_management!
    redirect_to dashboard_path unless current_user.can_manage_farm?
  end
end
