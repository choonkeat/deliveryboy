require 'deliveryboy/loggable'
require 'deliveryboy/maildir'
require 'logger'

class Deliveryboy::Daemon
  include Deliveryboy::Loggable

  def initialize(config)
    config[:logger] ||= {}
    Deliveryboy::Loggable.logger = (config[:logger][:path].to_s.strip == "") ? Logger.new(STDOUT) : Logger.new(config[:logger][:path])
    logger.level = config[:logger][:level] || Logger::DEBUG
    @maildirs = config[:maildirs].collect {|cfg| Deliveryboy::Maildir.new(cfg)}
  end

  def run
    trap("INT") { logger.info "shutting down ..."; @maildirs.each {|dir| dir.terminated = true} }
    logger.info "Ctrl-C to terminate"
    threads = @maildirs.collect {|dir| Thread.new { dir.run } }
    threads.collect {|t| t.join }
  end
end

