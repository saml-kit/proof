# frozen_string_literal: true

json.schemas ["urn:ietf:params:scim:api:messages:2.0:Error"]
json.detail @error.message
json.status "403"
