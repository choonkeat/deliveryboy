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
    @plugin = Deliveryboy::Plugins::Exec.new({:maildir => @maildirpath, :cmdline => "dd if=/dev/null of=%s 2>/dev/null"})
    @normal_mail = Mail.new(:from => 'Frommer <from@testfrom.com>', :to => 'Toer <to@testto.com>', :cc => 'Ccer <cc@testcc.com>', :bcc => 'Bccer <bcc@testbcc.com>', :subject => "Hello world", :message_id => FactoryGirl.attributes_for(:mail)[:message_id])
    @selected_recipient = @normal_mail.destinations[rand(@normal_mail.destinations.length)]
  end

  after(:each) do
    FileUtils.rm_rf @maildirpath
  end

  it "should write file to location and execute command on the file" do
    fullpath = nil
    handle_return = @plugin.handle(@normal_mail, @selected_recipient) do |p|
      File.exists?(p).should be_true
      Mail.new(IO.read(p)).message_id.should == @normal_mail.message_id
      File.size(p).should > 0
      fullpath = p
    end
    handle_return.should_not == false
    File.size(fullpath).should == 0 # if command ran, the file would now be 0-sized
  end

end
