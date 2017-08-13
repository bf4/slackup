class Slackup::Ims < Slackup
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
  def list
    @list ||= client.im_list["ims"].map { |im| Im.new(im) }
  end
  alias ims list

  def write_ims?
    if config.fetch("ims", true)
      p [name, :ims, "Writing"]
      true
    else
      p [name, :ims, "Skipping"]
      false
    end
  end

  def write!
    return unless write_ims?
    Dir.chdir(ims_dir) do
      ims.each do |im|
        # p [:ims, im.user, format_username(im.user)]
        write_messages(im)
      end
    end
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
  def messages(im_id)
    client.im_history(channel: im_id)
  end

  def write_messages(im)
    im_username = format_username(im.user)
    with_messages im_username, messages(im.id) do |messages|
      formatted_messages = format_messages(messages)
      File.open(backup_filename(im_username), "w")  do |f|
        f.write serialize(formatted_messages)
      end unless formatted_messages.empty?
    end
  end

  def format_username(user)
    user_name(user).downcase.gsub(/\s+/, "-")
  end

  def ims_dir
    @ims_dir ||= "ims"
    FileUtils.mkdir_p(@ims_dir)
    @ims_dir
  end
end
