class Pluginfalse
  include Deliveryboy::Maildir::Plugin

  def initialize(config)
  end

  def handle(tmail_object)
    false
  end

  include Deliveryboy::Loggable
end
