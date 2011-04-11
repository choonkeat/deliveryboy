require 'spec_helper'

describe ApisController do

  before(:each) do
    @raw = Mail.new(:from => 'hello@example.com', :to => 'world@example.com')
    @maildirpath = "#{Rails.root}/tmp/maildir-#{$$}"
    ["new", "cur", "tmp", "err"].each {|subdir| FileUtils.mkdir_p(File.join(@maildirpath, subdir))}
    ApisController::CONFIG.stub(:[]) { @maildirpath }
  end

  after(:each) do
    FileUtils.rm_rf @maildirpath
  end

  describe "POST 'deliver'" do
    it "should write HTTP POST body into outbox/new" do
      Dir["#{@maildirpath}/*/*"].should be_empty
      request.env['RAW_POST_DATA'] = @raw.to_s
      post 'deliver'
      Dir["#{@maildirpath}/new/*"].should_not be_empty
      IO.read(Dir["#{@maildirpath}/new/*"].first).should == @raw.to_s
    end
  end
end
