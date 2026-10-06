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
  
  gem.description   = %q{An Ajax data grid for Rails applications with Sequel SQL queries or Active Record relations.}
  
  gem.summary       = %q{Sortable, searchable, exportable data grids for Rails}
  gem.required_ruby_version = '>= 3.2'
  
  gem.homepage      = "https://github.com/davidrenne/widget_list"
  
  #
  # SEQUEL IS NOW OPTIONAL!! I am sure most people will be using ActiveRecord ORM
  # I am including it as a dependency just because it is easier to pull it down and have it available
  #
  gem.add_dependency('sequel', '5.109.0')

  gem.add_dependency('ransack', '5.0.2')
  gem.add_dependency('csv', '~> 3.3')
  gem.metadata['rubygems_mfa_required'] = 'true'
  
  gem.files         = `git ls-files`.split($/)
  
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  
  gem.require_paths = ["lib"]
  
end
