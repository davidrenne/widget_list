#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"
version=$(ruby -Ilib -rwidget_list/version -e 'print WidgetList::VERSION')
gem build widget_list.gemspec --output "widget_list-${version}.gem"

example_dir="../widget_list_example_rails8"
if [[ -f "${example_dir}/bin/rails" ]]; then
  (cd "$example_dir" && bundle install && bin/rails test)
fi

printf 'Built widget_list-%s.gem. Review git diff and commit on main before publishing.\n' "$version"
