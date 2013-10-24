require_relative 'game'

module Ghost
  class Transform < Parslet::Transform
    # Text
    rule(:label => simple(:text)) { String(text) }
    rule(:prose => simple(:text)) { { 0 => String(text) } }

    # Timestamps
    rule(:name     => simple(:name))     { { :name => String(name) } }
    rule(:name     => simple(:name),
         :operator => simple(:operator),
         :value    => simple(:value))    { { :name     => String(name),
                                             :operator => String(operator),
                                             :value    => Integer(value) } }
    rule(:timestamp => subtree(:t),
         :prose     => simple(:text)) { { t => String(text) } }

    # Actions
    rule(:commands    => sequence(:commands),
         :description => subtree(:description)) do |dict|
      { :commands    => commands,
        :description => flatten_description(dict[:description]) }
    end

    # Rooms
    rule(:room_name => simple(:room)) { { :zone => nil, :room => room } }
    rule(:zoned_room    => subtree(:zoned_room),
         :exits         => subtree(:exits),
         :description   => subtree(:description),
         :local_actions => subtree(:actions)) do |dict|
      room                = Ghost::Room.new
      room.zone           = dict[:zoned_room][:zone] # not yet object ref
      room.name           = dict[:zoned_room][:room]
      room.exits          = dict[:exits] # not yet object refs
      room.actions.merge!   flatten_actions dict[:actions]

      # Add `> look` command to all rooms
      room.actions[Ghost::Command.new "look"] = flatten_description dict[:description]
      room
    end

    # Game
    rule(:start_description  => subtree(:start_description),
         :global_actions     => subtree(:actions),
         :rooms              => subtree(:rooms),
         :timestamp_manifest => subtree(:timestamp_manifest)) do |dict|
      game = Ghost::Game.new
      game.start_description = Ghost::Description.new dict[:start_description]
      game.actions.merge!      flatten_actions dict[:actions]
      game.merge!              inflate_zones dict[:rooms]
      game.current_room      = dict[:rooms].first

      inflate_timestamps game, dict[:timestamp_manifest]
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

          flattened_actions[command] = flatten_description action[:description]
        end
      end

      flattened_actions
    end

    # Make description data structures consistent
    def self.flatten_description(description)
      # Convert to array if there is only one result
      description = [description] unless description.is_a? Array

      # Merge array of hashes
      # i.e. [{0 => "str0"}, {10 => "str1"}] yields {0 => "str0", 10 => "str1"}
      Ghost::Description.new description.inject(:merge)
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
            exit_refs << exit_zone[exit[:room]]
          end

          # Replace list of strings with list of refs
          room.exits = exit_refs
        end
      end

      zones
    end

    def self.inflate_timestamps(game, timestamp_manifest)
      timestamps = {}

      # Set absolute timestamps set in manifest files
      timestamp_manifest.each do |timestamp|
        timestamp = timestamp[:timestamp]
        if timestamp[:operator] == "="
          # Add time value to timestamp dictionary
          timestamps[timestamp[:name]] = timestamp[:value]
        end
      end

      # Set absolute timestamps not defined in manifest files
      is_new_absolute_timestamp = Proc.new do |timestamp|
        timestamp.is_a? Hash             and not
        timestamps.key? timestamp[:name] and
        timestamp.key? :operator         and
        timestamp[:operator] == "="
      end
      process_timestamps_if(game, is_new_absolute_timestamp) do |timestamp|
        # Add time value to timestamp dictionary, then return it
        timestamps[timestamp[:name]] = timestamp[:value]
      end

      # Set all relative timestamps to time values
      is_relative_timestamp = Proc.new do |timestamp|
        timestamp.is_a? Hash and timestamp.key? :name
      end
      process_timestamps_if(game, is_relative_timestamp) do |timestamp|
        # Look up base time value of named timestamp from dictionary
        time = timestamps[timestamp[:name]]

        # Modify time value per the provided operator
        if timestamp.key? :operator
          if timestamp[:operator] == "+"
            time += timestamp[:value]
          elsif timestamp[:operator] == "-"
            time -= timestamp[:value]
          end
        end

        # Return modified time value
        time
      end
    end

    # Pass through all timestamps and replace them with an integer value if condition is met
    def self.process_timestamps_if(game, condition)
      game.each do |name, zone|
        zone.each do |name, room|
          room.actions.each do |command, description|
            rehashed_descriptions = {}

            description.each do |timestamp, result|
              if condition.call timestamp
                time = yield timestamp

                # Replace timestamp object with integer value
                # NOTE: We can't add elements to the hash during iteration, because Ruby
                rehashed_descriptions[time] = result
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
