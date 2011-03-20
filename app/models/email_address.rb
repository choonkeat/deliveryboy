class EmailAddress < ActiveRecord::Base
  has_many :received_messages, :class_name => 'EmailHistory', :foreign_key => 'to_email_id'
  has_many :sent_messages, :class_name => 'EmailHistory', :foreign_key => 'from_email_id'
  before_create :set_unique
  def set_unique
    self.unique = Digest::SHA1.hexdigest(self.email)
  end
  def self.base_email(email)
    email.to_s.gsub(/\+[^@]+@/, '@').downcase
  end
end
