require 'deliveryboy/plugins'

class Deliveryboy::Plugins::Noop
  include Deliveryboy::Plugins # Deliveryboy::Maildir needs this to load plugins properly

  def initialize(config)
  end

  def handle(mail, emailaddr)
  end
end
