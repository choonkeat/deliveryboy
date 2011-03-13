require 'spec_helper'

describe "email_addresses/show.html.erb" do
  before(:each) do
    @email_address = assign(:email_address, stub_model(EmailAddress,
      :email => "Email",
      :unique => "Unique"
    ))
  end

  it "renders attributes in <p>" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/Email/)
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/Unique/)
  end
end
