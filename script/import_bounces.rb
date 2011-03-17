$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), "lib"))
Dir[File.join(File.dirname(__FILE__), "vendor", "gems", "*")].each do |dir|
  File.exists?(libdir = File.join(dir, "lib")) ? $LOAD_PATH.unshift(libdir) : $LOAD_PATH.unshift(dir)
end
require 'rubygems'
require 'mail'
require 'mail_util'
require 'deliveryboy/client'

outbox_maildir = ARGV.pop
while not ARGV.empty?
  filename = ARGV.shift
  raw = open(filename) {|f| f.read}
  bounce = MailUtil.new(raw)
  if not bounce.original.to_s == ""
    puts filename
    puts Deliveryboy::Client.queue(bounce.original.to_s, outbox_maildir)
    puts bounce.send :get_embedded_mail, /rfc822/i
  end
end
