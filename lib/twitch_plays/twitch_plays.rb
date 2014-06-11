require_relative 'os'
require 'yaml'
require 'cinch'

module TwitchPlays
  class Plugin
    include Cinch::Plugin

    TOUCH_DIRECTIONS = {
      touch_up: [0, -50],
      touch_down: [0, 50],
      touch_left: [-50, 0],
      touch_right: [50, 0]
    }

    plugin_name = 'TwitchPlaysPlugin'
    listen_to :connect, method: :on_connect
    listen_to :message, method: :on_message

    def initialize(*args)
      super
      @keys = config[:keys]
      @democracy_votes = 0
      @anarchy_votes = 0
      @use_democracy = config[:use_democracy]
      @democracy_mode = @use_democracy && config[:start_in_democracy]
      @democracy_ratio_needed = config[:democracy_ratio_needed]
      @anarchy_ratio_needed = config[:anarchy_ratio_needed]
      @button_votes = Hash.new(0)
      @voting_time = config[:voting_time]
      @voting_thread = nil
      @total_votes = 0
      @use_savestates = config[:use_savestates]
      @savestate_interval = config[:savestate_interval]
      @savestate_thread = nil
      @log_line_length = config[:log_line_length]
      start_democracy if @democracy_mode
    end

    def calculate_ratio
      @democracy_votes.to_f / [@democracy_votes + @anarchy_votes, 1].max
    end

    def start_democracy
      return if @democracy_mode
      @democracy_mode = true
      puts '---STARTING DEMOCRACY MODE---'
      @voting_thread = Thread.new do
        while @democracy_mode
          synchronize(:votes_mutex) do
            @button_votes.clear
            @total_votes = 0
          end
          sleep @voting_time
          next if @total_votes == 0
          winner = synchronize(:votes_mutex) do
            puts "VOTES:\n" + @button_votes.sort {|(_, count1), (_, count2)|
              count1 <=> count2
            }.first(5).map {|(btn, count)|
              [btn, count.to_f / @total_votes * 100]
            }.map {|(btn, percent)|
              format_log_line(btn, "#{percent}%")
            }.join("\n")
            @button_votes.max_by {|(_, count)| count}
          end
          btn = winner[0]
          case btn
          when :touch_up, :touch_down, :touch_left, :touch_right
            Output.touch_move(*TOUCH_DIRECTIONS[btn])
          when :touch_press
            Output.touch_press
          when :touch_release
            Output.touch_release
          else
            Output.press(@keys[btn])
          end
        end
      end
    end

    def start_anarchy
      return unless @democracy_mode
      @democracy_mode = false
      @voting_thread.join
      @voting_thread = nil
      puts '---STARTING ANARCHY MODE---'
    end

    def format_log_line(name, command)
      "#{name}#{' ' * (@log_line_length - name.length - command.length)}#{command}"
    end

    def on_connect(msg)
      return unless @use_savestates
      @savestate_thread = Thread.new do
        key = @keys[:save_state]
        loop do
          sleep @savestate_interval
          Output.press(key)
        end
      end
    end

    def on_message(msg)
      message = msg.message
      case message
      when /^anarchy$/i
        return unless @use_democracy
        puts format_log_line(msg.user.nick, message.downcase)
        synchronize(:votes_mutex) do
          @anarchy_votes += 1
          if @democracy_mode && calculate_ratio <= @anarchy_ratio_needed
            start_anarchy
          end
        end
      when /^democracy$/i
        return unless @use_democracy
        puts format_log_line(msg.user.nick, message.downcase)
        synchronize(:votes_mutex) do
          @democracy_votes += 1
          if !@democracy_mode && calculate_ratio >= @democracy_ratio_needed
            start_democracy
          end
        end
      when /^(?:up|down|left|right|a|b|x|y|l|r|start|select)$/i
        btn = $&.to_sym
        if @democracy_mode
          synchronize(:votes_mutex) do
            @total_votes += 1
            @button_votes[btn] += 1
          end
          return
        end
        puts format_log_line(msg.user.nick, message.downcase)
        Output.press(@keys[btn])
      when /^(?:touch_up|touch_down|touch_left|touch_right)$/i
        if @democracy_mode
          synchronize(:votes_mutex) do
            @total_votes += 1
            @button_votes[$&.to_sym] += 1
          end
          return
        end
        puts format_log_line(msg.user.nick, message.downcase)
        Output.touch_move(*TOUCH_DIRECTIONS[btn])
      when /^touch_press$/i
        if @democracy_mode
          synchronize(:votes_mutex) do
            @total_votes += 1
            @button_votes[$&.to_sym] += 1
          end
          return
        end
        puts format_log_line(msg.user.nick, message.downcase)
        Output.touch_press
      when /^touch_release$/i
        if @democracy_mode
          synchronize(:votes_mutex) do
            @total_votes += 1
            @button_votes[$&.to_sym] += 1
          end
          return
        end
        puts format_log_line(msg.user.nick, message.downcase)
        Output.touch_release
      end
    end
  end

  def self.start(config_file:)
    bot = Cinch::Bot.new do
      configure do |c|
        config = YAML.load_file(config_file)
        c.server = config[:server]
        c.port = config[:port]
        c.nick = config[:nick]
        c.password = config[:password]
        c.channels = [config[:channel]]
        c.plugins.plugins = [Plugin]
        c.plugins.options[Plugin] = config
      end
    end
    bot.start
  end
end
