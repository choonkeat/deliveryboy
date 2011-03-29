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
    @plugin = Deliveryboy::Plugins::Mta.new({ :class => 'NullMta', :method => 'deliver_method' })
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
    @plugin = Deliveryboy::Plugins::Mta.new({ :class => 'NullMta', :method => 'overslept', :timeout => 1 })
    lambda { @plugin.handle(@normal_mail, @selected_recipient) }.should raise_error
  end

  context "configuration" do
    it "should use default config if not specified" do
      @plugin = Deliveryboy::Plugins::Mta.new({ })
      match, found_config = @plugin.match_config_for("sender@example.com")
      found_config[:class].should == Deliveryboy::Plugins::Mta::DEFAULT_CONFIG[:class]
      found_config[:method].should == Deliveryboy::Plugins::Mta::DEFAULT_CONFIG[:method]
      found_config[:returnpath].should == Deliveryboy::Plugins::Mta::DEFAULT_CONFIG[:returnpath]
      found_config[:timeout].should == Deliveryboy::Plugins::Mta::DEFAULT_CONFIG[:timeout]
    end

    it "should override values only where configured specifically" do
      [[:class, 'NullMta'], [:method, 'overslept'], [:returnpath, 'returnpath@example.com'], [:timeout, 1]].each do |(globalkey,globalvalue)|
        [[:class, 'Mail::SMTP'], [:method, 'deliver!'], [:returnpath, 'specific@example.com'], [:timeout, 2]].each do |(specifickey,specificvalue)|
          @plugin = Deliveryboy::Plugins::Mta.new({
            globalkey => globalvalue, :from => {
              "ender@example.com"  => {specifickey => "Hash"},
              "sender@example.com" => {specifickey => specificvalue},
          }})
          match, found_config = @plugin.match_config_for("sender@example.com")
          [:class, :method, :returnpath, :timeout].each do |k|
            case k
            when specifickey
              found_config[k].should == specificvalue
            when globalkey
              found_config[k].should == globalvalue
            else
              found_config[k].should == Deliveryboy::Plugins::Mta::DEFAULT_CONFIG[k]
            end
          end
        end
      end
    end
  end

end