require 'spec_helper'
require 'deliveryboy/maildir'
require 'deliveryboy/plugins/history'

class AuditLog
  attr_accessor :logs
  def initialize
    @logs = []
  end
  def method_missing(method, *args)
    @logs << [method, args]
  end
end

describe Deliveryboy::Plugins::History do
  before(:each) do
    Deliveryboy::Loggable.logger = AuditLog.new
    randoffset = rand(100)
    @hard_bounce = randoffset + 5
    @soft_bounce = randoffset + 1
    @plugin = Deliveryboy::Plugins::History.new({ :hard_bounce => @hard_bounce, :soft_bounce => @soft_bounce })
    @normal_mail = Mail.new(:from => 'Frommer <from@testfrom.com>', :to => 'Toer <to@testto.com>', :cc => 'Ccer <cc@testcc.com>', :bcc => 'Bccer <bcc@testbcc.com>', :subject => "Hello world", :message_id => FactoryGirl.attributes_for(:mail)[:message_id])
    @soft_bounced_mail = mock(Mail::Message, :probably_bounced? => true, :bounced_hard? => false, :from => ['mailerdaemon@testto.com'], :to => @normal_mail.froms, :cc => nil, :bcc => nil, :destinations => ['mailerdaemon@testto.com'], :bounced_message => @normal_mail, :message_id => FactoryGirl.attributes_for(:mail)[:message_id], :subject => 'Delivery Status Notification (Delay)', :diagnostic_code => "oops")
    @hard_bounced_mail = mock(Mail::Message, :probably_bounced? => true, :bounced_hard? => true, :from => ['mailerdaemon@testto.com'], :to => @normal_mail.froms, :cc => nil, :bcc => nil, :destinations => ['mailerdaemon@testto.com'], :bounced_message => @normal_mail, :message_id => FactoryGirl.attributes_for(:mail)[:message_id], :subject => 'Delivery Status Notification (Delay)', :diagnostic_code => "oops")
  end

  context "Outgoing mail" do
    before(:each) do
      @selected_recipient = @normal_mail.destinations[rand(@normal_mail.destinations.length)]
    end

    it "should create EmailAddress entry for 'from' and 'recipient', if it does not exist" do
      EmailAddress.delete_all
      @plugin.handle(@normal_mail, @selected_recipient).should_not == false
      @normal_mail.froms.each {|email| EmailAddress.where(:email => email).count.should == 1}
      [@selected_recipient].each {|email| EmailAddress.where(:email => email).count.should == 1}
      # count should not increase
      @plugin.handle(@normal_mail, @selected_recipient).should_not == false
      @normal_mail.froms.each {|email| EmailAddress.where(:email => email).count.should == 1}
      [@selected_recipient].each {|email| EmailAddress.where(:email => email).count.should == 1}
    end
    it "should create an EmailHistory record for 'from' and 'recipient' pair" do
      histories = EmailHistory.where(:message_id => @normal_mail.message_id)
      histories.should be_empty
      @plugin.handle(@normal_mail, @selected_recipient).should_not == false
      histories = EmailHistory.where(:message_id => @normal_mail.message_id)
      histories.should_not be_empty
      histories.length.should == 1
    end
    it "should return false when encountering penalized recipients" do
      @plugin.handle(@normal_mail, @selected_recipient)
      @plugin.handle(@hard_bounced_mail, @hard_bounced_mail.destinations.first)
      newmail = Mail.new(:from => @normal_mail.froms, :to => @normal_mail.destinations + ['innocent1@test.com', 'innocent2@test.com'], :subject => "Hello world")
      @plugin.handle(newmail, @selected_recipient).should be_false
    end
  end

  context "Bounced mail" do
    before(:each) do
      @selected_recipient = @normal_mail.destinations[rand(@normal_mail.destinations.length)]
      @plugin.handle(@normal_mail, @selected_recipient).should_not == false
      @history = EmailHistory.find_by_message_id(@normal_mail.message_id)
      @history.bounce_at.should be_nil
      @history.bounce_reason.should be_nil
      @now = Time.now
    end
    it "should update an existing EmailHistory record" do
      count = EmailHistory.count
      @plugin.handle(@hard_bounced_mail, "not used").should_not == false
      EmailHistory.count.should == count
      @history.reload
      @history.bounce_at.should_not be_nil
      @history.bounce_reason.should_not be_nil
    end
    it "should not penalise sender" do
      @plugin.handle(@hard_bounced_mail, "not used").should_not == false
      @history.reload
      @history.from.allow_from_since.should < @now
    end
    it "should penalise recipient for soft bounce" do
      @plugin.handle(@soft_bounced_mail, "not used").should_not == false
      @history.reload
      @history.to.allow_to_since.to_i.should >= @soft_bounce.since(@now).to_i
    end
    it "should penalise recipient for hard bounce" do
      @plugin.handle(@hard_bounced_mail, "not used").should_not == false
      @history.reload
      @history.to.allow_to_since.to_i.should >= @hard_bounce.since(@now).to_i
    end
    it "should remember the message_id of the bounce when penalized" do
      @plugin.handle(@soft_bounced_mail, "not used").should_not == false
      @history.reload
      @history.to.penalized_message_id.should == @soft_bounced_mail.message_id
      @plugin.handle(@hard_bounced_mail, "not used").should_not == false
      @history.reload
      @history.to.penalized_message_id.should == @hard_bounced_mail.message_id
    end
    it "should not reduce existing penalty" do
      @plugin.handle(@hard_bounced_mail, "not used").should_not == false
      @history.reload
      @history.to.allow_to_since.to_i.should >= @hard_bounce.since(@now).to_i
      @plugin.handle(@soft_bounced_mail, "not used").should_not == false
      @history.reload
      @history.to.allow_to_since.to_i.should >= @hard_bounce.since(@now).to_i
    end
  end
end