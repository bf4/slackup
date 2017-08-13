class Slackup::Stars < Slackup

  def list
    Slack.stars_list(count: "1000", page: "1")
  end
  alias stars list

  def write!
    with_messages "stars", list do |messages|
      File.open(backup_filename("stars"), "w")  do |f|
        f.write(serialize(messages))
      end
    end
  end
end
