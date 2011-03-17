class Pluginerror
  # compulsary stuff
  include Deliveryboy::Maildir::Plugin

  def initialize(config)
  end

  def handle(tmail_object)
    raise self.class
  end

  # optional stuff
  include Deliveryboy::Loggable
end
