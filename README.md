ghost
=====

**ghost** is an engine for a highly-simplified form of interactive fiction, tentatively called *explorative fiction*. While ghost does support the navigation ("go") and investigation ("look") of a world, it doesn't support the player interacting with the world in any way. (This is an intentional limitation, intended to work well for a restricted class of storytelling.)

Because this format is relatively limited, it's beneficial to create an authorship environment that's optimized for writing in it. To that end, ghost provides a [syntax](test/game/_starting_zone.ghost) for writing explorative fiction, a [parser](lib/parser.rb) that handles that syntax, and a [transform](lib/transform.rb) that will convert the parse into a playable [game](lib/game.rb).

The following `rake` tasks are available to test the game defined in [test/game/](test/game/):

- `rake test`: output parse and transform results
- `rake test:reader`: output game directory read/concatenate results
- `rake test:parser`: output parse results
- `rake test:transform`: output transform results (after parsing)
- `rake test:console`: play test game in console
- `rake test:server`: play test game via AJAX requests
  - `http://localhost:4567/start`: start game
  - `http://localhost:4567/execute/:command`: execute command
- `rake test:client`: play test game via web interface
  - `http://localhost:4567/`: play game
