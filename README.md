# Capistrano Rainbows

Capistrano plugin that integrates Rainbows tasks into capistrano deployment script.

## Installation

Install library from rubygems:

```
gem install capistrano-rainbows
```

## Usage

### Setup

Add the library to your `Gemfile`:

```ruby
group :development do
  gem 'capistrano-rainbows', require: false
end
```

And load it into your deployment script `config/deploy.rb`:

```ruby
require 'capistrano-rainbows'
```

Add rainbows restart task hook:

```ruby
after 'deploy:restart', 'rainbows:reload' # app IS NOT preloaded
after 'deploy:restart', 'rainbows:restart'  # app preloaded
```

Create a new configuration file `config/rainbows/rainbows.rb` or `config/rainbows/STAGE.rb`, where stage is your deployment environment.

Example config - [examples/rails3.rb](https://github.com/sosedoff/capistrano-rainbows/blob/master/examples/rails3.rb). Please refer to rainbows documentation for more examples and configuration options.

### Test

First, make sure you're running the latest release:

```
cap deploy
```

Then you can test each individual task:

```
cap rainbows:start
cap rainbows:stop
cap rainbows:reload
```

## Configuration

You can modify any of the following options in your `deploy.rb` config.

- `rainbows_env`             - Set rainbows environment. Default to `rails_env` variable.
- `rainbows_pid`             - Set rainbows PID file path. Default to `current_path/tmp/pids/rainbows.pid`
- `rainbows_bin`             - Set rainbows executable file. Default to `rainbows`.
- `rainbows_bundle`          - Set bundler command for rainbows. Default to `bundle`.
- `rainbows_user`            - Launch rainbows master as the specified user. Default to `user` variable.
- `rainbows_roles`           - Define which roles to perform rainbows recpies on. Default to `:app`.
- `rainbows_config_path`     - Set the directory where rainbows config files reside. Default to `current_path/config`.
- `rainbows_config_filename` - Set the filename of the rainbows config file. Not used in multistage installations. Default to `rainbows.rb`.

## Available Tasks

To get a list of all capistrano tasks, run `cap -T`:

```
cap rainbows:add_worker                # Add a new worker
cap rainbows:remove_worker             # Remove amount of workers
cap rainbows:reload                    # Reload rainbows
cap rainbows:restart                   # Restart rainbows
cap rainbows:shutdown                  # Immediately shutdown rainbows
cap rainbows:start                     # Start rainbows master process
cap rainbows:stop                      # Stop rainbows
```

## License

See LICENSE file for details.
