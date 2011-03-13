require "spec_helper"

describe EmailAddressesController do
  describe "routing" do

    it "recognizes and generates #index" do
      { :get => "/email_addresses" }.should route_to(:controller => "email_addresses", :action => "index")
    end

    it "recognizes and generates #new" do
      { :get => "/email_addresses/new" }.should route_to(:controller => "email_addresses", :action => "new")
    end

    it "recognizes and generates #show" do
      { :get => "/email_addresses/1" }.should route_to(:controller => "email_addresses", :action => "show", :id => "1")
    end

    it "recognizes and generates #edit" do
      { :get => "/email_addresses/1/edit" }.should route_to(:controller => "email_addresses", :action => "edit", :id => "1")
    end

    it "recognizes and generates #create" do
      { :post => "/email_addresses" }.should route_to(:controller => "email_addresses", :action => "create")
    end

    it "recognizes and generates #update" do
      { :put => "/email_addresses/1" }.should route_to(:controller => "email_addresses", :action => "update", :id => "1")
    end

    it "recognizes and generates #destroy" do
      { :delete => "/email_addresses/1" }.should route_to(:controller => "email_addresses", :action => "destroy", :id => "1")
    end

  end
end
