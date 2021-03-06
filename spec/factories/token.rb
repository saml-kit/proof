# frozen_string_literal: true

FactoryBot.define do
  factory :token do
    authorization { nil }
    association :audience, factory: :client
    association :subject, factory: :user

    factory :access_token do
      token_type { :access }
    end

    factory :refresh_token do
      token_type { :refresh }
    end

    trait :revoked do
      revoked_at { Time.current }
    end

    trait :expired do
      expired_at { 1.minute.ago }
    end
  end
end
