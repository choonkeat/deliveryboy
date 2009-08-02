require 'deliveryboy/client'

class ArchiveMail
  # compulsary stuff
  include Deliveryboy::Maildir::Plugin

  def initialize(config)
    @maildir = config["maildir"]
    @limit   = config["limit"]
    File.makedirs(@maildir)
  end

  def handle(tmail_object)
    filename = Deliveryboy::Client.queue(tmail_object.to_s, @maildir)
    logger.info "saved at #{filename}"
    if @limit
      # File.dirname() because file could be saved into a subdir,
      # and we just want to cull files in that subdir
      files = Dir[File.join(File.dirname(filename), "*.*")]
      length = files.length
      if length > @limit
        files.sort_by {|f| File.mtime(f) }[0...length-@limit].each do |ancient_file|
          File.delete(ancient_file)
        end
      end
    end
  end

  # optional stuff
  include Deliveryboy::Loggable
end
