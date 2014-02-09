require_relative "../api"
require "rspec"
require "rack/test"
require 'spec_helper'
require 'json'

set :environment, :test

describe "The Api" do
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  let(:time) { Time.now }
  let(:user) {double(code: 1)}
  let(:user2) {double(code: 2)}
  def log_request(response)
    JSON.parse(last_response.body)
  end


  before do
    LogRequest.clear_log!
    LogRequest.log_request(user.code, 6.seconds.ago.utc, time.utc, "Hello World")
    LogRequest.log_request(user.code, 6.seconds.ago.utc, time.utc, "Hello World")
    LogRequest.log_request(user2.code, 6.seconds.ago.utc, time.utc, "user 2")
  end

  it "should return json array of log request" do
    get "/"
    # json = JSON.parse(last_response.body)
    log_request = log_request(last_response).first["logrequest"]
    log_request.fetch("text").should eq("Hello World")

    time_in_utc = Time.parse(log_request.fetch("time"))
    time_in_utc.should be_within(1).of(6.seconds.ago.utc)

    execution_time = Time.parse(log_request.fetch("execution_time"))
    execution_time.should be_within(1).of(time.utc)
    
    new_user = log_request.fetch('user_code')
    new_user.should eq(user.code)
  end

  it 'should return all the logs' do
    get '/'
    user_codes = log_request(last_response).map { |log| log['logrequest']['user_code'] }
    user_codes.count.should eq(3)
  end

  it 'should return users logs' do
    get '/', 'user_code' => user.code
    user_codes = log_request(last_response).map { |log| log['logrequest']['user_code'] }
    user_codes.should include(1)
    user_codes.should_not include(2)
    user_codes.count.should eq(2)
  end

  it 'should return user2 logs' do
    get '/', 'user_code' => user2.code
    user_codes = log_request(last_response).map { |log| log['logrequest']['user_code'] }
    user_codes.should include(2)
    user_codes.should_not include(1)
    user_codes.count.should eq(1)
  end

  it 'should store the request in memory from a post' do
    request = {'user_code' => "#{user.code}", 'text' => 'a post', 'time' => "#{Time.now}", 'execution_time' => "#{Time.now}" }.to_json
    post "/", 'post' => request
    log_request = log_request(last_response).last['logrequest']
    log_request.fetch('text').should eq('a post')
  end

  it 'should always post with a user_code' do
    post '/'
    last_response.status.should eq(401)
  end

  it "not be ok with /wack" do
    get "/wack"
    last_response.should_not be_ok
  end
end


describe LogRequest do

  let(:time) { Time.now }
  let(:user) { double(code: 1) }
  let(:subject) { LogRequest.new(user.code, 45.minutes.ago, time, "Just Record it")}


  it "should have the text" do
    subject.text.should eq("Just Record it")
  end
  it "should keep the time" do
    subject.time.should be_within(0.01).of(45.minutes.ago)
  end

  it 'should tell the execution time' do
    subject.execution_time.should be_within(1).of(time)
  end

  it 'should tell the user code' do
    subject.user_code.should eq(user.code)
  end

  describe ":log" do
    before do
      LogRequest.clear_log!
      LogRequest.log_request(user.code, Time.now, Time.now, "Now")
      LogRequest.log_request(user.code, Time.now, Time.now, "Now")
    end
    it "should be an array-like thing" do
      LogRequest.log.count.should eq(2)
    end
    it "should request LogRequest" do
      LogRequest.log.first.should be_a(LogRequest)
    end

    it "can clear out the log" do
      LogRequest.clear_log!
      LogRequest.log.should be_empty
    end

  end
end

describe User do

  let(:user1) {User.new}
  let(:user2) {User.new}

  before do
    LogRequest.clear_log!
  end

  it 'should have a unique code' do
    user1.code.should eq(1)
    user2.code.should eq(2)
  end
end
