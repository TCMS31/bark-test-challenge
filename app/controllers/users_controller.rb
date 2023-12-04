# frozen_string_literal: true

# Signup. The controller only marshals params and picks a response; every rule
# about what a valid user looks like lives in User and PasswordPolicy.
class UsersController < ApplicationController
  # Recovering from a missing +user+ key means re-rendering *this* controller's
  # form, so it is handled here rather than in ExceptionHandler.
  rescue_from ActionController::ParameterMissing, with: :missing_user_params

  before_action :set_user, only: :show

  def show; end

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)

    if @user.save
      redirect_to user_path(@user), notice: t('.success')
    else
      render :new, status: :unprocessable_entity
    end
  rescue ActiveRecord::RecordNotUnique
    # Two concurrent signups can both pass the uniqueness validation; the
    # unique index is what actually settles it. Turn the 500 into a form error.
    @user.errors.add(:email, :taken)
    render :new, status: :unprocessable_entity
  end

  private

  def set_user
    @user = User.find(params[:id])
  end

  def user_params
    params.require(:user).permit(:email, :password, :password_confirmation)
  end

  def missing_user_params(exception)
    # +@user+ must exist or the form in +new+ cannot be built at all.
    @user = User.new
    flash.now[:alert] = "Required parameters are missing: #{exception.param}"
    render :new, status: :bad_request
  end
end
