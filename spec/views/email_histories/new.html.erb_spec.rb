require 'spec_helper'

describe "email_histories/new.html.erb" do
  before(:each) do
    assign(:email_history, stub_model(EmailHistory,
      :to_email_id => 1,
      :from_email_id => 1,
      :message_id => "MyString",
      :bounce_reason => "MyString"
    ).as_new_record)
  end

  it "renders new email_history form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => email_histories_path, :method => "post" do
      assert_select "input#email_history_to_email_id", :name => "email_history[to_email_id]"
      assert_select "input#email_history_from_email_id", :name => "email_history[from_email_id]"
      assert_select "input#email_history_message_id", :name => "email_history[message_id]"
      assert_select "input#email_history_bounce_reason", :name => "email_history[bounce_reason]"
    end
  end
end
