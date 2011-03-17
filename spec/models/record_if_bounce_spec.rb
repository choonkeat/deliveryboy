require 'spec_helper'
require 'deliveryboy/maildir'
require 'deliveryboy/plugins/record_if_bounce'

describe Deliveryboy::Plugins::RecordIfBounce do

  before(:each) do
    @plugin = Deliveryboy::Plugins::RecordIfBounce.new({})
  end

  it "ignores non-bounce emails" do
    @plugin.handle(Mail.new).should be_nil
  end

  it "handles bounce emails" do
    @plugin.handle(Mail.new(IO.read("#{File.dirname(__FILE__)}/../fixtures/bounce_cases/fullinbox.eml"))).should be_true
  end

end