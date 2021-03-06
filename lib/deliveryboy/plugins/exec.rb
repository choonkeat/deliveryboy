require 'deliveryboy/client'
require 'deliveryboy/loggable'
require 'deliveryboy/plugins'
require 'fileutils'

class Deliveryboy::Plugins::Exec
  include Deliveryboy::Plugins # Deliveryboy::Maildir needs this to load plugins properly
  include Deliveryboy::Loggable # to use "logger"

  def initialize(config)
    @sorted_configs = [:from, :to].inject({}) do |sum, key|
      options = (config[key] || []).inject({}) do |s,(k,opts)|
        ["new", "cur", "tmp", "err"].each {|subdir| FileUtils.mkdir_p(File.join(opts[:maildir], subdir))} # make a Maildir structure
        s.merge(k.to_s => opts)
      end.sort_by {|(a,b)| a.length}.reverse
      sum.merge(key => options)
    end
  end

  def match_config_for(key, email)
    @sorted_configs[key].find {|(substring, hash)| email.index(substring) }
  end

  def handle(mail, recipient)
    matches = {:from => mail.froms, :to => (mail.to + [mail['X-Original-To']]).uniq.compact}.inject([]) do |sum,(key,emails)|
      emails.collect(&:to_s).inject(sum) do |s, email|
        if match = match_config_for(key, email)
          s + [match]
        else
          s
        end
      end
    end.uniq.compact
    matches.collect do |match,config|
      fullpath = Deliveryboy::Client.queue(mail.to_s, config[:maildir])
      logger.debug "[wrote] #{fullpath}"
      cmd = config[:cmdline] % fullpath
      logger.debug "[exec] #{cmd}"
      system(cmd)
      yield match,fullpath if block_given? # only used for testing
      fullpath
    end
  end
end
