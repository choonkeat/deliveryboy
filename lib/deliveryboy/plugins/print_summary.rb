class Deliveryboy::Plugins::PrintSummary
  # compulsary stuff
  include Deliveryboy::Maildir::Plugin

  def initialize(config)
  end

  def handle(tmail_object)
    logger.info "recipients:#{tmail_object.destinations.join(',')} subject:#{tmail_object.subject} (#{tmail_object.to_s.length} bytes)"
  end

  # optional stuff
  include Deliveryboy::Loggable
end
