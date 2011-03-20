require 'spec_helper'

describe LinksController do

  before(:each) do
    @link = Link.create(:url => "http://example.com/#{rand}")
    @history = EmailHistory.create(:message_id => "#{rand}")
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
    it "should be successful" do
      get 'unsubscribe', :args => ['x'], :link => @link.to_param, :history => @history.to_param
      response.should be_success
    end
  end

end
