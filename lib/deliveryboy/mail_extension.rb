module Deliveryboy
  module MailExtension
    def bounced_part
      @bounced_part ||= self.parts.find {|p| p.mime_type == "message/rfc822"} || probably_bounced? && begin
        # blank link, followed immediately by "some-key: value"
        body_s = self.charset ? self.body.to_s.encode(self.charset) : self.body.to_s
        if body_s =~ /\n[\r\n]+([\w\-]+\: .+)\Z/m
          Mail::Part.new(:body => $1)
        end
      end
    end
    def bounced_message
      if bounced_part
        Mail.new(self.bounced_part.body)
      end
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
    def froms
      return self.from if self.from.kind_of?(Array)
      field = Mail::FromField.new(self.from.to_s.scan(/\S+@\S+/).last)
      Mail::AddressContainer.new(field, [field.to_s])
    end
  end
end

# String encoding from utf-8 to utf-8 doesn't trigger encoder options like {invalid: :replace}
# Hack: do a utf-8 > utf-16le > utf-8 hop
Mail::Ruby19.class_eval do
  class << self
    alias :b_value_decode_optimistic :b_value_decode
    def b_value_decode(str)
      value = b_value_decode_optimistic(str)
      return value if value.valid_encoding?
      value.encode("utf-16le", :invalid => :replace, :replace => "").encode("utf-8", :invalid => :replace, :replace => "")
    end
    alias :q_value_decode_optimistic :q_value_decode
    def q_value_decode(str)
      value = q_value_decode_optimistic(str)
      return value if value.valid_encoding?
      value.encode("utf-16le", :invalid => :replace, :replace => "").encode("utf-8", :invalid => :replace, :replace => "")
    end
  end
end

Mail::Message.send :include, Deliveryboy::MailExtension