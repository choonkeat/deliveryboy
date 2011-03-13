class Deliveryboy
  class Maildir
    include Loggable

    attr_accessor :terminated
    def initialize(config)
      @filematch = config[:filematch] || "*.*"
      @dirmatch  = config[:dirmatch]  || "{new,cur,.}"
      @maildir   = config[:maildir]
      # make a Maildir structure
      ["new", "cur", "tmp", "err"].each {|subdir| File.makedirs(File.join(@maildir, subdir))}
      @terminated = false
      @plugins = (config[:plugins] || []).collect {|hash| plugin_class(hash['script']).new(hash) }
      logger.info "#{@maildir} configured plugins: #{@plugins.collect {|p| p.class.name}.join(', ')}"
    end

    PLUGINS = {}
    module Plugin; def self.included(klass); PLUGINS[PLUGINS[:last_script]] = klass; end; end
    def plugin_class(script)
      PLUGINS[:last_script] = script
      require script
      PLUGINS[script]
    end

    def handle(filename)
      logger.info "handling #{filename}"
      mail = open(filename) {|io| TMail::Mail.parse(io.read) }
      @plugins.each do |plugin|
        logger.debug "calling #{plugin.inspect} ..."
        return if plugin.handle(mail) == false
        # callback chain is broken when one returns false
      end
      File.delete filename
    rescue Exception
      # server must continue running so,
      # run "archive_mail" as first plugin
      logger.error $!
      err_filename = File.join(@maildir, "err", File.split(filename).last)
      logger.error "Failed mail archived as #{err_filename} ..."
      File.rename filename, err_filename
      sleep 5
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
          sleep 5
          return if @terminated
        end # filename.nil?
        self.handle(filename)
      end
    ensure
      logger.debug "#{@maildir} closed"
    end
  end
end
