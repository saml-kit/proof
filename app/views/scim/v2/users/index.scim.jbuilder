# frozen_string_literal: true

json.schemas [Scim::Kit::V2::Messages::LIST_RESPONSE]
json.totalResults @users.count
json.startIndex @page
json.itemsPerPage Scim::V2::UsersController::PAGE_SIZE
json.Resources do
  json.array! @users do |user|
    json.partial! user, as: :user
  end
end