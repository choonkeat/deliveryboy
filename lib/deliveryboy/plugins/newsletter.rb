require 'deliveryboy/plugins'
require 'deliveryboy/loggable'
require 'email_address'
require 'blocked_list'

# When a user unsubscribe, an entry should be created for the user's email + the email.from
# However, emails may come with List-ID headers. In which case, the entry will be between the user's email + List-ID header value

class Deliveryboy::Plugins::Newsletter
  include Deliveryboy::Plugins # Deliveryboy::Maildir needs this to load plugins properly
  include Deliveryboy::Loggable

  def initialize(config)
    @unsubscribe_url_prefix = config[:unsubscribe_url_prefix]
  end

  def handle(mail, recipient)
    if email_address = EmailAddress.find_by_email(recipient)
      possibly_blocked = mail.froms
      possibly_blocked.push(mail['List-ID'].value) if mail['List-ID']
      if blocked = email_address.blocked_lists.where(:sender => possibly_blocked).first
        logger.info "[blocked] #{recipient} blocks #{blocked}"
        return false # stops further processing
      end
      if @unsubscribe_url_prefix && history = EmailHistory.where(:message_id => mail.message_id, :to_email_id => email_address).first
        mail['List-Unsubscribe'] = '<' + Link.rewrite(@unsubscribe_url_prefix, '-', history, 'unsubscribe') + '>'
      end
    end
  end
end
