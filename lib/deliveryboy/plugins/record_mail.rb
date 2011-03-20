require 'deliveryboy/plugins'

class Deliveryboy::Plugins::RecordMail
  # compulsary stuff
  include Deliveryboy::Maildir::Plugin

  def initialize(config)
  end

  def from_email_addresses(mail)
    mail.from.collect do |addr|
      EmailAddress.find_or_create_by_email(EmailAddress.base_email(addr))
    end
  end
  
  def to_email_addresses(mail)
    [mail.to, mail.cc, mail.bcc].flatten.compact.collect do |addr|
      EmailAddress.find_or_create_by_email(EmailAddress.base_email(addr))
    end
  end

  def handle(mail)
    if mail.bounced? && bounce = mail.bounced_message
      histories = EmailHistory.where(:message_id => bounce.message_id, :to_email_id => to_email_addresses(bounce)).includes(:from, :to)
      time_now = Time.now
      penalty = (mail.bounced_hard? ? 1.month : 1.day)
      bounce_type = (mail.bounced_hard? ? 'hard' : 'soft')
      history_update = {
        :bounce_at => time_now,
        :bounce_reason => mail.diagnostic_code,
      }
      from_update = {
        :allow_from_since => penalty.since(time_now),
        :"#{bounce_type}_bounce_at" => time_now,
      }
      to_update = {
        :allow_to_since => penalty.since(time_now),
        :"#{bounce_type}_bounce_at" => time_now,
      }
      EmailHistory.transaction do
        histories.each do |history|
          history.update_attributes(history_update)
          history.from.update_attributes(from_update)
          history.to.update_attributes(to_update)
        end
      end
    else
      from_email_addresses(mail).each do |from_email|
        to_email_addresses(mail).each do |to_email|
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