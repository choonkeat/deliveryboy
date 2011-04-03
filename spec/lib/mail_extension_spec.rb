require 'spec_helper'

describe Deliveryboy::MailExtension do
  describe "bounced emails" do
    @yml = YAML.load(IO.read("#{Rails.root}/spec/fixtures/bounce_cases.yml"))
    @yml.each do |key, hash|
      it "should obtain the correct status for #{key}" do
        data = IO.read("#{Rails.root}/spec/fixtures/bounce_cases/#{key}.eml")
        mail = Mail.new(data)
        mail.should be_probably_bounced
        mail.error_status.should == hash['status']
        mail.bounced_message.to.should include hash['original_to']
        mail.bounced_message.message_id.should == hash['message_id']
      end
    end
  end
  describe "subject with bad encoding" do
    it "should skip invalid characters" do
      m = Mail.new
      m['Subject'] = Mail::SubjectField.new("=?utf-8?Q?Hello_=96_World?=")
      m.subject.should be_valid_encoding
    end
  end
end
