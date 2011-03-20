class EmailHistory < ActiveRecord::Base
  belongs_to :to, :class_name => 'EmailAddress', :foreign_key => 'to_email_id'
  belongs_to :from, :class_name => 'EmailAddress', :foreign_key => 'from_email_id'
  scope :visited, where("visit_at IS NOT NULL")
  scope :opened, where("open_at IS NOT NULL")
  scope :bounced, where("bounce_at IS NOT NULL")
  before_create :set_unique
  def to_param
    self.unique
  end
  def set_unique
    self.unique = UUID.new.generate
  end
end
