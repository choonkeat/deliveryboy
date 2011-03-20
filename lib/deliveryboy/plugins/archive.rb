require 'deliveryboy/plugins'
require 'email_archive'

class Deliveryboy::Plugins::Archive
  include Deliveryboy::Plugins # Deliveryboy::Maildir needs this to load plugins properly

  def initialize(config)
  end

  def handle(mail, recipient)
    EmailArchive.create!(:message_id => mail.message_id, :body => mail.to_s)
  end
end