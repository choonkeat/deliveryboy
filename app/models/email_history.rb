class EmailHistory < ActiveRecord::Base
  belongs_to :to, :class_name => 'EmailAddress', :foreign_key => 'to_email_id'
  belongs_to :from, :class_name => 'EmailAddress', :foreign_key => 'from_email_id'
end
