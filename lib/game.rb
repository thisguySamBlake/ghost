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
    @actions = {}

    attr_accessor :start_description, :zones, :time, :current_room

    def describe(description, time_cost: 1)
      @time += time_cost
      puts description[@time]
    end

    def execute(command)
      if command == "quit"
        exit
      elsif command == "wait"
        next_time = current_room["look"].next_time @time
        @time = next_time - 1 if next_time
        describe current_room["look"]
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
      exit = current_room.exit destination
      if exit
        @current_room = exit
        describe current_room["look"]
      else
        puts "Invalid exit"
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
    end
  end

  class Zone
    attr_accessor :name, :rooms
  end

  class Room
    include Actionable
    attr_accessor :actions
    @actions = {}

    attr_accessor :zone, :name, :exits
    @name = nil
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

  class Command < String
    attr_accessor :transitive

    def initialize(str, transitive: false)
      super str
      @transitive = transitive
    end
  end
end
