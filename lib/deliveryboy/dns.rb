module Deliveryboy
  class DNS
    def mx(hostname)
      list = Resolv::DNS.open {|dns| dns.getresources hostname, Resolv::DNS::Resource::IN::MX }
      hostnames = list.sort_by {|l| l.preference }.collect {|l| l.exchange.to_s }
      hostnames.empty? ? [hostname] : hostnames
    end
    def txt(hostname)
      list = Resolv::DNS.open {|dns| dns.getresources hostname, Resolv::DNS::Resource::IN::TXT }
    end
    # http://www.openspf.org/Why?show-form=1&identity=mrtweet.net&ip-address=74.50.48.74&.submit=Submit
  end
end