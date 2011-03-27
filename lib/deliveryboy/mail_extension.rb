module Deliveryboy
  module MailExtension
    def bounced_part
      @bounced_part ||= self.parts.find {|p| p.mime_type == "message/rfc822"} || probably_bounced? && begin
        # blank link, followed immediately by "some-key: value"
        if self.body.to_s =~ /\n[\r\n]+([\w\-]+\: .+)\Z/m
          Mail::Part.new(:body => $1)
        end
      end
    end
    def bounced_message
      Mail.new(self.bounced_part.body) if bounced_part
    end
    def bounced_hard?
      !!(error_status =~ /^5/)
    end
    def bounced_soft?
      !!probably_bounced? && (! bounced_hard?)
    end
    def probably_bounced?
      self['X-Failed-Recipients'].try(:value).present? ||
      bounced?
    end
    def html_parts(multipart = self)
      list = multipart.parts.empty? ? [multipart] : multipart.parts
      list.inject([]) do |sum, part|
        case part.content_type
        when /multipart/
          sum + html_parts(part)
        when /text\/html/
          sum + [part]
        else
          sum
        end
      end
    end
  end
end

Mail::Message.send :include, Deliveryboy::MailExtension