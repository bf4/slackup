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

  # {
  #   "ok": true,
  #   "items": [
  #     {
  #       "type": "message",
  #       "channel": "XXXXXXXXX",
  #       "message": { ... }
  #       "date_create": "1511982656"
  #     },
  #     {
  #       "type": "file",
  #       "file": {
  #         ....
  #         "channels": [ "XXXXXXXXX" ],
  #         "groups": [ ],
  #         "ims": [ ],
  #         "comments_count": 0, "num_stars": 1, "is_starred": true
  #       },
  #       "date_create": "1511373913"
  #     }
  #   ],
  #   "paging": { "per_page": 1000, "spill": 0, "page": 1, "total": 25, "pages": 1 }
  # }
  def write!
    return unless write_stars?
    with_messages "stars", list, key: "items" do |messages|
      File.open(backup_filename("stars"), "w")  do |f|
        f.write(serialize(messages))
      end
    end
  end
end
