require 'deliveryboy/loggable'
require 'deliveryboy/plugins'
require 'fileutils'

module Deliveryboy
  class Maildir
    include Loggable

    attr_accessor :terminated
    def initialize(config)
      @throttle  = (config[:throttle] || 5).to_i
      @filematch = config[:filematch] || "*.*"
      @dirmatch  = config[:dirmatch]  || "{new,cur,.}"
      @maildir   = config[:maildir]
      # make a Maildir structure
      ["new", "cur", "tmp", "err"].each {|subdir| FileUtils.mkdir_p(File.join(@maildir, subdir))}
      @terminated = false
      @plugins = config[:plugins].collect {|hash| Deliveryboy::Plugins.load(hash[:script]).new(hash) }
      logger.info "#{@maildir} configured plugins: #{@plugins.collect {|p| p.class.name}.join(', ')}"
    end

    def handle(filename)
      logger.info "handling #{filename}"
      mailtxt = IO.read(filename)
      mailobj = Mail.new(mailtxt)
      mailobj.destinations.each_with_index do |recipient, index|
        logger.debug "recipient: #{recipient.inspect} ..."
        @plugins.each do |plugin|
          logger.debug " - #{plugin.inspect} ..."
          mail = (index == 0 ? mailobj : Mail.new(mailtxt))
          mail.message_id = "#{mail.message_id}-#{index}"
          break if plugin.handle(mail, recipient) == false
          # callback chain is broken when one plugin returns false
        end
      end
      File.delete filename if File.exists?(filename)
    rescue Exception
      # server must continue running so,
      # run "archive_mail" as first plugin
      logger.error $!
      if File.exists?(filename)
        err_filename = File.join(@maildir, "err", File.split(filename).last)
        logger.error "Failed mail archived as #{err_filename} ..."
        File.rename filename, err_filename
      end
      sleep @throttle
    end

    def get_filename
      @sorted_filenames && @sorted_filenames.shift || begin
        # batch operation for filename retrieval & mtime comparison
        @fullmatch ||= File.join(@maildir, @dirmatch, @filematch)     # looks inside maildir/new/, maildir/cur/ and maildir/ itself. (avoids maildir/tmp/)
        @sorted_filenames = Dir[@fullmatch].sort_by {|f| test(?M, f)} # sort by mtime
        @sorted_filenames.shift
      end
    end

    def run
      while not @terminated
        sleep @throttle until filename = self.get_filename || @terminated
        self.handle(filename) unless @terminated
      end
    ensure
      logger.debug "#{@maildir} closed"
    end
  end
end
