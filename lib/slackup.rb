#!/usr/bin/ruby

require "pathname"
require "yaml"
require "fileutils"
gem "slack-api", "~> 1.1", ">= 1.1.3"
require "slack"
require_relative 'slackup/channels'
require_relative 'slackup/groups'

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
          write_stars
          write_users
          Dir.chdir(ims_dir) do
            im_list.each do |im|
              write_im_messages(im)
            end
          end
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

  Im = Struct.new(:im_hash) do
    def id; im_hash["id"]; end

    def user; im_hash["user"]; end
  end
  # @return [Hash]
  # @example
  # {
  #   "ok"=>true,
  #   "ims"=>[
  #     {"id"=>"D1234567890", "is_im"=>true, "user"=>"USLACKBOT", "created"=>1372105335, "is_user_deleted"=>false},
  #   ]
  # }
  def im_list
    @im_list ||= Slack.im_list["ims"].map { |im| Im.new(im) }
  end

  # @param im_id [String] is the 'channel' of the im, e.g. "D1234567890"
  # @return [Hash]
  # @example return
  # {
  #   "ok": true,
  #   "latest": "1358547726.000003",
  #   "messages": [
  #     {
  #       "type": "message",
  #       "ts": "1358546515.000008",
  #       "user": "U2147483896",
  #       "text": "<@U0453RHGQ> has some thoughts on that kind of stuff"
  #     },
  #     ]
  #   "has_more": false
  def im_history(im_id)
    Slack.im_history(channel: im_id)
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

  alias_method :format_im_messages, :format_messages

  # gets user name for an id, if mapping is known, else returns the input
  def user_name(user_id)
    @user_names ||= users.each_with_object({}) {|user, lookup|
      lookup[user.id] = user.name
    }
    @user_names.fetch(user_id) {
      user_id
    }
  end

  def write_stars
    File.open(backup_filename("stars"), "w")  do |f|
      stars = Slack.stars_list(count: "1000", page: "1")
      f.write(serialize(stars))
    end
  end

  def write_users
    File.open(backup_filename("users"), "w")  do |f|
      f.write(serialize(users.map(&:to_hash)))
    end
  end

  def serialize(obj)
    obj.to_yaml
  end

  def write_im_messages(im)
    im_username = user_name(im.user).downcase.gsub(/\s+/, "-")
    with_messages im_username, im_history(im.id) do |messages|
      formatted_messages = format_im_messages(messages)
      File.open(backup_filename(im_username), "w")  do |f|
        f.write serialize(formatted_messages)
      end unless formatted_messages.empty?
    end
  end

  def ims_dir
    @ims_dir ||= "ims"
    FileUtils.mkdir_p(@ims_dir)
    @ims_dir
  end

  def backup_filename(name)
    "#{name}.yml"
  end
end

if $0 == __FILE__
  Slackup.backup
end
