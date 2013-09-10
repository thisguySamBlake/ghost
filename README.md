ghost
=====

**ghost** is an engine for a highly-simplified form of interactive fiction, tentative called *explorative fiction*. While ghost does support the navigation ("go") and investigation ("look") of a world, it doesn't support the player interacting with the world in any way. (This is an intentional limitation, intended to work well for a restricted class of storytelling.)

Because this format is relatively limited, it's beneficial to create an authorship environment that's optimized for writing in it. To that end, ghost provides a [syntax](test/test.ghost) for writing explorative fiction and a [parser](lib/parser.rb) that handles the syntax.

The parser can be tested on the provided test file by running `rake test`. As yet, the parser doesn't actually build a playable game, merely a data tree.
