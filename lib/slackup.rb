#!/usr/bin/ruby

require "pathname"
require "yaml"
require "fileutils"
gem "slack-api", "~> 1.1", ">= 1.1.3"
require "slack"
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
      authorize! &&
        Dir.chdir(name) do
          Channels.new(name, @token).write!
          Groups.new(name, @token).write!
          Stars.new(name, @token).write!
          write_users
          Ims.new(name, @token).write!
        end
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

  User = Struct.new(:user_hash) do
    def id; user_hash["id"]; end

    def name; user_hash["name"]; end

    def deleted; user_hash["deleted"]; end

    def color; user_hash["color"]; end

    def profile; user_hash["profile"]; end

    def admin?; user_hash["is_admin"]; end

    def owner?; user_hash["is_owner"]; end

    def has_2fa?; user_hash["has_2fa"]; end

    def has_files?; user_hash["has_files"]; end

    def to_hash; user_hash; end
  end
  # {
  #   "ok": true,
  #   "members": [
  #     {
  #       "id": "U023BECGF",
  #       "name": "bobby",
  #       "deleted": false,
  #       "color": "9f69e7",
  #       "profile": {
  #         "first_name": "Bobby",
  #         "last_name": "Tables",
  #         "real_name": "Bobby Tables",
  #         "email": "bobby@slack.com",
  #         "skype": "my-skype-name",
  #         "phone": "+1 (123) 456 7890",
  #         "image_24": "https:\/\/...",
  #         "image_32": "https:\/\/...",
  #         "image_48": "https:\/\/...",
  #         "image_72": "https:\/\/...",
  #         "image_192": "https:\/\/..."
  #       },
  #       "is_admin": true,
  #       "is_owner": true,
  #       "has_2fa": false,
  #       "has_files": true
  #     },
  #   ]
  # }
  def users
    @users ||= Slack.users_list["members"].map { |member| User.new(member) }
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

  # gets user name for an id, if mapping is known, else returns the input
  def user_name(user_id)
    @user_names ||= users.each_with_object({}) {|user, lookup|
      lookup[user.id] = user.name
    }
    @user_names.fetch(user_id) {
      user_id
    }
  end

  def write_users
    File.open(backup_filename("users"), "w")  do |f|
      f.write(serialize(users.map(&:to_hash)))
    end
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
