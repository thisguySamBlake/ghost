require 'parslet' 

module Ghost
  class Parser < Parslet::Parser
    # Whitespace
    rule(:space)      { match(' ').repeat(1) }
    rule(:space?)     { space.maybe }
    rule(:indent)     { match(' ').repeat(2) }
    rule(:newline)    { match('\n') }
    rule(:blank_line) { newline.repeat(2) }

    # Prompts
    rule(:prompt)         { str('>') >> space }
    rule(:new_prompt)     { blank_line >> prompt }
    rule(:synonym_prompt) { newline >> prompt }

    # Symbols
    rule(:arrow) { space? >> str('->') >> space }

    # Text
    rule(:wildcard)    { space >> str('*') >> space? }
    rule(:label)       { (arrow.absent? >> newline.absent? >> wildcard.absent? >> any).repeat(1).as(:label) }
    rule(:description) { (new_prompt.absent? >> timestamp.absent? >> any).repeat(1).as(:descriptive_text) }

    # Commands
    rule(:room_command_prefix)  { str('go') >> space }
    rule(:room_command)         { room_command_prefix >> zoned_room.as(:zoned_room) }
    rule(:transitive_command)   { room_command_prefix.absent? >> label.as(:transitive_command) >> wildcard }
    rule(:intransitive_command) { room_command_prefix.absent? >> label.as(:command) }
    rule(:command)              { transitive_command | intransitive_command }
    rule(:commands)             { command >> (synonym_prompt >> command).repeat }

    # Actions (commands + results)
    rule(:action) { new_prompt >> commands.as(:commands) >> blank_line >> descriptions.as(:result) }

    # Timestamps
    rule(:descriptions) { description >> (timestamp >> description).repeat }
    rule(:timestamp)    { blank_line >> str('[') >> match('\d').repeat(1).as(:timestamp) >> str(']') >> blank_line }

    # Rooms
    rule(:exit) { newline >> indent >> arrow >> zoned_room.as(:exit)}
    rule(:room) { new_prompt >> room_command >> (synonym_prompt >> room_command).repeat >> exit.repeat.as(:exits) >> blank_line >> descriptions.as(:description) >> action.repeat.as(:local_actions) }
    rule(:zone) { label.as(:zone) >> arrow }
    rule(:zoned_room) { zone.maybe >> label.as(:name)}

    # Game
    rule(:game) { description.as(:start) >> action.repeat.as(:global_actions) >> room.repeat(1).as(:rooms) }
    root :game
  end
end
