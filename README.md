WireRoom
===========


Requirement
-----------

- node.js
- redis
- mongodb
- coffee-script

Features
--------

* Notification Center
  * Jenkins Notification
  * GitHub PostReceive
  * Git Commit Notification (for private git repository)
  * Travis-ci Notification

Supported Browsers
------------------
* iOS6 (iPad or iPhone)
* Safari
* Google Chrome
* FireFox

Installation
------------

    npm install


Run
---

    coffee app.coffee

Setting Up Hooks
----------------

### GitHub

Add the post-receive hook:

    http://wireroom.extremedev.org/=/github/:channel

The `:channel` could be `Hall` or the channel name you want.


### Jenkins

Install the Jenkins Notification plugin and setup the endpoint at

    http://wireroom.extremedev.org/=/jenkins/:channel

### Travis-CI

Setup the notification in your `.travis-ci.yml` config file:

    notifications:
      webbooks: http://wireroom.extremedev.org/=/travis-ci/:channel


### License

MIT License

