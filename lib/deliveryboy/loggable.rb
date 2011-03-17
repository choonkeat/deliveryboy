module Deliveryboy
  module Loggable
    def self.logger=(val)
      @@logger=val
    end
    def self.logger
      @@logger
    end
    def logger
      @@logger
    end
  end
end
