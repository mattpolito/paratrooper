![Paratrooper](http://f.cl.ly/items/0Z1v1P1l1B1h1k1l2q0E/paratrooper_header.png)

[![Gem Version](https://badge.fury.io/rb/paratrooper.png)](http://badge.fury.io/rb/paratrooper)
[![Build Status](https://travis-ci.org/mattpolito/paratrooper.png?branch=master)](https://travis-ci.org/mattpolito/paratrooper)
[![Code Climate](https://codeclimate.com/github/mattpolito/paratrooper.png)](https://codeclimate.com/github/mattpolito/paratrooper)

Simplify your [Heroku][] deploy with quick and concise deployment rake tasks.

## Installation

Add this line to your application's Gemfile:

```shell
  gem 'paratrooper'
```

and then execute

```shell
  bundle
```

or

install it yourself with

```shell
  gem install paratrooper
```

## Usage

Instantiate Paratrooper with the name of your heroku application.

```ruby
Paratrooper::Deploy.new('amazing-app')
```

You can also provide a tag:

```ruby
Paratrooper::Deploy.new('amazing-app', tag: 'staging')
```

or alternatively:

```ruby
Paratrooper::Deploy.new('amazing-app') do |deploy|
  deploy.tag = 'staging'
end
```

## Authentication

You can authenticate your Heroku account in a few ways:

* Provide an API Key

```ruby
Paratrooper::Deploy.new('app', api_key: 'API_KEY')
```

* Set an environment variable

```ruby
ENV['HEROKU_API_KEY'] = 'API_KEY'
Paratrooper::Deploy.new('app')
```

* Local Netrc file

```ruby
Paratrooper::Deploy.new('app')
```

This method works via a local Netrc file handled via the [Heroku Toolbelt][] and is the default and preferred method for providing authentication keys.

## Git SSH key configuration

If you use multiple SSH keys for managing multiple accounts, for example in your `.ssh/config`, you can set the `deployment_host` option:

```ruby
Paratrooper::Deploy.new('app', deployment_host: 'HOST')
```

or alternatively:

```ruby
Paratrooper::Deploy.new('amazing-app') do |deploy|
  deploy.deployment_host = 'HOST'
end
```

This also works if you're using the [heroku-accounts](https://github.com/ddollar/heroku-accounts) plugin:

```ruby
Paratrooper::Deploy.new('app', deployment_host: 'heroku.ACCOUNT_NAME')
```

## Tag Management

By providing tag options for Paratrooper, your code can be tagged and deployed from various reference points.

### Staging example
```ruby
  Paratrooper::Deploy.new("staging-app", tag: 'staging')
```
This will create/update a `staging` git tag at `HEAD`.

### Production example
```ruby
  Paratrooper::Deploy.new("amazing-production-app",
    tag: 'production',
    match_tag: 'staging'
  )
```

or alternatively:

```ruby
Paratrooper::Deploy.new('amazing-production-app') do |deploy|
  deploy.tag       = 'production'
  deploy.match_tag = 'staging'
end
```
This will create/update a `production` git tag at `staging` and deploy the `production` tag.

## Sensible Default Deployment

You can use the object's methods any way you'd like, but we've provided a sensible default at `Paratrooper#deploy`.

This will perform the following tasks:

* Activate maintenance mode
* Create or update a git tag (if provided)
* Push changes to Heroku
* Run database migrations if any have been added to db/migrate
* Restart the application
* Deactivate maintenance mode
* Warm application instance

### Example Usage

```ruby
require 'paratrooper'

namespace :deploy do
  desc 'Deploy app in staging environment'
  task :staging do
    deployment = Paratrooper::Deploy.new("amazing-staging-app", tag: 'staging')

    deployment.deploy
  end

  desc 'Deploy app in production environment'
  task :production do
    deployment = Paratrooper::Deploy.new("amazing-production-app") do |deploy|
      deploy.tag              = 'production'
      deploy.match_tag        = 'staging'
    end

    deployment.deploy
  end
end
```

## Bucking the Norm

Our default deploy gets us most of the way, but maybe it's not for you--we've
got you covered. Every deployment method has a set of callback instructions that can be
utilized in almost any way you can imagine.

The `add_callback` method allows for the execution of arbitrary code within different steps of the deploy process.

There are 'before' and 'after' hooks for each of the following:

* setup
* activate_maintenance_mode
* update_repo_tag
* push_repo
* run_migrations
* app_restart
* deactivate_maintenance_mode
* warm_instance
* teardown

### Example Usage

For example, say you want to let [New Relic][] know that you are deploying and
to disable your application monitoring.

```ruby
# lib/tasks/deploy.rake

namespace :deploy do
  desc 'Deploy app in production environment'
  task :production do
    deployment = Paratrooper::Deploy.new("amazing-production-app") do |deploy|
      deploy.tag = 'production'
      deploy.match_tag = 'staging'
      deploy.add_callback(:before_setup) do |output|
        output.display("Totally going to turn off newrelic")
        system %Q[curl https://rpm.newrelic.com/accounts/ACCOUNT_ID/applications/APPLICATION_ID/ping_targets/disable -X POST -H "X-Api-Key: API_KEY"]
      end
      deploy.add_callback(:after_teardown) do |output|
        system %Q[curl https://rpm.newrelic.com/accounts/ACCOUNT_ID/applications/APPLICATION_ID/ping_targets/enable -X POST -H "X-Api-Key: API_KEY"]
        output.display("Aaaannnd we're back")
      end
    end

    deployment.deploy
  end
end
```

Or maybe you just want to run a rake task on your application

```ruby
# lib/tasks/deploy.rake

namespace :deploy do
  desc 'Deploy app in production environment'
  task :production do
    deployment = Paratrooper::Deploy.new("amazing-production-app") do |deploy|
      deploy.add_callback(:after_teardown) do |output|
        output.display("Running some task that needs to run")
        deploy.add_remote_task("rake some:task:to:run")
      end
    end

    deployment.deploy
  end
end
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`).
3. Commit your changes (`git commit -am 'Add some feature'`).
4. Push to the branch (`git push origin my-new-feature`).
5. Create new Pull Request.

## Thanks

* [Rye Mason][] for the fantastic heading image.

[Heroku]: http://heroku.com
[Heroku Toolbelt]: http://toolbelt.heroku.com
[New Relic]: http://newrelic.com
[Rye Mason]: https://github.com/ryenotbread
[`Paratrooper::Notifier`]: https://github.com/mattpolito/paratrooper/blob/master/lib/paratrooper/notifier.rb
