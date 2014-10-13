module TwitchPlays
  case RbConfig::CONFIG['host_os']
  when /mswin|mingw|cygwin/
    require_relative 'os/win'
    Output = OS::Win
  when /linux|darwin/
    require_relative 'os/x11'
    Output = OS::X11
  end
end
