require 'spec_helper'
require 'deliveryboy/maildir'
require 'deliveryboy/plugins/archive'

class AuditLog
  attr_accessor :logs
  def initialize
    @logs = []
  end
  def method_missing(method, *args)
    @logs << [method, args]
  end
end

describe Deliveryboy::Plugins::Archive do
  before(:each) do
    Deliveryboy::Loggable.logger = AuditLog.new
    @plugin = Deliveryboy::Plugins::Archive.new({})
    @normal_mail = Mail.new(:from => 'Frommer <from@testfrom.com>', :to => 'Toer <to@testto.com>', :cc => 'Ccer <cc@testcc.com>', :bcc => 'Bccer <bcc@testbcc.com>', :subject => "Hello world", :message_id => FactoryGirl.attributes_for(:mail)[:message_id])
    @selected_recipient = @normal_mail.destinations[rand(@normal_mail.destinations.length)]
  end

  it "should create an EmailArchive record for each mail" do
    archives = EmailArchive.where(:message_id => @normal_mail.message_id)
    archives.should be_empty
    @plugin.handle(@normal_mail, @selected_recipient).should_not == false
    archives = EmailArchive.where(:message_id => @normal_mail.message_id)
    archives.should_not be_empty
    archives.length.should == 1
  end

  it "should store a compressed version of the email text" do
    @plugin.handle(@normal_mail, @selected_recipient).should_not == false
    archive = EmailArchive.where(:message_id => @normal_mail.message_id).first
    archive.body_gzip.length.should < @normal_mail.to_s.length
    archive.body.should == @normal_mail.to_s
  end
end