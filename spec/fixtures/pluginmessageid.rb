class Pluginmessageid
  include Deliveryboy::Plugins # Deliveryboy::Maildir needs this to load plugins properly

  def initialize(config)
    @@message_ids = []
  end

  def handle(mail, emailaddr)
    @@message_ids << mail.message_id
  end

  include Deliveryboy::Loggable
end
