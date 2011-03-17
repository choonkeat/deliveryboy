require 'spec_helper'
require 'deliveryboy/maildir'

describe Deliveryboy::Maildir do
  Deliveryboy::Loggable.logger = Logger.new(STDOUT)

  before(:each) do
    @maildirpath = "#{Rails.root}/tmp/maildir-#{$$}"
    FileUtils.mkdir_p(@maildirpath)
  end

  after(:each) do
    FileUtils.rm_rf @maildirpath
  end

  it "creates a Maildir where configured" do
    maildir = Deliveryboy::Maildir.new({
      :maildir => @maildirpath,
      :plugins => [ ]
    })
    File.exists?(@maildirpath).should be_true
    ["new", "cur", "tmp", "err"].each {|subdir| File.exists?(File.join(@maildirpath, subdir)).should be_true }
  end

  it "creates a Maildir where configured" do
    maildir = Deliveryboy::Maildir.new({
      :maildir => @maildirpath,
      :plugins => [ ]
    })
    File.exists?(@maildirpath).should be_true
    ["new", "cur", "tmp", "err"].each {|subdir| File.exists?(File.join(@maildirpath, subdir)).should be_true }
  end
end