require 'rubygems'
require 'bundler'
Bundler.require

require 'sinatra'
require "active_support/all"

Rabl.register!

class LogRequest
  attr_reader :text, :time, :created_at, :execution_time
  def initialize(time, execution_time, text)
    @text = text
    @time = time
    @created_at = Time.now
    @execution_time = Time.now
  end

  @@log = []
  def self.log_request(time, execution_time, text)
    @@log << LogRequest.new(time, execution_time, text)
  end

  def self.log
    @@log
  end

  def self.clear_log!
    @@log = []
  end

end

LogRequest.log_request Time.now, 2.hours.from_now, "Just do it alreay"

get '/' do
  @logs = LogRequest.log
  render :rabl, :logs, :format => "json"
end

post '/' do
  request = JSON.parse(params['request'])['post']
  LogRequest.log_request request['time'], request['execution_time'], request['text']
  @logs = LogRequest.log
  render :rabl, :logs, :format => "json"  
end
