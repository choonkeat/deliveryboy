class Pluginerror
  include Deliveryboy::Plugins # Deliveryboy::Maildir needs this to load plugins properly

  def initialize(config)
  end

  def handle(mail, emailaddr)
    raise self.class
  end

  include Deliveryboy::Loggable
end
