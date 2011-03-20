class Pluginfalse
  include Deliveryboy::Plugins # Deliveryboy::Maildir needs this to load plugins properly

  def initialize(config)
  end

  def handle(mail, emailaddr)
    false
  end

  include Deliveryboy::Loggable
end
