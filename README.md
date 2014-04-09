twitch_plays
============

Yet another Twitch Plays Pokemon clone. MMO-ify any game over IRC.

Prerequisites
-------------

Requires xdotool on Linux.


Configuration
-------------

See config.yml for an example of a configuration file.

Running
-------

Run it as...
```sh
$ twitch_plays --config-file FILE 2> irc.log
```
...to pipe the IRC log to a file, otherwise it will be interspersed with the player commands.
