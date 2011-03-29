require 'deliveryboy/loggable'
require 'deliveryboy/plugins'
require 'timeout'

class Deliveryboy::Plugins::Mta
  include Deliveryboy::Plugins # Deliveryboy::Maildir needs this to load plugins properly
  include Deliveryboy::Loggable # to use "logger"

  module ModifiableDestinations
    def destinations=(args)
      @destinations = args
    end
    def destinations
      @destinations || super
    end
  end

  DEFAULT_CONFIG = {
    :class      => "Mail::SMTP",
    :method     => "deliver!",
    :returnpath => nil,
    :timeout    => 60,
    :config     => {},
    :agent      => Mail::SMTP.new({}),
  }

  def initialize(config)
    @sorted_configs = (config[:from] || [['@', {}]]).inject([]) do |sum, (from, hash)|
      cfg = DEFAULT_CONFIG.merge(config).merge(hash)
      cfg[:agent] = cfg[:class].constantize.new(cfg[:config])
      sum + [[from.to_s, cfg]]
    end.sort_by {|(a,b)| a.length}.reverse!
  end

  def match_config_for(sender_email)
    @sorted_configs.find {|(substring, hash)| sender_email.index(substring) } || ['default', DEFAULT_CONFIG]
  end

  def handle(mail, recipient)
    match, config = match_config_for(mail.sender || mail.from_addrs.first)
    mail.extend(ModifiableDestinations)
    mail.destinations = [recipient]
    mail.return_path = config[:returnpath] || mail.sender || mail.from_addrs.first
    start = Time.now.to_f
    Timeout::timeout(config[:timeout]) do # throws Timeout::Error
      config[:agent].send(config[:method], mail)
    end
    logger.debug "[mta] sent to #{mail.destinations.join(',')} via #{match} #{config[:class]} in #{Time.now.to_f - start}s"
  end
end