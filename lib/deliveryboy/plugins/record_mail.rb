require 'deliveryboy/plugins'

class Deliveryboy::Plugins::RecordMail
  # compulsary stuff
  include Deliveryboy::Maildir::Plugin

  def initialize(config)
    @config = config.reverse_merge({
      :hard_bounce => 1.month,
      :soft_bounce => 1.day,
    })
  end

  def from_email_addresses(mail)
    mail.from.collect do |addr|
      EmailAddress.find_or_create_by_email(EmailAddress.base_email(addr))
    end
  end
  
  def to_email_addresses(mail)
    mail.destinations.collect do |addr|
      EmailAddress.find_or_create_by_email(EmailAddress.base_email(addr))
    end
  end

  def handle(mail)
    if mail.bounced? && bounce = mail.bounced_message
      histories = EmailHistory.where(:message_id => bounce.message_id, :to_email_id => to_email_addresses(bounce)).includes(:to)
      time_now = Time.now
      bounce_type = (mail.bounced_hard? ? 'hard' : 'soft')
      penalty = @config[:"#{bounce_type}_bounce"]
      history_update = {
        :bounce_at => time_now,
        :bounce_reason => mail.diagnostic_code,
      }
      to_update = {
        :allow_to_since => penalty.since(time_now),
        :"#{bounce_type}_bounce_at" => time_now,
      }
      EmailHistory.transaction do
        histories.each do |history|
          history.update_attributes(history_update)
          currently_more_severe = history.to.allow_to_since.to_i >= to_update[:allow_to_since].to_i
          history.to.update_attributes(to_update) unless currently_more_severe
        end
      end
    else
      from_email_addresses(mail).each do |from_email|
        to_email_addresses(mail).each do |to_email|
          EmailHistory.create!({:from => from_email, :to => to_email, :message_id => mail.message_id, :subject => mail.subject})
        end
      end
    end
  end

  # optional stuff
  include Deliveryboy::Loggable
end