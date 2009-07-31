class PrintSummary
  # compulsary stuff
  include Deliveryboy::Maildir::Plugin

  def initialize(owner)
  end

  def handle(tmail_object)
    log "from:#{tmail_object.from} subject:#{tmail_object.subject} (#{tmail_object.to_s.length} bytes)"
  end

  # optional stuff
  include Deliveryboy::Loggable
end
