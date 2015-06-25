# slackup
backup my slacks

## Installation

`gem install slackup`

## Usage

1. Get token for each team from https://api.slack.com/web

2. Configure a file in the backup directory called `slack_teams.yml`,
though `slack_teams.yaml` and `slack_teams.json` will also work.

The config file must contain a dictionary (hash) of 
team names (backup directories) and associated tokens.

e.g.

slack_teams.yml

```yaml
---
some-team: xxxp-some-token
another-team: xxxp-different-token
```

slack_teams.json

```json
{
  "some-team": "xxxp-some-token",
  "another-team": "xxxp-different-token"
}
```

3. Run `slackup` in your terminal

Each key/value team pair will be run in a local directory named by the key
using only the token for auth. Thus, the key (team) name can be whatever you want.

## Development

This gem is does the bare basics of backup and works for me.

It has no tests.

It depends on the ['slack-api' gem](https://github.com/aki017/slack-ruby-gem)

I run it periodically via `bash update.bash`

```bash
#!/usr/bin/env bash -l
bundle check || bundle --quiet
git commit -am "Update before update.bash"
bundle exec slackup &&
  git commit -am "Update via update.bash" &&
    git add . && git commit -am "Add new via update.bash"
```

## Contributing

1. Fork it ( https://github.com/[my-github-username]/slackup/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

MIT License
