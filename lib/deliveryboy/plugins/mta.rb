require 'deliveryboy/plugins'
require 'deliveryboy/loggable'
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

  def initialize(config)
    @klass, @method = (config[:invoke] || 'Mail::SMTP#deliver!').split('#')
    @agent = @klass.constantize.new(config.except(:invoke))
    @returnpath = config[:returnpath]
    @timeout = (config[:timeout] || 60).to_i
  end

  def handle(mail, recipient)
    mail.extend(ModifiableDestinations)
    mail.destinations = [recipient]
    mail.return_path = @returnpath || mail.sender || mail.from_addrs.first
    start = Time.now.to_f
    Timeout::timeout(@timeout) do # throws Timeout::Error
      @agent.send(@method, mail)
    end
    logger.debug "[mta] sent to #{mail.destinations.join(',')} via #{@klass} in #{Time.now.to_f - start}s"
  end
end