# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'widget_list/version'

Gem::Specification.new do |gem|

  gem.name          = "widget_list"

  gem.licenses      = ['MIT']
  
  gem.version       = WidgetList::VERSION
  
  gem.authors       = ["David Renne"]
  
  gem.email         = ["widgetlist@davidrenne.com"]
  
  gem.description   = %q{Build interactive data tables in Rails from Sequel SQL queries or Active Record relations. widget_list handles sorting, search, pagination, Ajax updates, and CSV export. Configure columns in Ruby and add advanced filters with Ransack.}
  
  gem.summary       = %q{Rails data grids with Ajax search, sorting, pagination, and CSV export}
  gem.required_ruby_version = '>= 3.2'
  
  gem.homepage      = "https://github.com/davidrenne/widget_list"
  
  gem.add_dependency('sequel', '5.109.0')

  gem.add_dependency('ransack', '5.0.2')
  gem.add_dependency('csv', '~> 3.3')
  gem.metadata['rubygems_mfa_required'] = 'true'
  
  gem.files         = `git ls-files`.split($/)
  
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  
  gem.require_paths = ["lib"]
  
end
