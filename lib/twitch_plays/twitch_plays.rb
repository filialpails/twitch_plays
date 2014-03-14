require 'yaml'
require 'ffi' if RbConfig::CONFIG['host_os'] =~ /win/
require 'cinch'

module TwitchPlays
  if RbConfig::CONFIG['host_os'] =~ /win/
    module Win
      extend FFI::Library

      INPUT_KEYBOARD = 1

      VK_BACK = 0x08
      VK_TAB = 0x09
      VK_RETURN = 0x0d
      VK_SHIFT = 0x10
      VK_CONTROL = 0x11
      VK_SPACE = 0x20
      VK_LEFT = 0x25
      VK_UP = 0x26
      VK_RIGHT = 0x27
      VK_DOWN = 0x28
      VK_F1 = 0x70
      VK_F2 = 0x71
      VK_F3 = 0x72
      VK_F4 = 0x73
      VK_F5 = 0x74
      VK_F6 = 0x75
      VK_F7 = 0x76
      VK_F8 = 0x77
      VK_F9 = 0x78
      VK_F10 = 0x79
      VK_F11 = 0x7a
      VK_F12 = 0x7b

      class KeyboardInput < FFI::Struct
        layout(:vk, :ushort,
               :scan, :ushort,
               :flags, :uint,
               :time, :uint,
               :extra_info, :pointer)
      end

      class InputEvent < FFI::Union
        layout :ki, KeyboardInput

        class Input < FFI::Struct
          layout(:type, :uint,
                 :evt, InputEvent)
        end

        ffi_lib 'user32'
        ffi_convention :stdcall

        attach_function :SendInput, [:uint, :pointer, :int], :uint
      end
    end

    TRANSLATE_KEYS = {
      'BackSpace' => Win::VK_BACK,
      'Tab' => Win::VK_TAB,
      'Return' => Win::VK_RETURN,
      'Shift_L' => Win::VK_SHIFT,
      'Shift_R' => Win::VK_SHIFT,
      'Control_L' => Win::VK_CONTROL,
      'Control_R' => Win::VK_CONTROL,
      'space' => Win::VK_SPACE,
      'Left' => Win::VK_LEFT,
      'Up' => Win::VK_UP,
      'Right' => Win::VK_RIGHT,
      'Down' => Win::VK_DOWN,
      'F1' => Win::VK_F1,
      'F2' => Win::VK_F2,
      'F3' => Win::VK_F3,
      'F4' => Win::VK_F4,
      'F5' => Win::VK_F5,
      'F6' => Win::VK_F6,
      'F7' => Win::VK_F7,
      'F8' => Win::VK_F8,
      'F9' => Win::VK_F9,
      'F10' => Win::VK_F10,
      'F11' => Win::VK_F11,
      'F12' => Win::VK_F12
    }
  end

  class Plugin
    include Cinch::Plugin

    listen_to :connect, method: :on_connect
    listen_to :message, method: :on_message

    def initialize(*args)
      super
      @keys = config[:keys]
      @democracy_votes = 0
      @anarchy_votes = 0
      @democracy_mode = config[:start_in_democracy]
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
      @democracy_mode = true
      puts '---STARTING DEMOCRACY MODE---'
      @voting_thread = Thread.new do
        while @democracy_mode
          @button_votes.clear
          @total_votes = 0
          sleep @voting_time
          next if @total_votes == 0
          out = 'VOTES:'
          percentages = @button_votes.sort {|(_, count1), (_, count2)|
            count1 <=> count2
          }.first(5).map {|(btn, count)|
            [btn, count.to_f / @total_votes * 100]
          }.each {|(btn, percent)|
            out << format_log_line(btn, "#{percent}%")
          }
          puts out
          winner = @button_votes.max_by {|(_, count)| count}
          next if winner.nil?
          press(@keys[winner[0]])
        end
      end
    end

    def start_anarchy
      @democracy_mode = false
      @voting_thread.join
      puts '---STARTING ANARCHY MODE---'
    end

    case RbConfig::CONFIG['host_os']
    when /linux/
      def press(key)
        `xdotool key #{key}`
      end
    when /win/
      def press(key)
        input = Win::Input.new
        input[:type] = Win::INPUT_KEYBOARD
        evt = input[:evt][:ki]
        evt.vk = TRANSLATE_KEYS[key] || key.upcase.ord
        evt.scan = 0
        evt.flags = 0
        evt.time = 0
        evt.extra_info = 0
        Win.SendInput(1, [input], Win::Input.size)
      end
    end

    def format_log_line(name, command)
      "#{name}#{' ' * (@log_line_length - name.length - command.length)}#{command}"
    end

    def on_connect(msg)
      if @use_savestates
        @savestate_thread = Thread.new do
          loop do
            sleep @savestate_interval
            press(@keys[:save_state])
          end
        end
      end
    end

    def on_message(msg)
      message = msg.message
      case message
      when /^anarchy$/i
        puts format_log_line(msg.user.nick, message.downcase)
        @anarchy_votes += 1
        if @democracy_mode && calculate_ratio <= @anarchy_ratio_needed
          start_anarchy
        end
      when /^democracy$/i
        puts format_log_line(msg.user.nick, message.downcase)
        @democracy_votes += 1
        if !@democracy_mode && calculate_ratio >= @democracy_ratio_needed
          start_democracy
        end
      when /^up|down|left|right|a|b|x|y|l|r|start|select$/i
        btn = $&.to_sym
        if @democracy_mode
          @total_votes += 1
          @button_votes[btn] += 1
          return
        end
        puts format_log_line(msg.user.nick, $&.downcase)
        press(@keys[btn])
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
