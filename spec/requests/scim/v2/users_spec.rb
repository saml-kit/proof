# frozen_string_literal: true

require 'rails_helper'

describe '/scim/v2/users' do
  let(:user) { create(:user) }
  let(:token) { create(:access_token, subject: user).to_jwt }
  let(:headers) do
    {
      'Authorization' => "Bearer #{token}",
      'Accept' => 'application/scim+json',
      'Content-Type' => 'application/scim+json',
    }
  end

  describe "POST /scim/v2/users" do
    context "when a valid request is sent" do
      let(:email) { generate(:email) }
      let(:locale) { 'en' }
      let(:timezone) { 'Etc/UTC' }
      let(:body) { { schemas: [Scim::Kit::V2::Schemas::USER], userName: email, locale: locale, timezone: timezone } }
      let(:json) { JSON.parse(response.body, symbolize_names: true) }

      before { post '/scim/v2/users', params: body.to_json, headers: headers }

      specify { expect(response).to have_http_status(:created) }
      specify { expect(response.headers['Content-Type']).to eql('application/scim+json') }
      specify { expect(response.headers['Location']).to be_present }
      specify { expect(response.body).to be_present }
      specify { expect(json[:schemas]).to match_array([Scim::Kit::V2::Schemas::USER]) }
      specify { expect(json[:id]).to be_present }
      specify { expect(json[:userName]).to eql(email) }
      specify { expect(json[:meta][:resourceType]).to eql('User') }
      specify { expect(json[:meta][:created]).to be_present }
      specify { expect(json[:meta][:lastModified]).to be_present }
      specify { expect(json[:meta][:version]).to be_present }
      specify { expect(json[:meta][:location]).to be_present }
      specify { expect(json[:locale]).to eql(locale) }
      specify { expect(json[:timezone]).to eql(timezone) }
    end

    context "when a duplicate email is specified" do
      let(:other_user) { create(:user) }
      let(:request_body) { attributes_for(:scim_user, userName: other_user.email) }
      let(:json) { JSON.parse(response.body, symbolize_names: true) }

      before { post '/scim/v2/users', params: request_body.to_json, headers: headers }

      specify { expect(response).to have_http_status(:bad_request) }
      specify { expect(json[:schemas]).to match_array(['urn:ietf:params:scim:api:messages:2.0:Error']) }
      specify { expect(json[:scimType]).to eql('uniqueness') }
      specify { expect(json[:detail]).to be_instance_of(String) }
      specify { expect(json[:status]).to eql('400') }
    end
  end

  describe "GET /scim/v2/users/:id" do
    let(:user) { create(:user) }

    context "when the resource is available" do
      before { get "/scim/v2/users/#{user.to_param}", headers: headers }

      let(:json) { JSON.parse(response.body, symbolize_names: true) }

      specify { expect(response).to have_http_status(:ok) }
      specify { expect(response.headers['Content-Type']).to eql('application/scim+json') }
      specify { expect(response.headers['Location']).to eql(scim_v2_user_url(user)) }
      specify { expect(response.headers['ETag']).to be_present }
      specify { expect(response.body).to be_present }

      specify { expect(json[:schemas]).to match_array([Scim::Kit::V2::Schemas::USER]) }
      specify { expect(json[:id]).to eql(user.to_param) }
      specify { expect(json[:userName]).to eql(user.email) }
      specify { expect(json[:meta][:resourceType]).to eql('User') }
      specify { expect(json[:meta][:created]).to eql(user.created_at.iso8601) }
      specify { expect(json[:meta][:lastModified]).to eql(user.updated_at.iso8601) }
      specify { expect(json[:meta][:version]).to eql(response.headers['ETag']) }
      specify { expect(json[:meta][:location]).to eql(scim_v2_user_url(user)) }
      specify { expect(json[:name][:formatted]).to eql(user.email) }
      specify { expect(json[:name][:familyName]).to eql(user.email) }
      specify { expect(json[:name][:givenName]).to eql(user.email) }
    end

    context "when the resource does not exist" do
      let(:json) { JSON.parse(response.body, symbolize_names: true) }

      before { get "/scim/v2/users/#{SecureRandom.uuid}", headers: headers }

      specify { expect(response).to have_http_status(:not_found) }
      specify { expect(json[:schemas]).to match_array(['urn:ietf:params:scim:api:messages:2.0:Error']) }
      specify { expect(json[:detail]).to be_present }
      specify { expect(json[:status]).to eql('404') }
    end

    context "when a valid Authorization header is not provided" do
      let(:user) { create(:user) }
      let(:token) { SecureRandom.uuid }
      let(:json) { JSON.parse(response.body, symbolize_names: true) }

      before { get "/scim/v2/users/#{user.to_param}", headers: headers }

      specify { expect(response).to have_http_status(:unauthorized) }
      specify { expect(json[:schemas]).to match_array(['urn:ietf:params:scim:api:messages:2.0:Error']) }
      specify { expect(json[:detail]).to be_present }
      specify { expect(json[:detail]).to be_instance_of(String) }
      specify { expect(json[:status]).to eql('401') }
    end
  end

  describe "GET /scim/v2/users" do
    context "when fetching all users" do
      let(:json) { JSON.parse(response.body, symbolize_names: true) }
      let!(:user) { create(:user) }

      before { get "/scim/v2/users", headers: headers }

      specify { expect(response).to have_http_status(:ok) }
      specify { expect(response.headers['Content-Type']).to eql('application/scim+json') }
      specify { expect(response.body).to be_present }
      specify { expect(json[:schemas]).to match_array([Scim::Kit::V2::Messages::LIST_RESPONSE]) }
      specify { expect(json[:totalResults]).to be(1) }
      specify { expect(json[:startIndex]).to be(1) }
      specify { expect(json[:itemsPerPage]).to be(25) }
      specify { expect(json[:Resources]).not_to be_empty }
      specify { expect(json[:Resources][0][:id]).to eql(user.to_param) }
      specify { expect(json[:Resources][0][:active]).to be(true) }
      specify { expect(json[:Resources][0][:displayName]).to eql(user.email) }
      specify { expect(json[:Resources][0][:locale]).to eql(user.locale) }
      specify { expect(json[:Resources][0][:timezone]).to eql(user.timezone) }
      specify { expect(json[:Resources][0][:emails]).to match_array([{ primary: true, value: user.email }]) }
      specify { expect(json[:Resources][0][:groups]).to be_empty }
      specify { expect(json[:Resources][0][:meta]).to be_present }
    end

    context "when paginating users" do
      let(:json) { JSON.parse(response.body, symbolize_names: true) }
      let!(:users) { create_list(:user, 10) }

      context "when requesting the first page of results (1-based index)" do
        before { get "/scim/v2/users", params: { startIndex: 1, count: 1 }, headers: headers }

        specify { expect(response).to have_http_status(:ok) }
        specify { expect(response.headers['Content-Type']).to eql('application/scim+json') }
        specify { expect(response.body).to be_present }
        specify { expect(json[:schemas]).to match_array([Scim::Kit::V2::Messages::LIST_RESPONSE]) }
        specify { expect(json[:totalResults]).to be(users.count + 1) }
        specify { expect(json[:startIndex]).to be(1) }
        specify { expect(json[:itemsPerPage]).to be(1) }
        specify { expect(json[:Resources][0][:id]).to eql(User.order(:created_at).offset(0).limit(1).pluck(:id).first) }
      end

      context "when requesting a negative page of results" do
        before { get "/scim/v2/users", params: { startIndex: -1 }, headers: headers }

        specify { expect(response).to have_http_status(:ok) }
        specify { expect(json[:totalResults]).to be(users.count + 1) }
        specify { expect(json[:startIndex]).to be(1) }
        specify { expect(json[:itemsPerPage]).to be(25) }
        specify { expect(json[:Resources]).to be_present }
      end

      context "when requesting a page 0" do
        before { get "/scim/v2/users", params: { startIndex: 0 }, headers: headers }

        specify { expect(response).to have_http_status(:ok) }
        specify { expect(json[:totalResults]).to be(users.count + 1) }
        specify { expect(json[:startIndex]).to be(1) }
        specify { expect(json[:itemsPerPage]).to be(25) }
        specify { expect(json[:Resources]).to be_present }
      end

      context "when requesting an invalid page" do
        before { get "/scim/v2/users", params: { startIndex: 'x' }, headers: headers }

        specify { expect(response).to have_http_status(:ok) }
        specify { expect(json[:totalResults]).to be(users.count + 1) }
        specify { expect(json[:startIndex]).to be(1) }
        specify { expect(json[:itemsPerPage]).to be(25) }
        specify { expect(json[:Resources]).to be_present }
      end

      context "when requesting a page size of 0 results" do
        before { get "/scim/v2/users", params: { count: 0 }, headers: headers }

        specify { expect(response).to have_http_status(:ok) }
        specify { expect(json[:schemas]).to match_array([Scim::Kit::V2::Messages::LIST_RESPONSE]) }
        specify { expect(json[:totalResults]).to be(users.count + 1) }
        specify { expect(json[:startIndex]).to be(1) }
        specify { expect(json[:itemsPerPage]).to be(0) }
        specify { expect(json[:Resources]).to be_empty }
      end

      context "when requesting a page size of negative results" do
        before { get "/scim/v2/users", params: { count: -1 }, headers: headers }

        specify { expect(response).to have_http_status(:ok) }
        specify { expect(json[:totalResults]).to be(users.count + 1) }
        specify { expect(json[:startIndex]).to be(1) }
        specify { expect(json[:itemsPerPage]).to be(0) }
        specify { expect(json[:Resources]).to be_empty }
      end
    end

    context "when searching for users" do
      let!(:users) { create_list(:user, 10) }

      context "when searching for an exact match on one field" do
        let(:matching_user) { users.sample }

        before { get "/scim/v2/users", params: { filter: "userName eq \"#{matching_user.email}\"" }, headers: headers }

        specify { expect(response).to have_http_status(:ok) }
        specify { expect(json[:totalResults]).to be(1) }
        specify { expect(json[:startIndex]).to be(1) }
        specify { expect(json[:itemsPerPage]).to be(25) }
        specify { expect(json[:Resources]).to be_present }
        specify { expect(json[:Resources][0][:id]).to eql(matching_user.to_param) }
      end

      context "when searhing for a match using a logical or condition" do
        let(:first_matching_user) { users.first }
        let(:second_matching_user) { users.last }
        let(:filter) do
          %(userName eq "#{first_matching_user.email}" or userName eq "#{second_matching_user.email}")
        end

        before { get "/scim/v2/users", params: { filter: filter }, headers: headers }

        specify { expect(response).to have_http_status(:ok) }
        specify { expect(json[:totalResults]).to be(2) }
        specify { expect(json[:startIndex]).to be(1) }
        specify { expect(json[:itemsPerPage]).to be(25) }
        specify { expect(json[:Resources]).to be_present }
        specify { expect(json[:Resources].map { |x| x[:id] }.uniq).to match_array([first_matching_user.to_param, second_matching_user.to_param].uniq) }
      end
    end

    xcontext "when fetching specific attributes" do
      let!(:user) { create(:user) }
      let(:json) { JSON.parse(response.body, symbolize_names: true) }

      before { get "/scim/v2/users?attributes=userName", headers: headers }

      specify { expect(response).to have_http_status(:ok) }
      specify { expect(response.headers['Content-Type']).to eql('application/scim+json') }
      specify { expect(response.body).to be_present }
      specify { expect(json[:schemas]).to match_array([Scim::Kit::V2::Messages::LIST_RESPONSE]) }
      specify { expect(json[:totalResults]).to be(1) }
      specify { expect(json[:Resources]).not_to be_empty }
      specify { expect(json[:Resources][0]).to eql(id: user.to_param, displayName: user.email) }
    end
  end

  describe "PUT /scim/v2/users" do
    let(:user) { create(:user) }
    let(:new_email) { FFaker::Internet.email }
    let(:locale) { 'ja' }
    let(:timezone) { 'America/Denver' }
    let(:body) { { schemas: [Scim::Kit::V2::Schemas::USER], userName: new_email, locale: locale, timezone: timezone } }
    let(:json) { JSON.parse(response.body, symbolize_names: true) }

    before { put "/scim/v2/users/#{user.to_param}", headers: headers, params: body.to_json }

    specify { expect(response).to have_http_status(:ok) }
    specify { expect(response.headers['Content-Type']).to eql('application/scim+json') }
    specify { expect(response.headers['Location']).to eql(scim_v2_user_url(user)) }
    specify { expect(response.body).to be_present }
    specify { expect(json[:schemas]).to match_array([Scim::Kit::V2::Schemas::USER]) }
    specify { expect(json[:id]).to be_present }
    specify { expect(json[:userName]).to eql(new_email) }
    specify { expect(json[:meta][:resourceType]).to eql('User') }
    specify { expect(json[:meta][:created]).to be_present }
    specify { expect(json[:meta][:lastModified]).to be_present }
    specify { expect(json[:meta][:version]).to be_present }
    specify { expect(json[:meta][:location]).to be_present }
    specify { expect(json[:emails]).to match_array([value: new_email, primary: true]) }
    specify { expect(json[:locale]).to eql(locale) }
    specify { expect(json[:timezone]).to eql(timezone) }
  end

  describe "DELETE /scim/v2/users/:id" do
    let(:other_user) { create(:user) }

    context "when the user can be deleted" do
      before { delete "/scim/v2/users/#{other_user.to_param}", headers: headers }

      specify { expect(response).to have_http_status(:no_content) }

      specify do
        get "/scim/v2/users/#{other_user.to_param}", headers: headers
        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
