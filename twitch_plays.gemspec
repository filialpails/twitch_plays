require_relative 'lib/twitch_plays/version'

Gem::Specification.new do |s|
  s.name = 'twitch_plays'
  s.version = TwitchPlays::VERSION
  s.summary = 'Yet another Twitch Plays Pokemon clone.'
  s.description = 'MMO-ify any game over IRC.'

  s.author = 'Rob Steward'
  s.email = 'bobert_1234567890@hotmail.com'
  s.homepage = 'https://github.com/filialpails/twitch_plays'
  s.license = 'GPL-3.0+'

  s.files = Dir['README.md', 'LICENSE', 'example.config.yml', 'lib/**/*.rb', 'bin/*']
  s.bindir = 'bin'
  s.executables = ['twitch_plays']
  s.required_ruby_version = '~> 2.1'
  s.add_runtime_dependency 'cinch', '~> 2.1'
  s.add_runtime_dependency 'ffi', '~> 1.9'
end
