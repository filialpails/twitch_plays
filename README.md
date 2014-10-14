twitch_plays
============

Yet another Twitch Plays Pokemon clone. MMO-ify any game over IRC.

Prerequisites
-------------

Requires xdotool on Linux and OSX.


Configuration
-------------

See config.yml for an example of a configuration file.

Running
-------

IRC log will be interspersed with the player commands, unless stderr is redirected.

sh:
```Shell
$ twitch_plays --config-file FILE 2> /dev/null
```
cmd.exe:
```Batchfile
twitch_plays --config-file FILE 2> nul
```
Powershell:
```PowerShell
twitch_plays --config-file FILE 2> $null
```
