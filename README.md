## Paratrooper

[![Gem Version](https://badge.fury.io/rb/paratrooper.png)](http://badge.fury.io/rb/paratrooper)
[![Build Status](https://travis-ci.org/mattpolito/paratrooper.png?branch=master)](https://travis-ci.org/mattpolito/paratrooper)
[![Code Climate](https://codeclimate.com/github/mattpolito/paratrooper.png)](https://codeclimate.com/github/mattpolito/paratrooper)

Make your complex deploy to [Heroku][] easy. This library affords you the ability to make a quick and concise deployment rake task.

## Installation

Add this line to your application's Gemfile:

    gem 'paratrooper'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install paratrooper

## Usage

Instantiate Paratrooper with the name of your heroku application

```ruby
Paratrooper::Deploy.new('amazing-app')
```

also you can provide a tag name for repository use

```ruby
Paratrooper::Deploy.new('amazing-app', tag: 'staging')
```

Then there are methods available to perform common tasks like creating git tags, running migrations, and warming your application instance.

## Authentication

Authentication with your Heroku account can happen in a few different ways

* Providing API Key

```ruby
Paratrooper::Deploy.new('app', api_key: 'API_KEY')
```

* Via environment variable

```ruby
ENV['HEROKU_API_KEY'] = 'API_KEY'
Paratrooper::Deploy.new('app')
```

* Local file storage
  This method works via a local Netrc file. Storage of this key is handled via the [Heroku Toolbelt][]. This is the default and preferred method of providing your authentication key.

```ruby
Paratrooper::Deploy.new('app')
```

## Tag Management

By providing tag options into Paratrooper, your code can be tagged and deployed from different reference points.

### Staging example
```ruby
  Paratrooper::Deploy.new("staging-app",
    tag: 'staging'
  )
```
This will create/update a `staging` git tag at `HEAD`

### Production example
```ruby
  Paratrooper::Deploy.new("amazing-production-app",
    tag: 'production'
    match_tag_to: 'staging'
  )
```
This will create/update a `production` git tag at `staging` and deploys the `production` tag

## Sensible Default Deployment

You can use the objects methods any way you'd like but we've provided a sensible default at `Paratrooper#deploy`

This will perform the following tasks:

* Activating maintenance mode
* Create or update a git tag (if provided)
* Push changes to Heroku
* Run database migrations
* Restart the application
* Deactivate maintenance mode
* Warm application instance

### Example Usage
```ruby
require 'paratrooper'

namespace :deploy do
  desc 'Deploy app in staging environment'
  task :staging do
    deployment = Paratrooper::Deploy.new("amazing-staging-app",
      tag: 'staging'
    )

    deployment.deploy
  end

  desc 'Deploy app in production environment'
  task :production do
    Paratrooper::Deploy.new("amazing-production-app",
      tag: 'production'
      match_tag_to: 'staging'
    )

    deployment.deploy
  end
end
```

## Bucking the Norm

Our default deploy gets us most of the way but maybe it's not for you. We've got you covered. Once you've instantated Paratrooper, you have access to all of the included methods as well as any arbitrary code that needs to be run.

Say you want to let [New Relic][] know that you are deploying. That way your heartbeat notifications will not make you crazy with false downtime.

### Example Usage
```ruby
require 'paratrooper'

namespace :deploy do
  desc 'Deploy app in production environment'
  task :production do
    Paratrooper::Deploy.new("amazing-production-app",
      tag: 'production'
      match_tag_to: 'staging'
    )

    %x[curl https://heroku.newrelic.com/accounts/ACCOUNT_ID/applications/APPLICATION_ID/ping_targets/disable -X POST -H "X-Api-Key: API_KEY"]

    deployment.activate_maintenance_mode
    deployment.update_repo_tag
    deployment.push_repo
    deployment.run_migrations
    deployment.app_restart
    deployment.deactivate_maintenance_mode
    deployment.warm_instance

    %x[curl https://heroku.newrelic.com/accounts/ACCOUNT_ID/applications/APPLICATION_ID/ping_targets/enable -X POST -H "X-Api-Key: API_KEY"]
  end
end
```

## Nice to haves

* send [New Relic][] a notification to toggle heartbeat during deploy

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

[Heroku]: http://heroku.com
[Heroku Toolbelt]: http://toolbelt.heroku.com
[New Relic]: http://newrelic.com
