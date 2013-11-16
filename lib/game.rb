module Ghost
  class Game < Hash
    # Actions
    attr_accessor :actions

    # Properties
    attr_accessor :debug, :start_description, :endgame_time, :endgame_result

    # State
    attr_accessor :time, :current_room

    def describe(description, time_cost: 1, wait: false)
      if @endgame_time and @time + time_cost >= @endgame_time
        @endgame_result.wait = @endgame_time - @time if wait
        return @endgame_result
      end

      @time += time_cost
      result = description[@time]

      unless result.seen
        # Save a copy of the unseen result (to return)
        result = result.clone

        # Set this result as seen
        description[@time].seen = true

        # Set all future identical results as seen
        description.each do |time, future_result|
          if future_result.to_s == result.to_s
            future_result.seen = true
          end
        end
      end

      result.wait = time_cost if wait
      result
    end

    def execute(command)
      command.downcase!
      if command == "quit"
        Ghost::Result.new "Thanks for playing!", endgame: true
      elsif @debug and command == "commands"
        commands = ""
        (self.actions.keys + current_room.actions.keys).each do |command, description|
          if commands != ""
            commands += "\n"
          end
          commands += "- " + command.to_s
          if command.transitive
            commands += " *"
          end
        end
        Ghost::Result.new commands
      elsif @debug and command == "exits"
        exits = ""
        current_room.exits.each do |exit|
          if exits != ""
            exits += "\n"
          end
          exits += "- "
          if exit.zone != current_room.zone
            exits += exit.zone.name + " -> "
          end
          exits += exit.name
        end
        Ghost::Result.new exits
      elsif @debug and command == "time"
        Ghost::Result.new @time.to_s
      elsif command == "wait"
        time_cost = 20
        next_time = current_room.actions["look"].next_time @time
        time_cost = [next_time - @time, time_cost].min if next_time
        describe current_room.actions["look"], time_cost: time_cost, wait: true
      elsif command.start_with? "go "
        move command[3..command.length]
      elsif current_room.actions[command]
        describe current_room.actions[command]
      elsif self.actions[command]
        describe self.actions[command]
      else
        Ghost::Result.new "Unrecognized command"
      end
    end

    def initialize
      @actions = Ghost::ActionCollection.new
    end

    def move(destination)
      exit = current_room.exit destination
      if exit
        @current_room = exit
        describe current_room.actions["look"]
      else
        Ghost::Result.new "Invalid exit"
      end
    end

    def start
      @time = 0
      describe @start_description, time_cost: 0
    end
  end

  class Zone < Hash
    # Properties
    attr_accessor :name
  end

  class Room
    # Actions
    attr_accessor :actions

    # Properties
    attr_accessor :zone, :name, :exits
    @exits = []

    def exit(destination)
      # Attempt to find an exit matching the input
      exits.each do |exit|
        if exit.name.downcase == destination or exit.zone.name.downcase == destination
          return exit
        end
      end

      # Return nil if no matching exit is found
      return nil
    end

    def initialize
      @actions = Ghost::ActionCollection.new
    end
  end

  class ActionCollection < Hash
    def [](input)
      # Find an action that matches the input
      action = find do |command, result|
        if command.transitive
          input.start_with?(command)
        else
          input == command
        end
      end

      # If an action is found, return its result
      (action) ? action[1] : nil
    end
  end

  class Command < String
    attr_accessor :transitive

    def initialize(str, transitive: false)
      super str
      @transitive = transitive
    end
  end

  class Description < Hash
    # Instantiate a Description from a hash
    def self.new(hsh)
      super_hsh = super
      super_hsh.replace hsh
    end

    # Access the last valid descriptive text
    def [](time)
      prev_time = prev_time time
      fetch prev_time if prev_time
    end

    def next_time(time)
      # Attempt to find a timestamp after the current time
      keys.sort.each do |timestamp|
        if timestamp > time
          return timestamp
        end
      end

      # Return nil if no such timestamp is found
      return nil
    end

    def prev_time(time)
      # Attempt to find a timestamp before the current time
      keys.sort.reverse.each do |timestamp|
        if timestamp <= time
          return timestamp
        end
      end

      # Return nil if no such timestamp is found
      return nil
    end
  end

  class Result < String
    attr_accessor :seen, :wait, :endgame

    def initialize(str, wait: nil, endgame: false)
      super str
      @seen = false
      @wait = wait
      @endgame = endgame
    end
  end
end
