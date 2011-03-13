require 'spec_helper'

describe "email_histories/index.html.erb" do
  before(:each) do
    assign(:email_histories, [
      stub_model(EmailHistory,
        :to_email_id => 1,
        :from_email_id => 2,
        :message_id => "Message",
        :bounce_reason => "Bounce Reason"
      ),
      stub_model(EmailHistory,
        :to_email_id => 1,
        :from_email_id => 2,
        :message_id => "Message",
        :bounce_reason => "Bounce Reason"
      )
    ])
  end

  it "renders a list of email_histories" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => 1.to_s, :count => 2
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => 2.to_s, :count => 2
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => "Message".to_s, :count => 2
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => "Bounce Reason".to_s, :count => 2
  end
end
