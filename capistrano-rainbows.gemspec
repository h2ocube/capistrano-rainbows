# -*- encoding: utf-8 -*-

Gem::Specification.new do |gem|
  gem.name        = 'capistrano-rainbows'
  gem.version     = '0.0.1'
  gem.author      = 'Ben'
  gem.email       = 'ben@h2ocube.com'
  gem.homepage    = 'https://github.com/h2ocube/capistrano-rainbows'
  gem.summary     = %q{Rainbows integration for Capistrano}
  gem.description = %q{Capistrano plugin that integrates Rainbows server tasks.}

  gem.files         = `git ls-files`.split("\n")
  gem.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  gem.executables   = `git ls-files -- bin/*`.split("\n").map{|f| File.basename(f)}
  gem.require_paths = ['lib']

  gem.add_development_dependency 'rake'

  gem.add_runtime_dependency 'capistrano'
end
