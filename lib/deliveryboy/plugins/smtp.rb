require 'deliveryboy/plugins'

class Deliveryboy::Plugins::Smtp
  # compulsary stuff
  include Deliveryboy::Maildir::Plugin

  def initialize(config)
    @smtp = Mail::SMTP.new(config)
  end

  def handle(mail)
    # mail.return_path = "donotreply@#{`hostname`.strip}"
    start = Time.now.to_f
    @smtp.deliver!(mail)
    logger.debug "[smtp] sent via #{@smtp.settings[:address]}:#{@smtp.settings[:port]} in #{Time.now.to_f - start}s"
  end

  # optional stuff
  include Deliveryboy::Loggable
end