require_relative 'game'

module Ghost
  class Transform < Parslet::Transform
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
    rule(:room_name => simple(:name)) { { :zone => nil, :name => name } }
    rule(:zoned_room    => subtree(:zoned_room),
         :exits         => subtree(:exits),
         :description   => subtree(:descriptions),
         :local_actions => subtree(:actions)) do |dict|
      room             = Ghost::Room.new
      room.zone        = dict[:zoned_room][:zone] # not yet object ref
      room.name        = dict[:zoned_room][:name]
      room.exits       = dict[:exits] # not yet object refs
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
      game.zones             = inflate_zones dict[:rooms]
      game.current_room      = dict[:rooms].first
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

    # Convert zone strings to first class object refs
    def self.inflate_zones(rooms)
      zones = {}
      last_zone = nil

      rooms.each do |room|
        # Create zone if necessary
        if room.zone
          unless zones.key? room.zone
            zones[room.zone] = Ghost::Zone.new
            zones[room.zone].name = room.zone
            zones[room.zone].rooms = {}
            last_zone = zones[room.zone]
          end
        end

        # Hydrate room->zone ref
        if room.zone
          room.zone = zones[room.zone]
        else
          # Use the last created zone if none is provided
          room.zone = last_zone
        end

        # Add room to zone
        zones[room.zone.name].rooms[room.name] = room
      end

      # Hydrate exit refs
      zones.each do |name, zone|
        zone.rooms.each do |name, room|
          exit_refs = []

          room.exits.each do |exit|
            exit = exit[:exit]

            # If the exit's zone isn't specified, it's the same as the room's
            exit_zone = (exit.key? :zone) ? zones[exit[:zone]] : room.zone

            # Add room ref to list of valid exits
            exit_refs << exit_zone.rooms[exit[:name]]
          end

          # Replace list of strings with list of refs
          room.exits = exit_refs
        end
      end

      zones
    end
  end
end
