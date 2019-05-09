# frozen_string_literal: true

module Scim
  module V2
    class UsersController < ::Scim::Controller
      PAGE_SIZE=25
      rescue_from ActiveRecord::RecordNotFound do |_error|
        @resource_id = params[:id] if params[:id].present?
        render "record_not_found", status: :not_found
      end

      def index
        @page = params.fetch(:startIndex, 1).to_i
        @page_size = params.fetch(:count, Scim::V2::UsersController::PAGE_SIZE).to_i
        @total = User.count
        @users = @page_size >= 0 ? User.offset(@page - 1).limit(@page_size) : User.none
        render formats: :scim, status: :ok
      end

      def show
        @user = User.find(params[:id])
        response.headers['Location'] = scim_v2_user_url(@user)
        fresh_when(@user)
        render formats: :scim, status: :ok
      end

      def create
        user = repository.create!(user_params)
        response.headers['Location'] = user.meta.location
        render json: user.to_json, status: :created
      end

      def update
        user = repository.update!(params[:id], user_params)
        response.headers['Location'] = user.meta.location
        render json: user.to_json, status: :ok
      end

      def destroy
        repository.destroy!(params[:id])
      end

      private

      def user_params
        params.permit(:schemas, :userName, :locale, :timezone)
      end

      def repository(container = Spank::IOC)
        container.resolve(:user_repository)
      end
    end
  end
end
