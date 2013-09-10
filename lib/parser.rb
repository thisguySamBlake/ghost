require 'parslet' 

class GhostParser < Parslet::Parser
  # Whitespace
  rule(:space)      { match('\s').repeat(1) }
  rule(:newline)    { match('\n') }
  rule(:blank_line) { newline.repeat(2) }

  rule(:prompt)      { blank_line >> str('>') >> space }
  rule(:label)       { (newline.absent? >> any).repeat(1) }
  rule(:description) { (prompt.absent? >> any).repeat(1) }
  rule(:command)     { str('go').absent? >> label }
  rule(:action)      { (prompt >> command.as(:command)) >> blank_line >> description.as(:result) }
  
  # Rooms
  rule(:exit) { newline >> str('  -> ') >> label.as(:exit)}
  rule(:room) { prompt >> str('go') >> space >> label.as(:room_name) >> exit.repeat.as(:exits) >> blank_line >> description.as(:description) >> action.repeat.as(:local_actions) }

  # Game
  rule(:game) { description.as(:start) >> action.repeat.as(:global_actions) >> room.repeat(1).as(:rooms) }
  root :game
end
