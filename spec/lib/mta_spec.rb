require 'spec_helper'
require 'deliveryboy/maildir'
require 'deliveryboy/plugins/mta'

class AuditLog
  attr_accessor :logs
  def initialize
    @logs = []
  end
  def method_missing(method, *args)
    @logs << [method, args]
  end
end

class NullMta
  def initialize(config)
    config.kind_of?(Hash).should == true
    config[:invoke].should == nil
  end
  def deliver_method(mail)
    mail.kind_of?(Mail::Message).should == true
  end
  def overslept(mail)
    sleep 2
  end
end

describe Deliveryboy::Plugins::Mta do
  before(:each) do
    Deliveryboy::Loggable.logger = AuditLog.new
    @plugin = Deliveryboy::Plugins::Mta.new({ :invoke => 'NullMta#deliver_method' })
    @normal_mail = Mail.new(:from => 'Frommer <from@testfrom.com>', :to => 'Toer <to@testto.com>', :cc => 'Ccer <cc@testcc.com>', :bcc => 'Bccer <bcc@testbcc.com>', :subject => "Hello world", :message_id => FactoryGirl.attributes_for(:mail)[:message_id])
    @selected_recipient = @normal_mail.destinations[rand(@normal_mail.destinations.length)]
    @selected_recipient.should_not be_blank
  end

  it "should should only send email to selected recipient" do
    @normal_mail.destinations.length.should > 1
    @plugin.handle(@normal_mail, @selected_recipient).should_not be_false
    @normal_mail.destinations.length.should == 1
    @normal_mail.destinations.first.should == @selected_recipient
  end

  it "should throw Timeout::Error when things take too long" do
    @plugin = Deliveryboy::Plugins::Mta.new({ :invoke => 'NullMta#overslept', :timeout => 1 })
    lambda { @plugin.handle(@normal_mail, @selected_recipient) }.should raise_error
  end
end