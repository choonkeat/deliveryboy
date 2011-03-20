require 'deliveryboy/plugins'
require 'deliveryboy/loggable'
require 'email_history'
require 'link'
require 'nokogiri'

class Deliveryboy::Plugins::UrlRewrite
  include Deliveryboy::Plugins # Deliveryboy::Maildir needs this to load plugins properly
  include Deliveryboy::Loggable

  def initialize(config)
    @url_prefix = config[:url_prefix]
    @unsubscribe_url_prefix = config[:unsubscribe_url_prefix]
  end

  def handle(mail, recipient)
    if history = EmailHistory.where(:message_id => mail.message_id, :to_email_id => EmailAddress.find_by_email(recipient)).first
      supplant!(mail, history)
    end
  end

  def supplant!(container, history)
    container.parts.each do |part|
      case part.content_type
      when /multipart/
        supplant!(part, history)
      when /text\/html/
        doc = Nokogiri::HTML.parse(part.body.to_s, nil, part.charset)
        doc.css('a').each do |anchor|
          if @unsubscribe_url_prefix && anchor.text.to_s =~ /unsubscribe/i && anchor['href'].to_s =~ /unsubscribe/i
            anchor['href'] = Link.rewrite(@unsubscribe_url_prefix, anchor['href'], history, 'unsubscribe')
          else
            case anchor['href']
            when nil, "", /mailto\:/
              # do not rewrite these
            else
              anchor['title'] ||= anchor['href']
              anchor['href'] = Link.rewrite(@url_prefix, anchor['href'], history, 'visit')
            end
          end
        end
        img = doc.css('img[src^=http]').first || begin
          # if there is an image, we use it for open-rate tracking
          # otherwise, we add a smallest possible image to the doc
          doc.root.add_child('<img style="border:0;margin:0;padding:0;display:inline;width:0.1px;height:0.1px;" src="' + @url_prefix + '/images/spacer.gif"/>')
          doc.css('img[src^=http]').first
        end
        img['rel'] = 'open'
        img['src'] = Link.rewrite(@url_prefix, img['src'], history, 'open')
        part.body( Mail::Encodings.get_encoding(part.body.encoding).encode(doc.serialize(:encoding => part.charset)) )
      end
    end
  end
end
