# HerokuDeployment

Library for handling common tasks when deploying to [Heroku](http://heroku.com)

## Installation

Add this line to your application's Gemfile:

    gem 'heroku_deployment'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install heroku_deployment

## Usage

Instantiate HerokuDeployment with the name of your heroku application

```ruby
HerokuDeployment.new('amazing-app')
```

also you can provide a tag name for repository use

```ruby
HerokuDeployment.new('amazing-app', tag: 'staging')
```

Then there are methods available to perform common tasks like creating git tags, running migrations, and warming your application instance.

## Sensible Default Deployment

You can use the objects methods any way you'd like but we've provided a sensible default at `HerokuDeployment#deploy`

This will perform the following tasks:

* Activating maintenance mode
* Create or update a git tag (if provided)
* Push changes to Heroku
* Run database migrations
* Restart the application
* Deactivate maintenance mode
* Warm application instance

## Example Usage

```ruby
require 'heroku_deployment'

namespace :deploy do
  desc 'Deploy app in staging environment'
  task :staging do
    deployment = HerokuDeployment.new("amazing-staging-app", tag: 'staging')

    deployment.deploy
  end

  desc 'Deploy app in production environment'
  task :production do
    deployment = HerokuDeployment.new("amazing-production-app", tag: 'production')

    deployment.deploy
  end
end
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
