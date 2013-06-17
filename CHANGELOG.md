# Changelog

## 1.4.2

- Fixed incorrect pushing of a tag called 'master' to heroku on first deploy.
- Small README change regarding migrations

## 1.4.1

- Fix for migrations always being skipped

## 1.4.0

- Skip migrations if no changes have been made to `db/migrate`
- Removed #repo_host and #repo_name options from `Paratrooper::Deploy`
