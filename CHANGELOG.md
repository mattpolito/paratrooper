# Changelog

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
