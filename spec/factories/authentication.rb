FactoryBot.define do
  factory :authentication do
    user

    factory :password_authentication, class: PasswordAuthentication
    factory :totp_authentication, class: TotpAuthentication
  end
end
