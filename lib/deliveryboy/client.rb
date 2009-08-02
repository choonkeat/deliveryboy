require "socket"
require "tempfile"
class Deliveryboy
  module Client
    # 1. construct "unique.file.name" based on time, process id and hostname
    # 2. write "raw_text" into "outbox_maildir/tmp/unique.file.name" file
    # 3. renames "outbox_maildir/tmp/unique.file.name" to "outbox_maildir/new/unique.file.name"
    def self.queue(raw_mail_text, outbox_maildir)
      unique = [Time.now.to_f, "_", $$, ".", Socket.gethostname.gsub(/\W+/, '_')].join()
      full_tmpbox_path = File.join(outbox_maildir, "tmp", unique)
      full_outbox_path = File.join(outbox_maildir, "new", unique)
      open(full_tmpbox_path, "w") {|f| f.write(raw_mail_text) }
      File.rename full_tmpbox_path, full_outbox_path
      full_outbox_path
    end
  end
end
