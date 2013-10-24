require 'parslet' 

module Ghost
  class Parser < Parslet::Parser
    # Whitespace
    rule(:space)      { match(' ').repeat(1) }
    rule(:indent)     { match(' ').repeat(2, 2) }
    rule(:newline)    { match('\n') }
    rule(:blank_line) { newline.repeat(2) }
    rule(:eof)        { newline.repeat >> any.absent? }

    # Symbols
    rule(:arrow)         { space.maybe >> str('->') >> space }
    rule(:bracket)       { left_bracket | right_bracket }
    rule(:left_bracket)  { str('[') >> space.maybe }
    rule(:right_bracket) { space.maybe >> str(']') }
    rule(:operator)      { space >> (str('=') | str('+') | str('-')).as(:operator) >> space }
    rule(:wildcard)      { space >> str('*') }

    # Prompts
    rule(:prompt)         { str('>') >> space }
    rule(:new_prompt)     { blank_line >> prompt }
    rule(:synonym_prompt) { newline >> prompt }

    # Text
    rule(:label) { (arrow.absent?    >>
                    newline.absent?  >>
                    wildcard.absent? >> any).repeat(1).as(:label) }
    rule(:prose) { (eof.absent?                >>
                    new_prompt.absent?         >>
                    result_timestamp.absent?   >>
                    timestamp_manifest.absent? >> any).repeat(1).as(:prose) }

    # Commands
    rule(:command)              { room_command_prefix.absent? >>
                                  (transitive_command | intransitive_command) }
    rule(:intransitive_command) { label.as(:command) }
    rule(:transitive_command)   { label.as(:transitive_command) >> wildcard }
    rule(:commands)             { new_prompt >> command >> (synonym_prompt >> command).repeat }
    rule(:room_command)         { room_command_prefix >>
                                  zoned_room_label.as(:zoned_room) }
    rule(:room_command_prefix)  { str('go') >> space }

    # Timestamps
    rule(:timestamp)          { left_bracket                                             >>
                                (timestamp_name >> timestamp_value.maybe).as(:timestamp) >>
                                right_bracket }
    rule(:timestamp_name)     { (bracket.absent?  >>
                                 newline.absent?  >>
                                 operator.absent? >> any).repeat(1).as(:name) }
    rule(:timestamp_value)    { operator >>
                                match('\d').repeat(1).as(:value) }
    rule(:result_timestamp)   { blank_line >> timestamp }
    rule(:timestamp_manifest) { (blank_line         >>
                                 str('.ghost_time') >>
                                 (newline.repeat(1) >> timestamp).repeat(1)).repeat(1) }

    # Actions
    rule(:action)      { commands.as(:commands) >>
                         description.as(:description) }
    rule(:description) { result >> (result_timestamp >> result).repeat }
    rule(:result)      { blank_line >> prose }

    # Rooms
    rule(:room)             { new_prompt                   >>
                              room_command                 >>
                              exit.repeat.as(:exits)       >>
                              description.as(:description) >>
                              action.repeat.as(:local_actions) }
    rule(:zone)             { label.as(:zone) >>
                              arrow }
    rule(:zoned_room_label) { zone.maybe >>
                              label.as(:room) }
    rule(:exit)             { newline >>
                              indent  >>
                              arrow   >>
                              zoned_room_label.as(:exit) }

    # Game
    rule(:game) { prose.as(:start_description)                            >>
                  action.repeat.as(:global_actions)                       >>
                  room.repeat(1).as(:rooms)                               >>
                  timestamp_manifest.repeat(0, 1).as(:timestamp_manifest) >>
                  eof }
    root(:game)
  end
end
