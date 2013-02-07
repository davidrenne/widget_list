# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'widget_list/version'

Gem::Specification.new do |gem|
  gem.name          = "widget_list"
  gem.version       = WidgetList::VERSION
  gem.authors       = ["David Renne"]
  gem.email         = ["message_me_on_github@dave.com"]
  gem.description   = %q{An Advanced and flexible ajax data grid.  Outside of all of the RAILS Active record CRAP!}
  gem.summary       = %q{In rails you have will_paginate and other gems like it using the ActiveRecord approach, but widget_list adds some awesome treats to standard boring pagers}
  gem.homepage      = "https://github.com/davidrenne/widget_list"
  gem.add_dependency('sequel', '3.42.0')  # SEQUEL IS NOW OPTIONAL!! I am sure most people will be using ActiveRecord ORM

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]
end
