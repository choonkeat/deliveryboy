class Deliveryboy
  module Loggable
    def log(str)
      puts "#{$$} [#{self.class.name}] #{str}"
    end
  end
end
