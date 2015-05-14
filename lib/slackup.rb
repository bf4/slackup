#!/usr/bin/ruby

require "pathname"
require "yaml"
require "fileutils"
gem "slack-api", "= 1.1.3"
require "slack"

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
        channels.each do |channel|
          write_channel_messages(channel)
        end
        write_stars
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

  def users
    @users ||= Slack.users_list["members"]
  end

  def channels
    @channels ||= Slack.channels_list["channels"]
  end

  def write_channel_messages(channel)
    messages = Slack.channels_history({channel: channel["id"], count: "1000"})["messages"]
    File.open(backup_filename(channel['name']),"w")  do |f|
      f.write format_channel_messages(messages)
    end
  end

  def format_channel_messages(messages)
    messages.reverse.map { |msg|
      if (msg.has_key?("text") && msg.has_key?("user"))
        users.each do |user|
          if user["id"] == msg["user"]
            break msg["user"] = user["name"]
          end
        end
        msg
      else
        nil
      end
    }.compact.to_yaml
  end

  def write_stars
    File.open(backup_filename("stars"),"w")  do |f|
      stars = Slack.stars_list(count: "1000", page: "1")
      f.write(format_stars(stars))
    end
  end

  def format_stars(stars)
    stars.to_yaml
  end

  def backup_filename(name)
    "#{name}.yml"
  end
end

if $0 == __FILE__
  Slackup.backup
end
