require 'deliveryboy/plugins'
require 'deliveryboy/loggable'
require 'email_address'
require 'email_history'

class Deliveryboy::Plugins::History
  include Deliveryboy::Plugins # Deliveryboy::Maildir needs this to load plugins properly
  include Deliveryboy::Loggable # to use "logger"

  def initialize(config)
    @config = config.reverse_merge({
      :hard_bounce => 1.month,
      :soft_bounce => 1.day,
    })
  end

  def find_or_create_email_addresses(list)
    list.collect { |addr| EmailAddress.find_or_create_by_email(EmailAddress.base_email(addr)) }
  end

  def handle(mail, recipient)
    time_now = Time.now
    if mail.probably_bounced? && bounce = mail.bounced_message
      histories = EmailHistory.where(:message_id => bounce.message_id).includes(:to)
      bounce_type = (mail.bounced_hard? ? 'hard' : 'soft')
      penalty = @config[:"#{bounce_type}_bounce"]
      history_update = {
        :bounce_at => time_now,
        :bounce_reason => mail.diagnostic_code,
      }
      to_update = {
        :penalized_message_id => mail.message_id,
        :allow_to_since => penalty.since(time_now),
        :"#{bounce_type}_bounce_at" => time_now,
      }
      logger.debug "[history] #{bounce_type} bounced (#{histories.collect(&:id).join(',')}) #{bounce.subject}"
      EmailHistory.transaction do
        histories.each do |history|
          history.update_attributes(history_update)
          unless currently_more_severe = history.to.allow_to_since.to_i >= to_update[:allow_to_since].to_i
            logger.debug "[history] #{bounce_type} bounced penalty #{history.to.email}"
            history.to.update_attributes(to_update)
          end
        end
      end
    else
      histories = []
      EmailHistory.transaction do
        find_or_create_email_addresses(mail.from).each do |from_email|
          find_or_create_email_addresses([recipient]).each do |to_email|
            if to_email.allow_to_since && to_email.allow_to_since.to_i > time_now.to_i
              logger.debug "[history] excluding #{to_email.email} until #{to_email.allow_to_since}"
              return false
            else
              histories << EmailHistory.create!({:from => from_email, :to => to_email, :message_id => mail.message_id, :subject => mail.subject})
            end
          end
        end
      end
      logger.debug "[history] recorded (#{histories.collect(&:id).join(',')}) From:#{mail.from.join(',')} To:#{mail.destinations.join(',')} Subject:#{mail.subject}"
    end
  end
end