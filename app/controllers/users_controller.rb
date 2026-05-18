class UsersController < ApplicationController
  require_unauthenticated_access only: %i[ new create ]

  before_action :set_user, only: :show
  before_action :verify_join_code, only: %i[ new create ]

  def new
    @user = User.new
  end

  def create
    settings = Current.account.settings
    now = Time.current

    @user = User.new(user_params)
    @user.code_of_conduct_agreed_at = now if settings.code_of_conduct_url.to_s.strip.present?
    @user.minimum_age_attested_at   = now if settings.minimum_age.to_i > 0

    if @user.save(context: :signup)
      start_new_session_for @user
      redirect_to root_url
    else
      flash.now[:alert] = @user.errors.full_messages.to_sentence
      render :new, status: :unprocessable_entity
    end
  rescue ActiveRecord::RecordNotUnique
    redirect_to new_session_url(email_address: user_params[:email_address])
  end

  def show
  end

  private
    def set_user
      @user = User.find(params[:id])
    end

    def verify_join_code
      head :not_found if Current.account.join_code != params[:join_code]
    end

    def user_params
      params.require(:user).permit(:name, :avatar, :email_address, :password,
                                   :agreed_to_code_of_conduct, :attested_minimum_age)
    end
end
