require 'spec_helper'
require 'deliveryboy/maildir'
require 'deliveryboy/plugins/exec'

class AuditLog
  attr_accessor :logs
  def initialize
    @logs = []
  end
  def method_missing(method, *args)
    @logs << [method, args]
  end
end

describe Deliveryboy::Plugins::Exec do
  before(:each) do
    Deliveryboy::Loggable.logger = AuditLog.new
    @maildirpath = "#{Rails.root}/tmp/maildir-#{$$}"
    @plugin = Deliveryboy::Plugins::Exec.new({
      :to => {
        "@testto.com" => {:maildir => @maildirpath, :cmdline => "dd if=/dev/null of=%s >/dev/null 2>&1"},
      },
      :from => {
        "@testfrom.com" => {:maildir => @maildirpath, :cmdline => "file %s >/dev/null 2>&1"},
      },
    })
    @normal_mail = Mail.new(:from => 'Frommer <from@testfrom.com>', :to => 'Toer <to@testto.com>', :cc => 'Ccer <cc@testcc.com>', :bcc => 'Bccer <bcc@testbcc.com>', :subject => "Hello world", :message_id => FactoryGirl.attributes_for(:mail)[:message_id])
    @other_mail = Mail.new(:from => 'Frommer <from@not.com>', :to => 'Toer <to@not.com>', :cc => 'Ccer <cc@testcc.com>', :bcc => 'Bccer <bcc@testbcc.com>', :subject => "Hello world", :message_id => FactoryGirl.attributes_for(:mail)[:message_id])
    @selected_recipient = @normal_mail.destinations[rand(@normal_mail.destinations.length)]
  end

  after(:each) do
    FileUtils.rm_rf @maildirpath
  end

  it "should be no-op if unmatched config" do
    @plugin.handle(@other_mail, @selected_recipient).should be_empty
  end

  it "should write file to location and execute command on the file -- for every matched config" do
    @plugin.handle(@normal_mail, @selected_recipient) do |email,match,path|
      case email
      when "from@testfrom.com"
        File.exists?(path).should be_true
        Mail.new(IO.read(path)).message_id.should == @normal_mail.message_id
        File.size(path).should > 0
      when "to@testto.com"
        File.exists?(path).should be_true
        File.size(path).should == 0 # if command ran, the file would now be 0-sized
      end
    end.should_not be_empty
  end

end
