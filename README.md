<a href="http://www.detroitlabs.com/"><img src="https://img.shields.io/badge/Sponsor-Detroit%20Labs-000000.svg"/></a>

# CurryMUD

A Multi-User Dungeon ("MUD") server in Haskell. (If you are unfamiliar with the term "MUD," please refer to [this Wikipedia article](http://en.wikipedia.org/wiki/MUD).)

CurryMUD is the hobby project and brainchild of a single developer. It's been in active development for 4 years, but is still very much a work in progress.

## My goals

My aim is to create a unique, playable MUD. I am writing this MUD entirely in Haskell, from scratch.

Creating a framework which others can leverage to develop their own MUDs is _not_ an explicit goal of mine, nor is this a collaborative effort (I am not accepting PRs). Having said that, the code is available here on GitHub, so other parties are free to examine the code and develop their own forks. [Please refer to the license](https://github.com/jasonstolaruk/CurryMUD/blob/master/LICENSE), which is a 3-clause BSD license with additional unique clauses regarding the creation of derivative MUDs.

CurryMUD will have the following features:

* Players will be offered an immersive virtual world environment.
* Content will be created and development will proceed with the aim of supporting a small community of players.
* Role-playing will be strictly enforced.
* Classless/skill-based.
* Permadeath (when player characters die, they really die).
* Some degree of player-created content will be allowed and encouraged.
* The state of the virtual world will be highly persisted upon server shutdown.
* As is common with most MUDs, client connections will be supported with a loose implementation of the telnet protocol.
* CurryMUD will always be free to play. No pay-to-win.

## What I have so far

* About 95 player commands, 60 administrator commands, and 65 commands for debugging purposes. :1234:
* About 220 built-in emotes. :clap:
* Help files for all existing non-debug commands. Help topics. :information_desk_person:
* Commands have a consistent structure and a unique syntax for indicating target locations and quantities. :dart:
* Unique commands, accessible only when a player is in a particular room, may be created. :house_with_garden:
* Nearly everything may be abbreviated. :abc:
* Logging. :scroll:
* ANSI color. :red_circle:
* Character creation with optional readymade templates. :runner:
* The virtual world is automatically persisted at regular intervals and at shutdown. :floppy_disk:
* Commands for reporting bugs and typos. :bug:
* Commands to aid in the process of resetting a forgotten password. :passport_control:
* NPCs can execute commands, either from within code or via the ":as" administrator command. :performing_arts:
* PCs can introduce themselves to each other. :bow:
* PCs can "link" with each other so as to enable "tells." :link:
* Question channel for OOC newbie Q&A. :question:
* Players can create their own ad-hoc channels. :busts_in_silhouette:
* Free-form emotes and built-in emotes may be used in "tells" and channel communications. :clap:
* Functionality enabling one-on-one communication between players and administrators. :speech_balloon:
* Weight and encumbrance. :chart_with_downwards_trend:
* Volume and container capacity. :school_satchel:
* Vessels containing liquids. Vessels may be filled and emptied. :wine_glass:
* Light and darkness. :sun_with_face:
* Light sources (torches and oil lamps) that may be lit and extinguished. Lamps may be refueled. :lantern:
* Players can interact with permanent room fixtures that are not listed in a room's inventory. :fountain:
* Objects can be configured to automatically disappear when left on the ground for some time. :boom:
* Smell and taste. Listen. :nose::tongue::ear:
* Eating and drinking. Digestion. :bread::beer:
* Durational effects that can be paused and resumed. Corresponding feelings. :dizzy:
* PC and NPC death. Corpse decomposition. :skull:
* Corpses may be sacrificed using the holy symbol of a particular god. :pray:
* Upon death, PCs may have a limited amount of time to exist in the virtual world as spirits. :angel:
* [Maps of the game world.](https://github.com/jasonstolaruk/CurryMUD/tree/master/maps) :earth_americas:
* A history of the game world. :books:
* Gods. An origin myth describing the creation of the universe. :godmode:
* An in-game calendar. :calendar:
* Server settings are specified in a YAML file. :no_bell:
* Sending [GMCP](https://www.gammon.com.au/gmcp) `Char.Vitals` and `Info.Room`. :satellite:
* [Mudlet scripts](https://github.com/jasonstolaruk/CurryMUD/tree/master/Mudlet) for vitals gauges and mapping. :scroll:
* [A cheatsheet PDF.](https://github.com/jasonstolaruk/CurryMUD/blob/master/cheatsheet/CurryMUD%20cheatsheet.pdf) :memo:

I am still in the initial stage of developing basic commands. There is very little content in the virtual world.

## About the code

The code is available here on GitHub under [this license](https://github.com/jasonstolaruk/CurryMUD/blob/master/LICENSE) (a 3-clause BSD license with additional unique clauses regarding the creation of derivative MUDs.) Please note that **I am not accepting PRs**.

* About 42,000 lines of code/text.
* About 120 modules, excluding tests.
* About 105 unit and property tests (I'm using the [tasty testing framework](https://hackage.haskell.org/package/tasty)).
* A `ReaderT` monad transformer stack with the entire world state inside a single `IORef`.
* `STM`-based concurrency.
* Using `aeson` (with `conduit`) and `sqlite-simple` for persistence.
* Heavy use of the `lens` library.
* Heavy use of GHC extensions, including:
  * `DuplicateRecordFields`
  * `LambdaCase`
  * `MonadComprehensions`
  * `MultiWayIf`
  * `NamedFieldPuns`
  * `ParallelListComp`
  * `PatternSynonyms`
  * `RebindableSyntax`
  * `RecordWildCards`
  * `TupleSections`
  * `TypeApplications`
  * `ViewPatterns`
* Many functions are decorated with [the `HasCallStack` constraint](https://www.stackage.org/haddock/lts-9.17/base-4.9.1.0/GHC-Stack.html#t:HasCallStack). I hope to remove these when I'm convinced that the code is stable.

## How to try it out

Linux and macOS are supported. Sorry, but Windows is _not_ supported.

Please build with [stack](http://docs.haskellstack.org/en/stable/README.html):
1. [Install the pcre library](http://www.pcre.org) if necessary. (On macOS, `brew install pcre` should be sufficient.)
1. [Install stack.](http://docs.haskellstack.org/en/stable/install_and_upgrade/)
1. Clone the repo from your home directory (the server expects to find various folders under `$HOME/CurryMUD`).
1. Inside `$HOME/CurryMUD`, run `stack setup` to get GHC 8 on your machine. (The `stack.yaml` file points to [a recent resolver](https://www.stackage.org/snapshots) using GHC 8.)
1. Run `stack build` to compile the `curry` binary and libraries.
1. Run `stack install` to copy the `curry` binary to `$HOME/.local/bin`.
1. Execute the `curry` binary.
1. Telnet to `localhost` port 9696 to play. (Better yet, use a MUD client.)

## How to contact me

Feel free to email me at the address associated with [my GitHub account](https://github.com/jasonstolaruk) if you have any questions.
