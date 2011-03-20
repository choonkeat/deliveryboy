require 'deliveryboy/plugins'

class Deliveryboy::Plugins::RecordMail
  # compulsary stuff
  include Deliveryboy::Maildir::Plugin

  def initialize(config)
  end

  def handle(mail)
    from_email_addresses = mail.from.collect do |addr|
      EmailAddress.find_or_create_by_email(EmailAddress.base_email(addr))
    end
    to_email_addresses = [mail.to, mail.cc, mail.bcc].flatten.compact.collect do |addr|
      EmailAddress.find_or_create_by_email(EmailAddress.base_email(addr))
    end
    if mail.bounced? && bounce = mail.bounced_message
      EmailHistory.where(:message_id => bounce.message_id).update_all({
        :bounce_at => Time.now,
        :bounce_reason => mail.diagnostic_code,
      })
    else
      from_email_addresses.each do |from_email|
        to_email_addresses.each do |to_email|
          EmailHistory.create!({:from => from_email, :to => to_email, :message_id => mail.message_id, :subject => mail.subject})
        end
      end
    end
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