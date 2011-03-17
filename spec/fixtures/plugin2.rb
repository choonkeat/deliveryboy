class Plugin2
  # compulsary stuff
  include Deliveryboy::Maildir::Plugin

  def initialize(config)
  end

  def handle(tmail_object)
    logger.info self.class
  end

  # optional stuff
  include Deliveryboy::Loggable
end
