module Deliveryboy
  module MailExtension
    def bounced_part
      @bounced_part ||= self.parts.find {|p| p.mime_type == "message/rfc822"}
    end
    def bounced_message
      Mail.new(self.bounced_part.body) if bounced_part
    end
    def bounced_hard?
      !!(error_status =~ /^5/)
    end
    def bounced_soft?
      bounced? && (! hard_bounce?)
    end
  end
end

Mail::Message.send :include, Deliveryboy::MailExtension