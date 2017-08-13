#!/usr/bin/ruby

require "pathname"
require "yaml"
require "fileutils"
gem "slack-api", "~> 1.6", ">= 1.6.0"
require "slack"
require_relative 'slackup/users'
require_relative 'slackup/channels'
require_relative 'slackup/groups'
require_relative 'slackup/ims'
require_relative 'slackup/stars'

class Slackup
  Error = Class.new(StandardError)
  RUN_ROOT  = Pathname Dir.pwd
  def self.run_root
    RUN_ROOT
  end

  SEMAPHORE = Mutex.new
  attr_reader :name
  alias dirname name
  def initialize(name, token)
    @name = name
    @token = token
    FileUtils.mkdir_p(name)
  end

  def self.team_token_pairs_file
    Pathname.glob(run_root.join("slack_teams.{json,yml,yaml}")).first
  end

  def self.team_token_pairs
    if team_token_pairs_file.readable?
      YAML.load(team_token_pairs_file.read)
    else
      fail Error, "No team token pairs file found. See README for instructions."
    end
  end

  def self.backup(team_token_pairs = team_token_pairs())
    team_token_pairs.each do |name, token|
      new(name, token).execute
    end
  end

  def execute
    SEMAPHORE.synchronize do
      authorize! && write!
    end
  end

  def write!
    Dir.chdir(dirname) do
      Channels.new(name, @token).write!
      Groups.new(name, @token).write!
      Stars.new(name, @token).write!
      user_client.write!
      Ims.new(name, @token).write!
    end
  end

  private

  def authorize!
    Slack.configure do |config|
      config.token = @token
    end
    auth_test = Slack.auth_test
    if auth_test["ok"] === true
      p [name]
      true
    else
      p [name, auth_test]
      false
    end
  end


  # {"ok"=>false, "error"=>"ratelimited"}
  # {"ok"=>false, "error"=>"token_revoked"
  def with_messages(name, query_result)
    if query_result["ok"]
      yield query_result["messages"]
    else
      error = query_result["error"]
      $stderr.puts "#{name}, error: #{error}"
      exit 1 if error =~ /ratelimited/
    end
  end

  def format_messages(messages)
    if messages.nil?
      $stderr.puts "Messages nil #{caller[0..1]}"
      return []
    end
    messages.reverse.map { |msg|
      if msg.has_key?("text") && msg.has_key?("user")
        msg["user"] = user_name(msg["user"])
        msg["text"].gsub!(/<@(?<userid>U[A-Z0-9]+)>/) {
          userid = $~[:userid] # MatchData
          "<@#{user_name(userid)}>"
        }
        msg
      else
        nil
      end
    }.compact
  end

  def user_client
    @user_client ||= Users.new(name, @token)
  end

  def users
    user_client.users
  end

  def user_name(user_id)
    user_client.user_name(user_id)
  end

  def serialize(obj)
    obj.to_yaml
  end

  def backup_filename(name)
    "#{name}.yml"
  end
end

if $0 == __FILE__
  Slackup.backup
end
