FactoryGirl.define do
  factory :mail do
    sequence :message_id do |n|
      "message#{n}@test.com"
    end
  end
  factory :email_address do
    sequence :email do |n|
      "email#{n}@test.com"
    end
    sequence :unique do |n|
      "unique#{n}"
    end
  end
  factory :email_history do
    sequence :message_id do |n|
      "message_id-#{n}"
    end
    association :from, :factory => :email_address
    association :to, :factory => :email_address
  end
end
