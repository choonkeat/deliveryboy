require 'deliveryboy/client'

class ArchiveMail
  # compulsary stuff
  include Deliveryboy::Maildir::Plugin

  def initialize(config)
    @dirname = config["dirname"]
    @limit   = config["limit"]
    File.makedirs(@dirname)
  end

  def handle(tmail_object)
    filename = Deliveryboy::Client.queue(tmail_object.to_s, @dirname)
    logger.debug "saved at #{filename}"
    if @limit
      files = Dir[File.join(@dirname, '**', '*.*.*')]
      if files.length > @limit
        files.sort_by {|f| File.mtime(f) }[@limit..-1].each do |ancient_file|
          File.delete(ancient_file)
        end
      end
    end
  end

  # optional stuff
  include Deliveryboy::Loggable
end
