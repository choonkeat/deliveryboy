class EmailAddress < ActiveRecord::Base
  has_many :received_messages, :class_name => 'EmailHistory', :foreign_key => 'to_email_id'
  has_many :sent_messages, :class_name => 'EmailHistory', :foreign_key => 'from_email_id'
  has_many :blocked_lists
  belongs_to :last_penalty, :class_name => 'EmailArchive', :foreign_key => 'penalized_message_id', :primary_key => 'message_id'
  before_create :set_allow_since, :set_unique
  def set_allow_since(t = Time.now)
    self.allow_from_since = t
    self.allow_to_since = t
  end
  def set_unique
    self.unique = Digest::SHA1.hexdigest(self.email)
  end
  def self.base_email(email)
    email.to_s.gsub(/\+[^@]+@/, '@').downcase
  end
end
