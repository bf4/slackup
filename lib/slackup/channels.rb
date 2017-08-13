class Slackup::Channels < Slackup

  def list
    @list ||= Slack.channels_list["channels"]
  end
  alias channels list

  def write!
    channels.each do |channel|
      write_messages(channel)
    end
  end

  def messages(channel)
    Slack.channels_history(channel: channel["id"], count: "1000")
  end

  def write_messages(channel)
    with_messages channel["name_normalized"], messages(channel) do |messages|
      File.open(backup_filename(channel["name"]), "w")  do |f|
        formatted_messages = format_messages(messages)
        f.write serialize(formatted_messages)
      end
    end
  end
end
