require 'spec_helper'
require 'deliveryboy/maildir'
require 'deliveryboy/plugins/urlrewrite'
require 'deliveryboy/plugins/history'

class AuditLog
  attr_accessor :logs
  def initialize
    @logs = []
  end
  def method_missing(method, *args)
    @logs << [method, args]
  end
end

def collect_html_elements(mail, selector, &block)
  mail.html_parts.collect do |part|
    Nokogiri::HTML.parse(part.body.to_s, nil, part.charset).css(selector).collect(&block)
  end.flatten
end

describe Deliveryboy::Plugins::UrlRewrite do
  before(:each) do
    Deliveryboy::Loggable.logger = AuditLog.new
    @history = Deliveryboy::Plugins::History.new({ })
    @plugin = Deliveryboy::Plugins::UrlRewrite.new({ :url_prefix => 'https://new.com' })
    @normal_mail = Mail.new(:from => 'Frommer <from@testfrom.com>', :to => 'Toer <to@testto.com>', :cc => 'Ccer <cc@testcc.com>', :bcc => 'Bccer <bcc@testbcc.com>', :subject => "Hello world", :message_id => FactoryGirl.attributes_for(:mail)[:message_id])
    @text_part = Mail::Part.new(:content_type => 'text/plain; charset=UTF-8', :body => 'hello world')
    @html_part = Mail::Part.new(:content_type => 'text/html; charset=UTF-8', :body => '<p>hello world</p>')
    @link_part = Mail::Part.new(:content_type => 'text/html; charset=UTF-8', :body => '<p><a href="http://example.com/1">one</a></p><p><a href="http://example.com/2">two</a></p><p><a href="unsubscribe">unsubscribe</a></p>')
    @imgs_part = Mail::Part.new(:content_type => 'text/html; charset=UTF-8', :body => '<p><img src="http://example.com/3.jpg"/></p><p><img src="http://example.com/4.gif"></p>')
    @selected_recipient = @normal_mail.destinations[rand(@normal_mail.destinations.length)]
    @selected_recipient.should_not be_blank
  end

  it "should leave text mail untouched" do
    @normal_mail.add_part(@text_part)
    txt = @normal_mail.to_s
    @history.handle(@normal_mail, @selected_recipient).should_not be_false
    @plugin.handle(@normal_mail, @selected_recipient).should_not be_false
    @normal_mail.to_s.should == txt
  end

  it "should rewrite all <A> tags in HTML" do
    @normal_mail.add_part(@link_part)
    before_links = collect_html_elements(@normal_mail, 'a') {|a| a['href'] }
    @history.handle(@normal_mail, @selected_recipient).should_not be_false
    @plugin.handle(@normal_mail, @selected_recipient).should_not be_false
    after_links = collect_html_elements(@normal_mail, 'a') {|a| a['href'] }
    before_links.should_not == after_links
    after_links.each_with_index do |link, index|
      parts = URI.parse(link).path.split('/')
      action, history_unique, link_unique = [parts.pop, parts.pop, parts.pop]
      action.should == "visit"
      Link.find_by_unique(link_unique).url.should == before_links[index]
      history = EmailHistory.find_by_unique(history_unique)
      history.message_id.should == @normal_mail.message_id
      history.to.email.should == @selected_recipient
    end
  end

  it "should rewrite unsubscribe links specially if configured" do
    @plugin = Deliveryboy::Plugins::UrlRewrite.new({ :url_prefix => 'https://new.com', :unsubscribe_url_prefix => 'http://list.com' })
    @normal_mail.add_part(@link_part)
    before_links = collect_html_elements(@normal_mail, 'a') {|a| a['href'] }
    @history.handle(@normal_mail, @selected_recipient).should_not be_false
    @plugin.handle(@normal_mail, @selected_recipient).should_not be_false
    after_links = collect_html_elements(@normal_mail, 'a') {|a| a['href'] }
    before_links.should_not == after_links
    after_links.each_with_index do |link, index|
      parts = URI.parse(link).path.split('/')
      action, history_unique, link_unique = [parts.pop, parts.pop, parts.pop]
      if index == after_links.length-1
        action.should == "unsubscribe"
      else
        action.should == "visit"
      end
      Link.find_by_unique(link_unique).url.should == before_links[index]
      history = EmailHistory.find_by_unique(history_unique)
      history.message_id.should == @normal_mail.message_id
      history.to.email.should == @selected_recipient
    end
  end

  it "should rewrite only the first <img> tag in HTML" do
    @normal_mail.add_part(@imgs_part)
    before_links = collect_html_elements(@normal_mail, 'img') {|img| img['src'] }
    @history.handle(@normal_mail, @selected_recipient).should_not be_false
    @plugin.handle(@normal_mail, @selected_recipient).should_not be_false
    after_links = collect_html_elements(@normal_mail, 'img') {|img| img['src'] }
    before_links.first.should_not == after_links.first
    before_links[1..-1].should == after_links[1..-1]
    after_links[0..0].each_with_index do |link, index|
      parts = URI.parse(link).path.split('/')
      action, history_unique, link_unique = [parts.pop, parts.pop, parts.pop]
      action.should == "open"
      Link.find_by_unique(link_unique).url.should == before_links[index]
      history = EmailHistory.find_by_unique(history_unique)
      history.message_id.should == @normal_mail.message_id
      history.to.email.should == @selected_recipient
    end
  end

  it "should add a <img> tag in HTML if none exists" do
    @normal_mail.add_part(@link_part)
    before_links = collect_html_elements(@normal_mail, 'img') {|img| img['src'] }
    before_links.should be_empty
    @history.handle(@normal_mail, @selected_recipient).should_not be_false
    @plugin.handle(@normal_mail, @selected_recipient).should_not be_false
    after_links = collect_html_elements(@normal_mail, 'img') {|img| img['src'] }
    after_links.should_not be_empty
    after_links[0..0].each_with_index do |link, index|
      parts = URI.parse(link).path.split('/')
      action, history_unique, link_unique = [parts.pop, parts.pop, parts.pop]
      action.should == "open"
      history = EmailHistory.find_by_unique(history_unique)
      history.message_id.should == @normal_mail.message_id
      history.to.email.should == @selected_recipient
    end
  end
end