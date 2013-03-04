Ploy: faster than deploy
========================

As a PaaS provider we don't have the issues that Chef server deals with:
we don't need to handle heterogenous environments. We can take shortcuts
and adapt our application code to adjust to a single and opinionated
environment.

We want simple deploys, as simple as Heroku. But we don't want to loose
the power of developer-initiated command tools like Capistrano.

We don't want to depend (whenever possible) on external sources during
deploy. Things are all bundled in a single package before deploy.

We want to separate platform concerns from the application concerns.

We want to avoid remote ruby dependencies.

We run ruby 1.9.3+ locally.

Platform specifics
------------------

Application code is deployed in /mnt/app

We standardise on a single target OS: Ubuntu Precise 64

All hosts have a statsd daemon available.

Interfaces
----------

`script/slugify CACHE_DIR TARGET_DIR`: A project needs to have this script
to produce a slug.

`script/install CONFIG_PATH`: A slug needs to contain this
executable after unpacking to prepare the system.

`script/post-install`: A slug MAY have this script to run after a deploy
for example to restart processes.

Commands
--------

`ploy init`: Setups your project for ploy

`ploy setup`: Initializes a target

`ploy deploy [target]`: ???

`ploy teardown`: Removes all associated resources from a target (unless
it's production)


Configuration
-------------

  asset store

  roles

  targets


