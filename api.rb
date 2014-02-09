require 'rubygems'
require 'bundler'
Bundler.require

require 'sinatra'
require "active_support/all"

Rabl.register!

class LogRequest
  attr_reader :text, :time, :created_at, :execution_time, :user_code
  def initialize(user_code, time, execution_time, text)
    @text = text
    @time = time
    @created_at = Time.now
    @execution_time = Time.now
    @user_code = user_code
  end

  @@log = []
  def self.log_request(user_code, time, execution_time, text)
    @@log << LogRequest.new(user_code, time, execution_time, text)
  end

  def self.log
    @@log
  end

  def self.clear_log!
    @@log = []
  end
end

class User
  @@unique_codes = []

  attr_reader :code
  def initialize
    @code = create_unique_code
    @@unique_codes << @code
  end

  def create_unique_code
    @@unique_codes.length + 1
  end
end

# LogRequest.log_request Time.now, 2.hours.from_now, "Just do it alreay"

get '/' do
  if params['user_code']
    @logs = LogRequest.log.select { |log| 
      log if log.user_code == params['user_code'].to_i }
  else
    @logs = LogRequest.log
  end
  render :rabl, :logs, :format => "json"
end

post '/' do
  if params.empty? or params['post'].nil? or params['post']['user_code'].nil?
    status 401
    erb :'401'
  else
    request = JSON.parse(params['post'])
    LogRequest.log_request request['user_code'], request['time'], request['execution_time'], request['text']
    @logs = LogRequest.log
    render :rabl, :logs, :format => "json" 
  end
end
