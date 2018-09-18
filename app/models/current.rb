# frozen_string_literal: true

class Current < ActiveSupport::CurrentAttributes
  attribute :client, :user
  attribute :request_id, :user_agent, :ip_address

  def user?
    user.present?
  end
end
