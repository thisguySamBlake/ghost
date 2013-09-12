module Ghost
  require 'awesome_print'

  class Game
    attr_accessor :start_description, :actions, :rooms, :time, :current_room_name

    def [](command)
      @actions[command]
    end

    def current_room
      rooms[@current_room_name]
    end

    def describe(description, free = false)
      puts description[@time]
      @time += 1 unless free
    end

    def execute(command)
      if command == "quit"
        exit
      elsif command == "look"
        describe current_room.description
      elsif command == "time"
        puts @time
      elsif current_room[command]
        describe current_room[command]
      elsif self[command]
        describe self[command]
      else
        puts "Unrecognized command"
      end
    end

    def play
      puts
      start
      loop do
        puts
        print "> "
        input = STDIN.gets.chomp
        puts
        execute Command.new input
      end
    end

    def start
      @time = 0
      describe @start_description, free: true
    end
  end

  class Room
    attr_accessor :name, :exits, :description, :actions
    @name = nil
    @exits = []
    @description = nil
    @actions = {}

    def [](command)
      @actions[command]
    end
  end

  class Description
    attr_accessor :descriptions

    def [](time)
      # Return description valid at the given time
      @descriptions.keys.sort.reverse.each do |timestamp|
        if timestamp <= time
          return @descriptions[timestamp]
        end
      end
    end

    def initialize(timestamped_descriptions)
      @descriptions = timestamped_descriptions
    end
  end

  class Command
    attr_accessor :command

    # TODO: this is dangerous and should be replaced with a better approach
    def ==(command_string)
      @command == command_string
    end

    def eql?(other)
      @command.eql? other.command
    end

    def hash
      @command.hash
    end

    def initialize(command_string)
      @command = command_string
    end
  end

  class TransitiveCommand < Command
  end
end
