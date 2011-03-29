require 'deliveryboy/rails/active_record'
require 'deliveryboy/loggable'
require 'deliveryboy/plugins'
require 'email_archive'

class Deliveryboy::Plugins::Archive
  include Deliveryboy::Plugins # Deliveryboy::Maildir needs this to load plugins properly
  include Deliveryboy::Loggable # to use "logger"
  include Deliveryboy::Rails::ActiveRecord # establish connection

  def initialize(config)
  end

  def handle(mail, recipient)
    EmailArchive.create!(:message_id => mail.message_id, :body => mail.to_s)
    logger.debug "[archive] #{mail.message_id}"
  end
end