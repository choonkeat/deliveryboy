require 'spec_helper'

describe "email_histories/show.html.erb" do
  before(:each) do
    @email_history = assign(:email_history, stub_model(EmailHistory,
      :to_email_id => 1,
      :from_email_id => 1,
      :message_id => "Message",
      :unique => EmailHistory.new.set_unique,
      :bounce_reason => "Bounce Reason"
    ))
  end

  it "renders attributes in <p>" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/1/)
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/1/)
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/Message/)
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/Bounce Reason/)
  end
end
