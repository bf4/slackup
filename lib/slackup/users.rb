class Slackup::Users < Slackup
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
  def list
    @list ||= client.users_list["members"].map { |member| User.new(member) }
  end
  alias users list

  def write!
    File.open(backup_filename("users"), "w")  do |f|
      f.write(serialize(users.map(&:to_hash)))
    end
  end

  # gets user name for an id, if mapping is known, else returns the input
  def user_name(user_id)
    @user_names ||= users.each_with_object({}) {|user, lookup|
      lookup[user.id] = user.name
    }
    @user_names.fetch(user_id) {
      user_id
    }
  end
end
