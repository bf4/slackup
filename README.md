# slackup
backup my slacks

## Installation

`gem install slackup`

## Usage

1. Get token for each team from https://api.slack.com/web

2. Configure a file in the backup directory called `slack_teams.yml`,
though `slack_teams.yaml` and `slack_teams.json` will also work.

The config file must contain an array (list) of team configurations,
where each team config is a dictionary (hash) as below:

| config | description |
|--------|-------|
| name (required) | the team name. e.g. `some-team` in `some-team.slackup.com`. Is used as backup directory name for the team.
| nickname (optional) | a nickname. When present, overrides `name` as the backup directory name for the team.
| token (required) | https://api.slack.com/custom-integrations/legacy-tokens
| channels (optional) | array of whitelisted channels to include. Default is to include all
| groups (optional) | array of whitelisted groups to include. Default is to include all
| users (optional) | boolean whether to write out users
| stars (optional) | boolean whether to write out stars
| ims (optional) | boolean whether to write out ims

e.g.

slack_teams.yml

```yaml
---
- name: some-team
  token: xxxp-some-token
- name: another-team
  nickname: ateam
  token: xxxp-different-token
  channels:
    - general
    # - random
  groups:
    - core-maintainers
  users: true
  stars: false
  ims: true
```

slack_teams.json

```json
[
  {
    "name": "some-time",
    "token": "xxxp-some-token"
  },
  {
    "name": "another-team",
    "nickname": "ateam",
    "token": "xxxp-different-token"
  }
]
```

3. Run `slackup` in your terminal

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
