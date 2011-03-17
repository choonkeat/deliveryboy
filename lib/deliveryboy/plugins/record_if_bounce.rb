require 'deliveryboy/plugins'

class Deliveryboy::Plugins::RecordIfBounce
  # compulsary stuff
  include Deliveryboy::Maildir::Plugin

  def initialize(config)
  end

  def handle(mail)
    return if not mail.bounced?
    # 
    # mail.error_status.should == hash['status']
    # mail.bounced_message.to.should include hash['original_to']
    # mail.bounced_message.message_id.should == hash['message_id']
    # 
    true
  end

  # optional stuff
  include Deliveryboy::Loggable
end