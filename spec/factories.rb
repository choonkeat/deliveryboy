FactoryGirl.define do
  factory :mail do
    sequence :message_id do |n|
      "message#{n}@test.com"
    end
  end
end
