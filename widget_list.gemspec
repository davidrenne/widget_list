# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'widget_list/version'

Gem::Specification.new do |gem|

  gem.name          = "widget_list"
  
  gem.version       = WidgetList::VERSION
  
  gem.authors       = ["David Renne"]
  
  gem.email         = ["message_me_on_github@dave.com"]
  
  gem.description   = %q{An Advanced and flexible ajax data grid. Supports several databases where data is pulled from either using Sequel ORM (optional even though is a dependency), Active Record Models or Raw SQL.}
  
  gem.summary       = %q{In rails you have will_paginate and other gems like it using the ActiveRecord approach, but widget_list adds some awesome treats to standard boring pagers}
  
  gem.homepage      = "https://github.com/davidrenne/widget_list"
  
  #
  # SEQUEL IS NOW OPTIONAL!! I am sure most people will be using ActiveRecord ORM
  # I am including it as a dependency just because it is easier to pull it down and have it available
  #
  gem.add_dependency('sequel', '3.42.0')

  gem.add_dependency('ransack', '0.7.2')
  
  gem.files         = `git ls-files`.split($/)
  
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  
  gem.require_paths = ["lib"]
  
end
