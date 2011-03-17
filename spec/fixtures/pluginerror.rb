class Pluginerror
  include Deliveryboy::Maildir::Plugin

  def initialize(config)
  end

  def handle(tmail_object)
    raise self.class
  end

  include Deliveryboy::Loggable
end
