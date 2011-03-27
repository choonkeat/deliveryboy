require 'active_record'
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), "../../../app/models"))

module Deliveryboy
  module Rails
    module ActiveRecord
      def self.included(klass)
        ::ActiveRecord::Base.connection
      rescue ::ActiveRecord::ConnectionNotEstablished
        yaml = YAML.load(IO.read(File.join(File.dirname(__FILE__), "../../../config/database.yml")))
        ::ActiveRecord::Base.establish_connection(HashWithIndifferentAccess.new(yaml)[ ENV['RALIS_ENV'] || 'development' ])
      end
    end
  end
end
