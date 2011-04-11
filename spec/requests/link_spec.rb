require 'spec_helper'

describe "Link Rewrites" do

  before(:each) do
    @url = "http://example.com/#{rand}"
    @history = FactoryGirl.create(:email_history)
  end

  describe "GET /links/*args/:link/:history/:activity" do
    it "should resolve 'visit' urls correctly" do
      @history.visit_at.should be_nil
      @history.open_at.should be_nil
      get Link.rewrite('/', @url, @history, 'visit')
      response.should redirect_to(@url)
      @history.reload
      @history.visit_at.should_not be_nil
      @history.open_at.should_not be_nil
    end

    it "should resolve 'open' urls correctly" do
      @history.visit_at.should be_nil
      @history.open_at.should be_nil
      get Link.rewrite('/', @url, @history, 'open')
      response.should redirect_to(@url)
      @history.reload
      @history.visit_at.should be_nil
      @history.open_at.should_not be_nil
    end
  end

  describe "GET /links/*args/:link/:history/unsubscribe" do
    it "should resolve 'unsubscribe' urls correctly" do
      @history.visit_at.should be_nil
      @history.open_at.should be_nil
      get Link.rewrite('/', @url, @history, 'unsubscribe')
      block = @history.to.blocked_lists.last
      block.should_not be_nil
      block.sender.should == @history.from.email
    end
  end
end
