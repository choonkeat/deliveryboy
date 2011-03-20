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
      @plugins = (config[:plugins] || []).collect {|hash| Deliveryboy::Plugins.load(hash[:script]).new(hash) }
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
      # looks for file in maildir/new/, maildir/cur/ and maildir/ itself. (avoids maildir/tmp/)
      @fullmatch ||= File.join(@maildir, @dirmatch, @filematch)
      mtime, filename = Dir[@fullmatch].inject([]) do |current, f|
        mt = File.mtime(f)
        (current.empty? || mt < current[0]) ? [mt, f] : current
      end
      # oldest file, by mtime
      filename
    end

    def run
      while not @terminated
        while (filename = self.get_filename).nil?
          sleep @throttle
          return if @terminated
        end # filename.nil?
        self.handle(filename)
      end
    ensure
      logger.debug "#{@maildir} closed"
    end
  end
end
