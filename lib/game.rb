module Ghost
  class Game < Hash
    # Actions
    attr_accessor :actions

    # Properties
    attr_accessor :start_description, :endgame_time, :endgame_result

    # State
    attr_accessor :time, :current_room

    def describe(description, time_cost: 1)
      @time += time_cost

      if @endgame_time
        if @time >= @endgame_time
          return @endgame_result
        end
      end

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
      result
    end

    def execute(command)
      if command == "quit"
        Ghost::Result.new "Thanks for playing!", endgame: true
      elsif command == "wait"
        next_time = current_room.actions["look"].next_time @time
        @time = next_time - 1 if next_time
        describe current_room.actions["look"]
      elsif command == "time"
        Ghost::Result.new @time.to_s
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
        if exit.name == destination or exit.zone.name == destination
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
    attr_accessor :seen, :endgame

    def initialize(str, endgame: false)
      super str
      @seen = false
      @endgame = endgame
    end
  end
end
