Ploy: faster than deploy
========================

We don't want to loose the power of developer-initiated deploys (eg:
Capistrano).

We don't want to depent (whenever possible) on external sources during
deploy. Things are all bundled in a single package before deploy.

We want to separate platform concerns from the application concerns.

Deploying an application should be as simple as Heroku.

We standardise on a single target OS.

Interfaces
----------

`script/slugify CACHE_DIR TARGET_DIR`: A project needs to have this script
to produce a slug.

`script/install SLUG_URL CONFIG_URL`: A slug needs to contain this
executable after unpacking to prepare the system.

`script/post-install`: A slug MAY have this script to run after a deploy
for example to restart processes.

Commands
--------

`ploy init`: Setups your project for ploy

`ploy setup`: Initializes a target

`ploy build`: Creates a slug from your project

`ploy deploy [target]`: ???

`ploy teardown`: Removes all associated resources from a target (unless
it's production)


Configuration
-------------

  asset store

  roles

  targets


