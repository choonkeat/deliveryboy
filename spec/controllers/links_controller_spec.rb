require 'spec_helper'

describe LinksController do

  before(:each) do
    @link = Link.create(:url => "http://example.com/#{rand}")
    @history = FactoryGirl.create(:email_history)
  end

  after(:each) do
    @link.destroy
    @history.destroy
  end

  describe "GET 'visit'" do
    it "should be successful" do
      get 'visit', :args => ['x'], :link => @link.to_param, :history => @history.to_param, :activity => 'visit'
      response.should redirect_to(@link.url)
    end
  end

  describe "GET 'unsubscribe'" do
    it "should add a BlockedList record for EmailHistory#to" do
      @history.to.blocked_lists.should be_empty
      get 'unsubscribe', :args => ['x'], :link => @link.to_param, :history => @history.to_param
      response.should be_success
      @history.reload
      block = @history.to.blocked_lists.last
      block.should_not be_nil
      block.sender.should == @history.from.email
    end
  end

end
