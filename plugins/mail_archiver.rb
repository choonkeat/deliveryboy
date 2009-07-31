class MailArchiver
  # compulsary stuff
  include Deliveryboy::Maildir::Plugin

  def initialize(owner)
    @prefix = owner.class.name.downcase.gsub(/\W+/, '-')
    @dirname = "archives"
    File.makedirs(@dirname)
  end

  def handle(tmail_object)
    filename = File.join(@dirname, "#{@prefix}-#{Time.now.to_f}-#{$$}.mail")
    open(filename, "w") {|f| f.write(tmail_object.to_s) }
    log "saved at #{filename}"
  end

  # optional stuff
  include Deliveryboy::Loggable
end
