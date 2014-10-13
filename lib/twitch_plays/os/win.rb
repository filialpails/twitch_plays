require 'ffi'

module TwitchPlays
  module OS
    module Win
      module User32
        extend FFI::Library

        if FFI::Platform::ADDRESS_SIZE == 64
          LONG_PTR = :int64
          ULONG_PTR = :uint64
        else
          LONG_PTR = :long
          ULONG_PTR = :ulong
        end

        INPUT_MOUSE = 0x00
        INPUT_KEYBOARD = 0x01

        MOUSEEVENTF_MOVE = 0x01
        MOUSEEVENTF_LEFTDOWN = 0x02
        MOUSEEVENTF_LEFTUP = 0x04

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

        class MouseInput < FFI::Struct
          layout(:dx, :long,
                 :dy, :long,
                 :mouse_data, :ulong,
                 :flags, :ulong,
                 :time, :ulong,
                 :extra_info, ULONG_PTR)
        end

        class KeyboardInput < FFI::Struct
          layout(:vk, :ushort,
                 :scan, :ushort,
                 :flags, :ulong,
                 :time, :ulong,
                 :extra_info, ULONG_PTR)
        end

        class InputEvent < FFI::Union
          layout(:mi, MouseInput,
                 :ki, KeyboardInput)
        end

        class Input < FFI::Struct
          layout(:type, :ulong,
                 :evt, InputEvent)
        end

        ffi_lib 'user32'
        ffi_convention :stdcall

        attach_function :SendInput, [:uint, Input.ptr, :int], :uint
      end

      TRANSLATE_KEYS = {
        'BackSpace' => User32::VK_BACK,
        'Tab' => User32::VK_TAB,
        'Return' => User32::VK_RETURN,
        'Shift_L' => User32::VK_SHIFT,
        'Shift_R' => User32::VK_SHIFT,
        'Control_L' => User32::VK_CONTROL,
        'Control_R' => User32::VK_CONTROL,
        'space' => User32::VK_SPACE,
        'Left' => User32::VK_LEFT,
        'Up' => User32::VK_UP,
        'Right' => User32::VK_RIGHT,
        'Down' => User32::VK_DOWN,
        'F1' => User32::VK_F1,
        'F2' => User32::VK_F2,
        'F3' => User32::VK_F3,
        'F4' => User32::VK_F4,
        'F5' => User32::VK_F5,
        'F6' => User32::VK_F6,
        'F7' => User32::VK_F7,
        'F8' => User32::VK_F8,
        'F9' => User32::VK_F9,
        'F10' => User32::VK_F10,
        'F11' => User32::VK_F11,
        'F12' => User32::VK_F12
      }

      def self.press(key)
        input = User32::Input.new
        input[:type] = User32::INPUT_KEYBOARD
        evt = input[:evt][:ki]
        evt[:vk] = TRANSLATE_KEYS[key] || key.upcase.ord
        evt[:scan] = 0
        evt[:flags] = 0
        evt[:time] = 0
        evt[:extra_info] = 0
        User32.SendInput(1, input, User32::Input.size)
      end

      def self.touch_move(dx, dy)
        input = User32::Input.new
        input[:type] = User32::INPUT_MOUSE
        evt = input[:evt][:mi]
        evt[:dx] = dx
        evt[:dy] = dy
        evt[:mouse_data] = 0
        evt[:flags] = User32::MOUSEEVENTF_MOVE
        evt[:time] = 0
        evt[:extra_info] = 0
        User32.SendInput(1, input, User32::Input.size)
      end

      def self.touch_press
        input = User32::Input.new
        input[:type] = User32::INPUT_MOUSE
        evt = input[:evt][:mi]
        evt[:dx] = 0
        evt[:dy] = 0
        evt[:mouse_data] = 0
        evt[:flags] = User32::MOUSEEVENTF_LEFTDOWN
        evt[:time] = 0
        evt[:extra_info] = 0
        User32.SendInput(1, input, User32::Input.size)
      end

      def self.touch_release
        input = User32::Input.new
        input[:type] = User32::INPUT_MOUSE
        evt = input[:evt][:mi]
        evt[:dx] = 0
        evt[:dy] = 0
        evt[:mouse_data] = 0
        evt[:flags] = User32::MOUSEEVENTF_LEFTUP
        evt[:time] = 0
        evt[:extra_info] = 0
        User32.SendInput(1, input, User32::Input.size)
      end
    end
  end
end
