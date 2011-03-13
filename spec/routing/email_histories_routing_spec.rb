require "spec_helper"

describe EmailHistoriesController do
  describe "routing" do

    it "recognizes and generates #index" do
      { :get => "/email_histories" }.should route_to(:controller => "email_histories", :action => "index")
    end

    it "recognizes and generates #new" do
      { :get => "/email_histories/new" }.should route_to(:controller => "email_histories", :action => "new")
    end

    it "recognizes and generates #show" do
      { :get => "/email_histories/1" }.should route_to(:controller => "email_histories", :action => "show", :id => "1")
    end

    it "recognizes and generates #edit" do
      { :get => "/email_histories/1/edit" }.should route_to(:controller => "email_histories", :action => "edit", :id => "1")
    end

    it "recognizes and generates #create" do
      { :post => "/email_histories" }.should route_to(:controller => "email_histories", :action => "create")
    end

    it "recognizes and generates #update" do
      { :put => "/email_histories/1" }.should route_to(:controller => "email_histories", :action => "update", :id => "1")
    end

    it "recognizes and generates #destroy" do
      { :delete => "/email_histories/1" }.should route_to(:controller => "email_histories", :action => "destroy", :id => "1")
    end

  end
end
