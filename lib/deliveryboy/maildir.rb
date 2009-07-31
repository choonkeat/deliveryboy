class Deliveryboy
  class Maildir
    include Loggable

    attr_accessor :terminated
    def initialize(config)
      @path = config["path"]
      @filematch = File.join(@path, File.join("**", "[0-9]*"))
      File.makedirs(@path)
      @mtime = File.stat(@path).mtime
      @terminated = false
      @plugins = (config["plugins"] || []).collect {|path| plugin_class(path).new(self) }
      logger.info "#{self.class.name} configured plugins: #{@plugins.collect {|p| p.class.name}.inspect}"
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
        return if plugin.handle(mail) == false
        # callback chain is broken when one returns false
      end
    end

    def get_filename
      Dir[@filematch].first
    end

    def run(&block)
      while not @terminated
        while (filename = self.get_filename).nil?
          while (newmtime = File.stat(@path).mtime) == @mtime
            sleep 1
            return if @terminated
          end # mtime unchanged?
          @mtime = newmtime
        end # filename.nil?
        begin
          logger.info "#{filename}: #{self.class.name} handling ..."
          open(filename, &block)
        ensure
          File.delete filename
          logger.debug "#{filename}: #{self.class.name} removed ..."
        end
      end
    end
  end
end
