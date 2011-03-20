class EmailArchive < ActiveRecord::Base
  def body=(str)
    self.body_gzip = ActiveSupport::Gzip.compress(@body = str)
  end
  def body
    @body ||= ActiveSupport::Gzip.decompress(self.body_gzip)
  end
end
