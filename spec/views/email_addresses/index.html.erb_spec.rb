require 'spec_helper'

describe "email_addresses/index.html.erb" do
  before(:each) do
    assign(:email_addresses, [
      stub_model(EmailAddress,
        :email => "Email",
        :unique => "Unique"
      ),
      stub_model(EmailAddress,
        :email => "Email",
        :unique => "Unique"
      )
    ])
  end

  it "renders a list of email_addresses" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => "Email".to_s, :count => 2
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => "Unique".to_s, :count => 2
  end
end
