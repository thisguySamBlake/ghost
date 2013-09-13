require_relative 'game'

class GhostTransform < Parslet::Transform
  # Labels / Descriptions
  rule(:label            => simple(:text)) { String(text) }
  rule(:descriptive_text => simple(:text)) { { 0 => String(text) } }
  rule(:timestamp        => simple(:t),
       :descriptive_text => simple(:text)) { { Integer(t) => String(text) } }

  # Actions
  rule(:commands => sequence(:commands),
       :result   => subtree(:descriptions)) do |dict|
    { :commands    => commands,
      :description => flatten_descriptions(dict[:descriptions]) }
  end

  # Rooms
  rule(:exit          => simple(:room)) { room }
  rule(:room_name     => simple(:name),
       :exits         => sequence(:exits),
       :description   => subtree(:descriptions),
       :local_actions => subtree(:actions)) do |dict|
    room             = Ghost::Room.new
    room.name        = dict[:name]
    room.exits       = dict[:exits]
    room.description = flatten_descriptions dict[:descriptions]
    room.actions     = flatten_actions dict[:actions]
    room
  end

  # Game
  rule(:start          => subtree(:start),
       :global_actions => subtree(:actions),
       :rooms          => subtree(:rooms)) do |dict|
    game = Ghost::Game.new
    game.start_description = Ghost::Description.new dict[:start]
    game.actions           = flatten_actions dict[:actions]
    game.rooms             = Hash[dict[:rooms].map{|room| [room.name, room]}]
    game.current_room_name = dict[:rooms].first.name
    game
  end

  # Break apart command synonyms into separate actions
  def self.flatten_actions(actions)
    flattened_actions = {}
    actions.each do |action|
      commands = action[:commands]

      # Convert to array if there is only one command
      commands = [commands] unless commands.is_a? Array
      
      # Create the correct type of command for each synonym
      commands.each do |command_hash|
        if command_hash.keys.first == :command
          command = Ghost::Command.new command_hash[:command]
        elsif command_hash.keys.first == :transitive_command
          command = Ghost::Command.new command_hash[:transitive_command], transitive: true
        end

        flattened_actions[command] = Ghost::Description.new action[:result]
      end
    end

    flattened_actions
  end

  # Make description data structures consistent
  def self.flatten_descriptions(descriptions)
    # Convert to array if there is only one description
    descriptions = [descriptions] unless descriptions.is_a? Array

    # Merge array of hashes: i.e. [{0 => "str0"}, {10 => "str1"}] yields {0 => "str0", 10 => "str1"}
    Ghost::Description.new descriptions.inject(:merge)
  end
end
