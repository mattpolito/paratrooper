# Paratrooper

Library for handling common tasks when deploying to [Heroku](http://heroku.com)

[![Build Status](https://travis-ci.org/mattpolito/paratrooper.png?branch=master)](https://travis-ci.org/mattpolito/paratrooper)

## Installation

Add this line to your application's Gemfile:

    gem 'paratrooper'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install paratrooper

## Usage

>> Note: Before getting started, ensure that `ENV['HEROKU_API_KEY']` is set. If you do not know your api key, you can `cat ~/.netrc`. Your api key will be listed as password in that file. This is necessary until reading your crendentials out of the `.netrc` file is implemented.

Instantiate Paratrooper with the name of your heroku application

```ruby
Paratrooper::Deploy.new('amazing-app')
```

also you can provide a tag name for repository use

```ruby
Paratrooper::Deploy.new('amazing-app', tag: 'staging')
```

Then there are methods available to perform common tasks like creating git tags, running migrations, and warming your application instance.

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

## Example Usage

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
    deployment = Paratrooper::Deploy.new("amazing-production-app", tag: 'production')

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
