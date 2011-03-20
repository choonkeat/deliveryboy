require 'spec_helper'
require 'deliveryboy/maildir'
require 'deliveryboy/plugins/record_mail'

describe Deliveryboy::Plugins::RecordMail do
  before(:each) do
    randoffset = rand(100)
    @hard_bounce = randoffset + 5
    @soft_bounce = randoffset + 1
    @plugin = Deliveryboy::Plugins::RecordMail.new({ :hard_bounce => @hard_bounce, :soft_bounce => @soft_bounce })
    @normal_mail = Mail.new(:from => 'Frommer <from@testfrom.com>', :to => 'Toer <to@testto.com>', :cc => 'Ccer <cc@testcc.com>', :cc => 'Bccer <bcc@testbcc.com>')
    @soft_bounced_mail = mock(Mail::Message, :bounced? => true, :bounced_hard? => false, :from => ['mailerdaemon@testto.com'], :to => @normal_mail.from, :cc => nil, :bcc => nil, :bounced_message => @normal_mail, :message_id => Mail.new.message_id, :subject => 'Delivery Status Notification (Delay)', :diagnostic_code => "oops")
    @hard_bounced_mail = mock(Mail::Message, :bounced? => true, :bounced_hard? => true, :from => ['mailerdaemon@testto.com'], :to => @normal_mail.from, :cc => nil, :bcc => nil, :bounced_message => @normal_mail, :message_id => Mail.new.message_id, :subject => 'Delivery Status Notification (Delay)', :diagnostic_code => "oops")
  end

  context "Outgoing mail" do
    it "should create EmailAddress entry for all related email addresses, if it does not exist" do
      EmailAddress.delete_all
      @plugin.handle(@normal_mail)
      @normal_mail.from.each {|email| EmailAddress.where(:email => email).count.should == 1}
      @normal_mail.destinations.each {|email| EmailAddress.where(:email => email).count.should == 1}
      # count should not increase
      @plugin.handle(@normal_mail)
      @normal_mail.from.each {|email| EmailAddress.where(:email => email).count.should == 1}
      @normal_mail.destinations.each {|email| EmailAddress.where(:email => email).count.should == 1}
    end
    it "should create an EmailHistory record for each from/destination pair" do
      histories = EmailHistory.where(:message_id => @normal_mail.message_id)
      histories.should be_empty
      @plugin.handle(@normal_mail)
      histories = EmailHistory.where(:message_id => @normal_mail.message_id)
      histories.should_not be_empty
      histories.length.should == @normal_mail.destinations.length
    end
  end

  context "Bounced mail" do
    before(:each) do
      @plugin.handle(@normal_mail)
      @history = EmailHistory.find_by_message_id(@normal_mail.message_id)
      @history.bounce_at.should be_nil
      @history.bounce_reason.should be_nil
      @now = Time.now
    end
    it "should update an existing EmailHistory record" do
      count = EmailHistory.count
      @plugin.handle(@hard_bounced_mail)
      EmailHistory.count.should == count
      @history.reload
      @history.bounce_at.should_not be_nil
      @history.bounce_reason.should_not be_nil
    end
    it "should not penalise sender" do
      @plugin.handle(@hard_bounced_mail)
      @history.reload
      @history.from.allow_from_since.should < @now
    end
    it "should penalise recipient accordingly" do
      @plugin.handle(@soft_bounced_mail)
      @history.reload
      @history.to.allow_to_since.to_i.should == @soft_bounce.since(@now).to_i
      @plugin.handle(@hard_bounced_mail)
      @history.reload
      @history.to.allow_to_since.to_i.should == @hard_bounce.since(@now).to_i
    end
    it "should not reduce existing penalty" do
      @plugin.handle(@hard_bounced_mail)
      @history.reload
      @history.to.allow_to_since.to_i.should == @hard_bounce.since(@now).to_i
      @plugin.handle(@soft_bounced_mail)
      @history.reload
      @history.to.allow_to_since.to_i.should == @hard_bounce.since(@now).to_i
    end
  end
end