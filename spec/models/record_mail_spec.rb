require 'spec_helper'
require 'deliveryboy/maildir'
require 'deliveryboy/plugins/record_mail'

describe Deliveryboy::Plugins::RecordMail do
  before(:each) do
    @plugin = Deliveryboy::Plugins::RecordMail.new({})
    @normal_mail = Mail.new(:from => 'Frommer <from@testfrom.com>', :to => 'Toer <to@testto.com>')
    @bounced_mail = mock(Mail::Message, :bounced? => true, :bounced_hard? => true, :from => ['mailerdaemon@testto.com'], :to => @normal_mail.from, :cc => nil, :bcc => nil, :bounced_message => @normal_mail, :message_id => Mail.new.message_id, :subject => 'Delivery Status Notification (Delay)', :diagnostic_code => "oops")
  end

  context "Outgoing mail" do
    it "should create EmailAddress entry for 'From' if it does not exist" do
      EmailAddress.delete_all
      @plugin.handle(@normal_mail)
      @normal_mail.from.each do |email|
        EmailAddress.where(:email => email).count.should == 1
      end
      @plugin.handle(@normal_mail)
      @normal_mail.from.each do |email|
        EmailAddress.where(:email => email).count.should == 1
      end
    end
    it "should create an EmailHistory record" do
      histories = EmailHistory.where(:message_id => @normal_mail.message_id)
      histories.should be_empty
      @plugin.handle(@normal_mail)
      histories = EmailHistory.where(:message_id => @normal_mail.message_id)
      histories.should_not be_empty
    end
  end

  context "Bounced mail" do
    it "should update an existing EmailHistory record" do
      @plugin.handle(@normal_mail)
      history = EmailHistory.find_by_message_id(@normal_mail.message_id)
      history.bounce_at.should be_nil
      history.bounce_reason.should be_nil
      count = EmailHistory.count
      @plugin.handle(@bounced_mail)
      EmailHistory.count.should == count
      history.reload
      history.bounce_at.should_not be_nil
      history.bounce_reason.should_not be_nil
    end

    it "should penalise sender" do
      @plugin.handle(@normal_mail)
      history = EmailHistory.find_by_message_id(@normal_mail.message_id)
      @plugin.handle(@bounced_mail)
      history.reload
      history.from.allow_from_since.should > Time.now
    end

    it "should penalise recipient" do
      @plugin.handle(@normal_mail)
      history = EmailHistory.find_by_message_id(@normal_mail.message_id)
      @plugin.handle(@bounced_mail)
      history.reload
      history.to.allow_to_since.should > Time.now
    end
  end
end