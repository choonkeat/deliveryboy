require 'spec_helper'

describe "email_addresses/edit.html.erb" do
  before(:each) do
    @email_address = assign(:email_address, stub_model(EmailAddress,
      :email => "MyString",
      :unique => "MyString"
    ))
  end

  it "renders the edit email_address form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => email_addresses_path(@email_address), :method => "post" do
      assert_select "input#email_address_email", :name => "email_address[email]"
      assert_select "input#email_address_unique", :name => "email_address[unique]"
    end
  end
end
