class Deliveryboy
  class Maildir
    include Loggable

    attr_accessor :terminated
    def initialize(config)
      @maildir = config["maildir"]
      # make a Maildir structure
      ["new", "cur", "tmp"].each {|subdir| File.makedirs(File.join(@maildir, subdir))}
      @mtime = File.stat(@maildir).mtime
      @terminated = false
      @plugins = (config["plugins"] || []).collect {|hash| plugin_class(hash['script']).new(hash) }
      logger.info "#{@maildir} configured plugins: #{@plugins.collect {|p| p.class.name}.join(', ')}"
    end

    PLUGINS = {}
    module Plugin; def self.included(klass); PLUGINS[PLUGINS[:last_script]] = klass; end; end
    def plugin_class(script)
      PLUGINS[:last_script] = script
      require script
      PLUGINS[script]
    end

    def handle(mail)
      @plugins.each do |plugin|
        logger.debug "calling #{plugin.inspect} ..."
        return if plugin.handle(mail) == false
        # callback chain is broken when one returns false
      end
    rescue
      # server must continue running so,
      # run "archive_mail" as first plugin
      logger.error $!
      logger.error $!.backtrace
    end

    def get_filename
      # looks for file in maildir/new/, maildir/cur/ and maildir/ itself. (avoids maildir/tmp/)
      @filematch ||= File.join(@maildir, "{new,cur,.}", "*.*")
      mtime, filename = Dir[@filematch].inject([]) do |current, f|
        mt = File.mtime(f)
        (current.empty? || mt < current[0]) ? [mt, f] : current
      end
      # oldest file, by mtime
      filename
    end

    def run
      while not @terminated
        while (filename = self.get_filename).nil?
          while (newmtime = File.stat(@maildir).mtime) == @mtime
            sleep 5
            return if @terminated
          end # mtime unchanged?
          @mtime = newmtime
        end # filename.nil?
        begin
          logger.info "handling #{filename}"
          open(filename) {|io| self.handle(TMail::Mail.parse(io.read))}
        ensure
          File.delete filename
        end
      end
    ensure
      logger.debug "#{@maildir} closed"
    end
  end
end
