class Link < ActiveRecord::Base
  before_create :set_unique
  def to_param
    self.unique
  end
  def set_unique
    self.unique = UUID.new.generate
  end
  def self.rewrite(url_prefix, url, email_history, action)
    link = self.find_by_url(url) || self.create!({:url => url})
    path = URI.parse(url).path rescue nil
    File.join([url_prefix, 'links', path || "-", link.to_param, email_history.to_param, action])
  rescue Exception
    logger.warn $!
    logger.warn $@
    url
  end
end
