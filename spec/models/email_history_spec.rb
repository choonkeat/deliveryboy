require 'spec_helper'
require 'mail'

describe EmailHistory do

  describe "bounced emails" do
    @yml = YAML.load(IO.read("#{Rails.root}/spec/fixtures/bounce_cases.yml"))
    @yml.each do |key, hash|
      it "should obtain the correct status for #{key}" do
        data = IO.read("#{Rails.root}/spec/fixtures/bounce_cases/#{key}.txt")
        mail = Mail.new(data)
        mail.should be_bounced
        mail.error_status.should == hash['status']
        mail.bounced_message.to.should include hash['original_to']
        mail.bounced_message.message_id.should == hash['message_id']
      end
    end
  end

end
