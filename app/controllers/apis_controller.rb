require "deliveryboy/client"
require 'yaml'

class ApisController < ApplicationController
  CONFIG = YAML.load(IO.read(File.join(Rails.root, "config", "api.yml")))

  # e.g. curl -iv -X POST http://localhost:3000/apis/deliver --data-binary @file.eml
  def deliver
    result = Deliveryboy::Client.queue(request.body.read, CONFIG["outbox_maildir"])
    render :text => "Ok"
  end
end
