# Read about factories at https://github.com/thoughtbot/factory_bot

FactoryBot.define do
  factory :usage_sample do
    institution { nil }
    data { 'MyText' }
  end
end
