require 'deliveryboy/client'
require 'deliveryboy/loggable'
require 'deliveryboy/plugins'
require 'fileutils'

class Deliveryboy::Plugins::Exec
  include Deliveryboy::Plugins # Deliveryboy::Maildir needs this to load plugins properly
  include Deliveryboy::Loggable # to use "logger"

  def initialize(config)
    @maildir = config[:maildir]
    @cmdline = config[:cmdline]
    ["new", "cur", "tmp", "err"].each {|subdir| FileUtils.mkdir_p(File.join(@maildir, subdir))} # make a Maildir structure
  end

  def handle(mail, recipient)
    fullpath = Deliveryboy::Client.queue(mail.to_s, @maildir)
    logger.debug "[wrote] #{fullpath}"
    yield fullpath if block_given? # only used for testing
    cmd = @cmdline % fullpath
    logger.debug "[exec] #{cmd}"
    system(cmd) && fullpath
  end
end
