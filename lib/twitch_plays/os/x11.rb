module TwitchPlays
  module OS
    module X11
      def self.press(key)
        `xdotool key #{key}`
      end

      def self.touch_move(dx, dy)
        `xdotool mousemove_relative --sync -- #{dx} #{dy}`
      end

      def self.touch_press
        `xdotool mousedown 1`
      end

      def self.touch_release
        `xdotool mouseup 1`
      end
    end
  end
end
