module Ghost
  require 'awesome_print'
  require 'readline'

  class Game
    attr_accessor :start_description, :actions, :rooms, :time, :current_room_name

    def [](command)
      @actions[command]
    end

    def current_room
      rooms[@current_room_name]
    end

    def describe(description, free = false)
      @time += 1 unless free
      puts description[@time]
    end

    def execute(command)
      if command == "quit"
        exit
      elsif command == "look"
        describe current_room.description
      elsif command == "time"
        puts @time
      elsif command.start_with? "go "
        move command[3..command.length]
      elsif current_room[command]
        describe current_room[command]
      elsif self[command]
        describe self[command]
      else
        puts "Unrecognized command"
      end
    end

    def move(destination)
      if current_room.exits.include? destination
        @current_room_name = destination
        describe current_room.description
      else
        "Invalid exit"
      end
    end

    def play
      puts
      start
      puts
      begin
        while input = Readline.readline("> ", true)
          puts
          execute input
          puts
        end
      rescue Interrupt => e
        puts "quit"
        puts
        exit
      end
    end

    def start
      @time = 0
      describe @start_description, free: true
      puts
      describe current_room.description, free: true
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

  class Command < String
    attr_accessor :str, :transitive

    def initialize(str, transitive: false)
      super str
      @str = str
      @transitive = transitive
    end
  end
end
