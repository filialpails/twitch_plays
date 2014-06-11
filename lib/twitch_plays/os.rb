module TwitchPlays
  case RbConfig::CONFIG['host_os']
  when /win/
    require_relative 'os/win'
    Output = OS::Win
  when /linux/
    require_relative 'os/x11'
    Output = OS::X11
  end
end
