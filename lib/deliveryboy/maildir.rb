class Deliveryboy
  class Maildir
    include Loggable

    attr_accessor :terminated
    def initialize(config)
      @path = config["path"]
      File.makedirs(@path)
      @mtime = File.stat(@path).mtime
      @terminated = false
      @plugins = (config["plugins"] || []).collect {|hash| plugin_class(hash['path']).new(hash) }
      logger.info "#{@path} configured plugins: #{@plugins.collect {|p| p.class.name}.inspect}"
    end

    PLUGINS = {}
    module Plugin; def self.included(klass); PLUGINS[PLUGINS[:last_path]] = klass; end; end
    def plugin_class(path)
      PLUGINS[:last_path] = path
      require path
      PLUGINS[path]
    end

    def handle(mail)
      @plugins.each do |plugin|
        logger.debug "Trying #{plugin.inspect} ..."
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
      @filematch ||= File.join(@path, File.join("**", "[0-9]*"))
      Dir[@filematch].first
    end

    def run
      while not @terminated
        while (filename = self.get_filename).nil?
          while (newmtime = File.stat(@path).mtime) == @mtime
            sleep 5
            return if @terminated
          end # mtime unchanged?
          @mtime = newmtime
        end # filename.nil?
        begin
          logger.info "#{filename}: handling ..."
          open(filename) {|io| self.handle(TMail::Mail.parse(io.read))}
        ensure
          File.delete filename
          logger.debug "#{filename}: removed ..."
        end
      end
    end
  end
end
