require 'spec_helper'
require 'deliveryboy/maildir'
require 'deliveryboy/plugins/history'
require 'deliveryboy/plugins/newsletter'

class AuditLog
  attr_accessor :logs
  def initialize
    @logs = []
  end
  def method_missing(method, *args)
    @logs << [method, args]
  end
end

describe Deliveryboy::Plugins::Newsletter do
  before(:each) do
    Deliveryboy::Loggable.logger = AuditLog.new
    @plugin = Deliveryboy::Plugins::Newsletter.new({})
    @normal_mail = Mail.new(:from => 'Frommer <from@testfrom.com>', :to => 'Toer <to@testto.com>', :cc => 'Ccer <cc@testcc.com>', :bcc => 'Bccer <bcc@testbcc.com>', :subject => "Hello world", :message_id => FactoryGirl.attributes_for(:mail)[:message_id])
    @selected_recipient = @normal_mail.destinations[rand(@normal_mail.destinations.length)]
    @selected_email_address = EmailAddress.find_or_create_by_email(@selected_recipient)
  end

  it "should NOT allow from blocked FROM" do
    @selected_email_address.blocked_lists.create!(:sender => @normal_mail.froms.first)
    @plugin.handle(@normal_mail, @selected_recipient).should == false
  end

  it "should NOT allow from blocked List-ID" do
    @normal_mail['List-ID'] = "List-#{Time.now.to_f}"
    @selected_email_address.blocked_lists.create!(:sender => @normal_mail['List-ID'].value)
    @plugin.handle(@normal_mail, @selected_recipient).should == false
  end

  it "should allow from unblocked sender" do
    @plugin.handle(@normal_mail, @selected_recipient).should_not == false
  end

  it "should add 'List-Unsubscribe' header when configured :unsubscribe_url_prefix" do
    @history = Deliveryboy::Plugins::History.new({ })
    @plugin = Deliveryboy::Plugins::Newsletter.new({ :unsubscribe_url_prefix => 'http://example.com' })
    @history.handle(@normal_mail, @selected_recipient).should_not == false
    @plugin.handle(@normal_mail, @selected_recipient).should_not == false
    @normal_mail['List-Unsubscribe'].value.should =~ /<\w+\:\/\/.+unsubscribe>/
  end

end