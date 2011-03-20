module Deliveryboy
  module Plugins
    LOADED = {}
    def self.included(klass)
      LOADED[LOADED[:last_script]] = klass
    end
    def self.load(script)
      LOADED[:last_script] = script
      require script
      LOADED[script]
    end
  end
end