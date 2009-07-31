# via http://gist.github.com/157917
#
# = Environment variable configs:
# 
#   HIGHLANDER_PID_PATH
#   - optional, specify which directory the pid file goes.
#   - defaults to same location as script
# 
#   HIGHLANDER_MAX_SECONDS
#   - optional, specify how many seconds to wait before interrupting previous process (owner of pidfile)
#   - defaults to never
# 
#   HIGHLANDER_KILL
#   - signal to end process
#   - defaults INT
# 
#   HIGHLANDER_PING
#   - signal to ping process
#   - defaults USR2
# 
# = Usage example:
# 
#   require 'process/highlander/pid'
#   include Process::Highlander::PID # so there can only be one
#   
#   def do_stuff()
#     sleep 90
#   end
#   
#   do_stuff()
# 
# 1. When running the above script (let's call it "script.rb"), a pid file ("script.rb.pid") will be created alongside.
# 2. Running the same script concurrently, the later process would exit immediately (not go pass line 2 in example above)
# 3. When environment variable HIGHLANDER_MAX_SECONDS is set (e.g. 5), and the first script has been running for more
#    than 5 seconds, running the script again would terminate both scripts, and the pidfile would be removed.
# 
module Process
  module Highlander
    module PID
      def self.included(base)
        path = caller.first.split(':').first
        pidfile = ENV['HIGHLANDER_PID_PATH'] ? File.join(ENV['HIGHLANDER_PID_PATH'], "#{File.split(path).last}.pid") : "#{path}.pid"
        if File.exists?(pidfile)
          # if prev process taking too long, kill it; otherwise, ping it
          signal = (
            (ENV['HIGHLANDER_MAX_SECONDS'] && (Time.now - File.mtime(pidfile)) > ENV['HIGHLANDER_MAX_SECONDS'].to_i) ? 
            (ENV['HIGHLANDER_KILL'] || "INT") :
            (ENV['HIGHLANDER_PING'] || "USR2")
          )
          kill_and_exit(signal, IO.read(pidfile).to_i)
          # if pid cannot be reached (stale), this process proceeds
        end
        open(pidfile, "w") {|f| f.write($$) }
        trap("USR2") { }
        at_exit { File.delete(pidfile) }
      end
      def self.kill_and_exit(sig, pid)
        Process.kill(sig, pid)
        exit(1)
      rescue Errno::ESRCH
        # pid is stale, process does not exist
      end
    end
  end
end
