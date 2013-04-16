svn delete vendor/cache/widget_list-$1.gem vendor/bundle/ruby/1.9.1/cache/widget_list-$1.gem vendor/bundle/ruby/1.9.1/specifications/widget_list-$1.gemspec vendor/bundle/ruby/1.9.1/gems/widget_list-$1

grep -rl '"widget_list", "'$1'"' Gemfile | xargs sed -i 's/"widget_list", "'$1'"/"widget_list", "'$2'"/g'

bundle install

svn add vendor/cache/widget_list-$2.gem vendor/bundle/ruby/1.9.1/cache/widget_list-$2.gem vendor/bundle/ruby/1.9.1/specifications/widget_list-$2.gemspec vendor/bundle/ruby/1.9.1/gems/widget_list-$2

echo -e -n  "Please test your solution and press enter to checkin new gem" 
read THEMENAME


svn commit vendor/cache/widget_list-$1.gem vendor/bundle/ruby/1.9.1/cache/widget_list-$1.gem vendor/bundle/ruby/1.9.1/specifications/widget_list-$1.gemspec vendor/bundle/ruby/1.9.1/gems/widget_list-$1 vendor/cache/widget_list-$2.gem vendor/bundle/ruby/1.9.1/cache/widget_list-$2.gem vendor/bundle/ruby/1.9.1/specifications/widget_list-$2.gemspec vendor/bundle/ruby/1.9.1/gems/widget_list-$2 Gemfile.lock Gemfile -m "$1 -> $2 gem update"
