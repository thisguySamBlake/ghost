module Ghost
  require 'awesome_print'
  require 'readline'

  module Actionable
    def [](input)
      # Find an action that matches the input
      action = @actions.find do |command, result|
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

  class Game
    include Actionable
    attr_accessor :actions

    attr_accessor :start_description, :rooms, :time, :current_room_name

    def current_room
      rooms[@current_room_name]
    end

    def describe(description, time_cost: 1)
      @time += time_cost
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
        while input = Readline.readline("> ", true).downcase
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
      describe @start_description, time_cost: 0
      puts
      describe current_room.description, time_cost: 0
    end
  end

  class Room
    include Actionable
    attr_accessor :actions
    @actions = {}

    attr_accessor :name, :exits, :description
    @name = nil
    @exits = []
    @description = nil
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
