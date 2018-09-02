# frozen_string_literal: true

module My
  class MfasController < ApplicationController
    def show
      redirect_to current_user.tfa.setup? ? edit_my_mfa_path : new_my_mfa_path
    end

    def new
      return redirect_to edit_my_mfa_path if current_user.tfa.setup?
      current_user.tfa.build_secret
    end

    def create
      current_user.update!(params.require(:user).permit(:tfa_secret))
      redirect_to my_dashboard_path, notice: "successfully updated!"
    end

    def edit; end

    def destroy
      current_user.tfa.disable!
      redirect_to my_dashboard_path
    end
  end
end