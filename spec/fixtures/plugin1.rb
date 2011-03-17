class Plugin1
  include Deliveryboy::Maildir::Plugin

  def initialize(config)
  end

  def handle(tmail_object)
    logger.info self.class
  end

  include Deliveryboy::Loggable
end
