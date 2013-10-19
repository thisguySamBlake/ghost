require_relative 'game'

module Ghost
  class Transform < Parslet::Transform
    # Labels / Descriptions
    rule(:label            => simple(:text)) { String(text) }
    rule(:descriptive_text => simple(:text)) { { 0 => String(text) } }

    # Timestamps
    rule(:name     => simple(:name))     { { :name => String(name) } }
    rule(:name     => simple(:name),
         :operator => simple(:operator),
         :value    => simple(:value))    { { :name     => String(name),
                                             :operator => String(operator),
                                             :value    => Integer(value) } }
    rule(:timestamp        => subtree(:t),
         :descriptive_text => simple(:text)) { { t => String(text) } }

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
      room                = Ghost::Room.new
      room.zone           = dict[:zoned_room][:zone] # not yet object ref
      room.name           = dict[:zoned_room][:name]
      room.exits          = dict[:exits] # not yet object refs
      room.actions.merge!   flatten_actions dict[:actions]

      # Add `> look` command to all rooms
      room.actions[Ghost::Command.new "look"] = flatten_descriptions dict[:descriptions]
      room
    end

    # Game
    rule(:start          => subtree(:start),
         :global_actions => subtree(:actions),
         :rooms          => subtree(:rooms)) do |dict|
      game = Ghost::Game.new
      game.start_description = Ghost::Description.new dict[:start]
      game.actions.merge!      flatten_actions dict[:actions]
      game.merge!              inflate_zones dict[:rooms]
      game.current_room      = dict[:rooms].first

      inflate_timestamps game
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

          flattened_actions[command] = flatten_descriptions action[:result]
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
        zones[room.zone.name][room.name] = room
      end

      # Hydrate exit refs
      zones.each do |name, zone|
        zone.each do |name, room|
          exit_refs = []

          room.exits.each do |exit|
            exit = exit[:exit]

            # If the exit's zone isn't specified, it's the same as the room's
            exit_zone = (exit.key? :zone) ? zones[exit[:zone]] : room.zone

            # Add room ref to list of valid exits
            exit_refs << exit_zone[exit[:name]]
          end

          # Replace list of strings with list of refs
          room.exits = exit_refs
        end
      end

      zones
    end

    def self.inflate_timestamps(game)
      timestamps = {}

      # Set all absolute timestamps to integer values
      is_absolute_timestamp = Proc.new do |timestamp|
        timestamp.is_a? Hash and timestamp.key? :operator and timestamp[:operator] == "="
      end
      process_timestamps_if(game, is_absolute_timestamp) do |timestamp|
        time = timestamp[:value]

        # Add to timestamp dictionary
        timestamps[timestamp[:name]] = time

        time
      end

      # Set all relative timestamps to integer values
      is_relative_timestamp = Proc.new do |timestamp|
        timestamp.is_a? Hash and timestamp.key? :name
      end
      process_timestamps_if(game, is_relative_timestamp) do |timestamp|
        time = timestamps[timestamp[:name]]

        if timestamp.key? :operator
          if timestamp[:operator] == "+"
            time += timestamp[:value]
          elsif timestamp[:operator] == "-"
            time -= timestamp[:value]
          end
        end

        time
      end
    end

    # Pass through all timestamps and replace them with an integer value if condition is met
    def self.process_timestamps_if(game, condition)
      game.each do |name, zone|
        zone.each do |name, room|
          room.actions.each do |command, description|
            rehashed_descriptions = {}

            description.each do |timestamp, descriptive_text|
              if condition.call timestamp
                time = yield timestamp

                # Replace timestamp object with integer value
                # NOTE: We can't add elements to the hash during iteration, because Ruby
                rehashed_descriptions[time] = descriptive_text
                description.delete timestamp
              end
            end

            # Add descriptions with integer timestamps
            description.merge! rehashed_descriptions
          end
        end
      end
    end
  end
end
