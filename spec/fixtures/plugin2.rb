class Plugin2
  include Deliveryboy::Plugins # Deliveryboy::Maildir needs this to load plugins properly

  def initialize(config)
  end

  def handle(mail, emailaddr)
    logger.info self.class
  end

  include Deliveryboy::Loggable
end
