# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'widget_list/version'

Gem::Specification.new do |gem|
  gem.name          = "widget_list"
  gem.version       = WidgetList::VERSION
  gem.authors       = ["Dave"]
  gem.email         = ["dave@dave.com"]
  gem.description   = %q{widgetlist desc}
  gem.summary       = %q{widgetlist summary}
  gem.homepage      = ""
  gem.add_dependency('sequel', '3.42.0')

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]
end
