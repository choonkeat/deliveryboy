require "socket"
class Deliveryboy
  module Client
    def queue(raw_mail_text, outbox_path, tmpbox_path = Dir::tmpdir)
      unique = [Time.now.to_f, "_", $$, ".", Socket.gethostname.gsub(/\W+/, '_')].join()
      full_tmpbox_path = File.join(tmpbox_path, unique)
      full_outbox_path = File.join(outbox_path, unique)
      open(full_tmpbox_path, "w") {|f| f.write(raw_mail_text) }
      File.rename full_tmpbox_path, full_outbox_path
    end
  end
end
