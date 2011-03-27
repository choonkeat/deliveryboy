require 'spec_helper'
require 'deliveryboy/maildir'

class AuditLog
  attr_accessor :logs
  def initialize
    @logs = []
  end
  def method_missing(method, *args)
    @logs << [method, args]
  end
end

describe Deliveryboy::Maildir do

  before(:each) do
    Deliveryboy::Loggable.logger = AuditLog.new
    @maildirpath = "#{Rails.root}/tmp/maildir-#{$$}"
    @maildir_config = {
      :maildir => @maildirpath,
      :throttle => 1,
      :plugins => [
        { :script => "deliveryboy/plugins/noop" },
        { :script => "#{File.dirname(__FILE__)}/../fixtures/plugin1" },
        { :script => "#{File.dirname(__FILE__)}/../fixtures/plugin2" },
      ]
    }
    @maildir = Deliveryboy::Maildir.new(@maildir_config)
  end

  after(:each) do
    FileUtils.rm_rf @maildirpath
  end

  it "creates a Maildir where configured" do
    File.exists?(@maildirpath).should be_true
    ["new", "cur", "tmp", "err"].each {|subdir| File.exists?(File.join(@maildirpath, subdir)).should be_true }
  end

  it "refuse to initialize if configured without plugins defined" do
    @maildir_config.delete :plugins
    lambda { Deliveryboy::Maildir.new(@maildir_config) }.should raise_error
  end

  it "removes the file after handling" do
    mail_file = File.join(@maildirpath, "new", "sample.eml")
    open(mail_file, "w") {|f| f.write(IO.read("#{File.dirname(__FILE__)}/../fixtures/bounce_cases/fullinbox.eml")) }
    File.exists?(mail_file).should be_true
    filename = @maildir.get_filename
    File.absolute_path(filename).should == File.absolute_path(mail_file)
    @maildir.handle(filename)
    File.exists?(mail_file).should be_false
  end

  it "picks files from 'new' subdir chronologically" do
    files = [File.join(@maildirpath, "new", "zzzzz.eml"), File.join(@maildirpath, "new", "aaaaa.eml")]
    files.each do |file|
      open(file, "w") {|f| f.write(IO.read("#{File.dirname(__FILE__)}/../fixtures/bounce_cases/fullinbox.eml")) }
      File.exists?(file).should be_true
      sleep 1
    end
    files.each do |file|
      filename = @maildir.get_filename
      File.absolute_path(filename).should == File.absolute_path(file)
      @maildir.handle(filename)
      File.exists?(file).should be_false
    end
  end

  context "plugins" do
    it "are invoked sequentially" do
      mail_file = File.join(@maildirpath, "new", "sample.eml")
      open(mail_file, "w") {|f| f.write(IO.read("#{File.dirname(__FILE__)}/../fixtures/bounce_cases/fullinbox.eml")) }
      @maildir.handle(@maildir.get_filename)
      log_of_plugin1 = Deliveryboy::Loggable.logger.logs.find {|(method,(*args))| args.last == Plugin1 }
      log_of_plugin2 = Deliveryboy::Loggable.logger.logs.find {|(method,(*args))| args.last == Plugin2 }
      Deliveryboy::Loggable.logger.logs.index(log_of_plugin1).should < Deliveryboy::Loggable.logger.logs.index(log_of_plugin2)
    end
    
    context "encountering errors" do
      it "will place email file in 'err' subdir" do
        @maildir = Deliveryboy::Maildir.new(@maildir_config.merge({
          :plugins => [
            { :script => "#{File.dirname(__FILE__)}/../fixtures/pluginerror" },
          ]
        }))
        mail_file = File.join(@maildirpath, "new", "sample.eml")
        open(mail_file, "w") {|f| f.write(IO.read("#{File.dirname(__FILE__)}/../fixtures/bounce_cases/fullinbox.eml")) }
        @maildir.handle(@maildir.get_filename)
        File.exists?(mail_file).should be_false
        File.exists?(File.join(@maildirpath, "err", "sample.eml")).should be_true
      end

      it "will cause a delay to throttle processing" do
        @maildir = Deliveryboy::Maildir.new(@maildir_config.merge({
          :plugins => [
            { :script => "#{File.dirname(__FILE__)}/../fixtures/pluginerror" },
          ]
        }))
        mail_file = File.join(@maildirpath, "new", "sample.eml")
        open(mail_file, "w") {|f| f.write(IO.read("#{File.dirname(__FILE__)}/../fixtures/bounce_cases/fullinbox.eml")) }
        now = Time.now
        @maildir.handle(@maildir.get_filename)
        Time.now.should >= now + @maildir.instance_variable_get('@throttle')
      end

      it "will break call-chain" do
        @maildir = Deliveryboy::Maildir.new(@maildir_config.merge({
          :plugins => [
            { :script => "#{File.dirname(__FILE__)}/../fixtures/plugin1" },
            { :script => "#{File.dirname(__FILE__)}/../fixtures/pluginerror" },
            { :script => "#{File.dirname(__FILE__)}/../fixtures/plugin2" },
          ]
        }))
        mail_file = File.join(@maildirpath, "new", "sample.eml")
        open(mail_file, "w") {|f| f.write(IO.read("#{File.dirname(__FILE__)}/../fixtures/bounce_cases/fullinbox.eml")) }
        @maildir.handle(@maildir.get_filename)
        log_of_plugin1 = Deliveryboy::Loggable.logger.logs.find {|(method,(*args))| args.last == Plugin1 }
        log_of_plugin2 = Deliveryboy::Loggable.logger.logs.find {|(method,(*args))| args.last == Plugin2 }
        log_of_plugin1.should_not be_nil
        Deliveryboy::Loggable.logger.logs.should include log_of_plugin1
        log_of_plugin2.should be_nil
      end
    end

    context "returning false" do
      it "will break call-chain, but does not put files in 'err' subdir" do
        @maildir = Deliveryboy::Maildir.new(@maildir_config.merge({
          :plugins => [
            { :script => "#{File.dirname(__FILE__)}/../fixtures/plugin1" },
            { :script => "#{File.dirname(__FILE__)}/../fixtures/pluginfalse" },
            { :script => "#{File.dirname(__FILE__)}/../fixtures/plugin2" },
          ]
        }))
        mail_file = File.join(@maildirpath, "new", "sample.eml")
        open(mail_file, "w") {|f| f.write(IO.read("#{File.dirname(__FILE__)}/../fixtures/bounce_cases/fullinbox.eml")) }
        @maildir.handle(@maildir.get_filename)
        log_of_plugin1 = Deliveryboy::Loggable.logger.logs.find {|(method,(*args))| args.last == Plugin1 }
        log_of_plugin2 = Deliveryboy::Loggable.logger.logs.find {|(method,(*args))| args.last == Plugin2 }
        log_of_plugin1.should_not be_nil
        Deliveryboy::Loggable.logger.logs.should include log_of_plugin1
        log_of_plugin2.should be_nil
        File.exists?(mail_file).should be_false
        File.exists?(File.join(@maildirpath, "err", "sample.eml")).should be_false
      end
    end
  end

end