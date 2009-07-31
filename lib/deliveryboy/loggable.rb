class Deliveryboy
  module Loggable
    def self.logger=(val)
      @@logger=val
    end
    def logger
      @@logger
    end
  end
end
