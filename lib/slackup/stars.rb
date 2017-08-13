class Slackup::Stars < Slackup

  def list
    client.stars_list(count: "1000", page: "1")
  end
  alias stars list

  def write_stars?
    if config.fetch("stars", true)
      p [name, :stars, "Writing"]
      true
    else
      p [name, :stars, "Skipping"]
      false
    end
  end

  def write!
    return unless write_stars?
    with_messages "stars", list do |messages|
      File.open(backup_filename("stars"), "w")  do |f|
        f.write(serialize(messages))
      end
    end
  end
end
