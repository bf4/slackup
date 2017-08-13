class Slackup::Channels < Slackup

  def list
    @list ||= client.channels_list["channels"]
  end
  alias channels list

  def configured_channels
    @configured_channels ||= config.fetch("channels", [])
  end

  def write_channel?(channel)
    whitelisted_channel = channel["name"] if configured_channels.empty?
    whitelisted_channel ||= configured_channels.find do |channel_name|
      channel["name_normalized"] == channel_name or
        channel["name"] == channel_name
    end
    if whitelisted_channel
      p [name, :channels, "Writing #{whitelisted_channel}"]
      true
    else
      p [name, :channels, "Skipping #{channel["name"]}"]
      false
    end
  end

  def write!
    channels.each do |channel|
      next unless write_channel?(channel)
      write_messages(channel)
    end
  end

  def messages(channel)
    client.channels_history(channel: channel["id"], count: "1000")
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
