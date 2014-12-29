# Changelog

## 3.0.0.beta.1

- Moved all state into configuration object
- Updated interface to start a deploy Ex: `Paratrooper.deploy('appname')`
- If any exception is thrown, the deploy process is aborted
- Stop deploy process if there is no access to Heroku

## 2.4.1

- Fix `Deploy#app_url` for wildcard domains

## 2.4.0

- Maintenance mode only runs around migrations now
- README updates around `maintenance_mode=`

## 2.3.0

- Http calls no longer being made from system cURL

## 2.2.0

- Allow deploy from specific branch

## 2.1.0

- Run remote tasks on your application

## 2.0.0

- Updated README with callback output

## 2.0.0.beta2

- Added license.txt
- Maintenance mode triggered only when migrations are needed
- Throw exception if no netrc file is available
- Callbacks can now output screen notifications

## 2.0.0.beta1

- Callbacks are fired around deployment methods for an easy way to hook into
  the deploy process
- Ruby 1.9.2+ is required
- Added 'MIT' license to gem
- Options can now be set by options passed into contstructor or block syntax
- `match_tag_to` option has been changed to `match_tag`
- Disabling the use of maintenance mode as an option

## 1.4.2

- Fixed incorrect pushing of a tag called 'master' to heroku on first deploy
- Small README change regarding migrations

## 1.4.1

- Fix for migrations always being skipped

## 1.4.0

- Skip migrations if no changes have been made to `db/migrate`
- Removed #repo_host and #repo_name options from `Paratrooper::Deploy`
