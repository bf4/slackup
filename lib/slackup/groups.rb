class Slackup::Groups < Slackup

  # {
  #     "ok": true,
  #     "groups": [
  #         {
  #             "id": "G0ABC",
  #             "name": "some-group",
  #             "is_group": true,
  #             "created": 1436923155,
  #             "creator": "UABC",
  #             "is_archived": false,
  #             "members": [
  #             ],
  #             "topic": {
  #                 "value": "",
  #                 "creator": "",
  #                 "last_set": 0
  #             },
  #             "purpose": {
  #                 "value": "Some group",
  #                 "creator": "UABC",
  #                 "last_set": 1437105751
  #             }
  #         }
  #     ]
  # }
  def list
    @list ||= client.groups_list["groups"]
  end
  alias groups list

  def configured_groups
    @configured_groups ||= config.fetch("groups", [])
  end

  def write_group?(group)
    whitelisted_group = group["name"] if configured_groups.empty?
    whitelisted_group ||= @configured_groups.find do |group_name|
      group["name"] == group_name
    end
    if whitelisted_group
      p [name, :groups, "Writing #{whitelisted_group}"]
      true
    else
      p [name, :groups, "Skipping #{group["name"]}"]
      false
    end
  end

  def write!
    Dir.chdir(groups_dir) do
      groups.each do |group|
        next unless write_group?(group)
        write_messages(group)
      end
    end
  end

  def messages(group)
    client.groups_history(channel: group["id"], count: "1000")
  end

  # https://api.slack.com/methods/groups.history
  def write_messages(group)
    with_messages group, messages(group) do |messages|
      File.open(backup_filename(group["name"]), "w")  do |f|
        formatted_messages = format_messages(messages)
        f.write serialize(formatted_messages)
      end
    end
  end

  def groups_dir
    @groups_dir ||= "groups"
    FileUtils.mkdir_p(@groups_dir)
    @groups_dir
  end

end
