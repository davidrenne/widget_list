#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"
if [[ "$(git branch --show-current)" != main ]]; then
  echo 'Publish from the main branch.' >&2
  exit 1
fi
if [[ -n "$(git status --porcelain)" ]]; then
  echo 'Commit changes before publishing.' >&2
  exit 1
fi

version=$(ruby -Ilib -rwidget_list/version -e 'print WidgetList::VERSION')
gem build widget_list.gemspec --output "widget_list-${version}.gem"
gem push "widget_list-${version}.gem"
