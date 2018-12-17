# frozen_string_literal: true

module My
  class MfasController < ApplicationController
    def show
      redirect_to current_user.mfa.setup? ? edit_my_mfa_path : new_my_mfa_path
    end

    def new
      return redirect_to edit_my_mfa_path if current_user.mfa.setup?

      current_user.mfa.build_secret
    end

    def create
      current_user.update!(params.require(:user).permit(:mfa_secret))
      redirect_to my_dashboard_path, notice: "successfully updated!"
    end

    def edit; end

    def test
      secure_params = params.require(:user).permit(:mfa_secret, :code)
      current_user.mfa_secret = secure_params[:mfa_secret]
      @valid = current_user.mfa.authenticate(secure_params[:code])
      render status: :ok, layout: nil
    end

    def destroy
      current_user.mfa.disable!
      redirect_to my_dashboard_path, notice: 'MFA has been disabled'
    end
  end
end
