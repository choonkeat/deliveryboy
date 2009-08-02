class SendSmtp
  # compulsary stuff
  include Deliveryboy::Maildir::Plugin

  def initialize(config)
    @host = config["host"]
    @port = config["port"]
    @sender_host = config["sender_host"] || `hostname`.strip
    @return_user = config["return_user"] || "deliveryboy"
  end

  def handle(mail)
    start = Time.now.to_f
    mail.ready_to_send
    Net::SMTP.start(@host, @port, @sender_host) do |smtp|
      smtp.send_message(
        mail.encoded,
        "#{@return_user}@#{@sender_host}", # (mail['return-path'] && mail['return-path'].spec) || mail.from,
        mail.destinations
      )
    end
    logger.debug "sent via #{@host}:#{@port} in #{Time.now.to_f - start}s"
  rescue Exception, IOError, Errno::ECONNREFUSED
    logger.error $!
    logger.error "Retrying after sleep ..."
    sleep 10 + rand(20)
    retry
  end

  # optional stuff
  include Deliveryboy::Loggable
end
