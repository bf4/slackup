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
    @list ||= Slack.groups_list["groups"]
  end
  alias groups list

  def write!
    Dir.chdir(groups_dir) do
      groups.each do |group|
        write_messages(group)
      end
    end
  end

  def messages(group)
    Slack.groups_history(channel: group["id"], count: "1000")
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
