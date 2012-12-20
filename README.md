widget_list
====================
# WidgetList

## Introduction

This is my first gem ever!

I feel like there are not very good lists in ruby/rails and/or dont care to find any because nothing will compare to widget_list's implementation.

In rails you have will_paginate and other ones like it using the ActiveRecord approach, but widget_list adds some awesome treats to standard boring pagers:

* A sleek ajaxified list
* Full sorting
* Search bar/Ajax searching
* Column mappings
* Buttons for each row and areas on the bottom of the grid where you can add "Action buttons" like Add R


## Installation

Add this line to your application's Gemfile:

    gem 'widget_list'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install widget_list

## Usage

### #1 - Add widget_list CSS and JS to your application css and js

    Change application.css to:

    *= require widget_list
    *= require widgets

    Change application.js to:

    //= require widget_list

### #2 - Run bundle exec rails s to have widget_list create config/widget-list.yml

    Change application.css to:

    *= require widget_list
    *= require widgets

    Change application.js to:

    //= require widget_list

### Example Calling Page That Sets up Config and calls WidgetList.render

    #
    # Load Sample "items" Data. Comment out in your first time executing a widgetlist to create the items table
    #

    # no table - create it and load it with 5K records
    WidgetList::List.get_database.create_table :items do
      primary_key :id
      String :name
      Float :price
    end
    items = WidgetList::List.get_database[:items]
    100.times {
      items.insert(:name => 'abc', :price => rand * 100)
      items.insert(:name => '123', :price => rand * 100)
      items.insert(:name => 'asdf', :price => rand * 100)
      items.insert(:name => 'qwerty', :price => rand * 100)
      items.insert(:name => 'poop', :price => rand * 100)
    }


    #
    # Setup your first widget_list
    #

    button_column_name = 'actions'
    list_parms   = {}

    #
    # action_buttons will add buttons to the bottom of the list.
    #

    action_buttons =  WidgetList::Widgets::widget_button('Add New Item', {'page' => '/add/'} ) + WidgetList::Widgets::widget_button('Do something else', {'page' => '/else/'} )

    #
    # Give it a name, some SQL to feed widget_list and set a noDataMessage
    #
    list_parms['name']          = 'ruby_items_yum'
    list_parms['view']          = '(SELECT \'\'  as checkbox,a.* FROM items a ) a'
    list_parms['noDataMessage'] = 'No Tables Found'
    list_parms['title']         = 'Ruby Items!!!'

    #
    # Create small button array and pass to the buttons key
    #

    mini_buttons = {}
    mini_buttons['button_edit'] = {'page'       => '/edit',
                              'text'       => 'Edit',
                              'function'   => 'Redirect',
                              #pass tags to pull from each column when building the URL
                              'tags'       => {'my_key_name' => 'name','value_from_database'=>'price'}}

    mini_buttons['button_delete'] = {'page'       => '/delete',
                                'text'       => 'Delete',
                                'function'   => 'alert',
                                'innerClass' => 'danger'}
    list_parms['buttons']                                            = {button_column_name => mini_buttons}
    list_parms['function']                                           = {button_column_name => "'' " + button_column_name }
    list_parms['groupByItems']= ['All Records','Another Grouping Item']

    #
    # Generate a template for the DOWN ARROW for CUSTOM FILTER
    #

    template = {}
    input = {}

    input['id']          = 'comments'
    input['name']        = 'comments'
    input['width']       = '170'
    input['max_length']  = '500'
    input['input_class'] = 'info-input'
    input['title']       = 'Optional CSV list'

    button_search = {}
    button_search['innerClass']   = "success btn-submit"
    button_search['onclick']      = "alert('This would search, but is not coded.  That is for you to do')"

    list_parms['list_search_form'] = WidgetList::Utils::fill( {
                              '<!--COMMENTS-->'            => WidgetList::Widgets::widget_input(input),
                              '<!--BUTTON_SEARCH-->'       => WidgetList::Widgets::widget_button('Search', button_search),
                              '<!--BUTTON_CLOSE-->'        => "HideAdvancedSearch(this)" } ,
    '
    <div id="advanced-search-container">
    <div class="widget-search-drilldown-close" onclick="<!--BUTTON_CLOSE-->">X</div>
      <ul class="advanced-search-container-inline" id="search_columns">
        <li>
           <div>Search Comments</div>
           <!--COMMENTS-->
        </li>
      </ul>
    <br/>
    <div style="text-align:right;width:100%;height:30px;" class="advanced-search-container-buttons"><!--BUTTON_RESET--><!--BUTTON_SEARCH--></div>
</div>')

    #
    # Setup a custom field for checkboxes stored into the session and reloaded when refresh occurs
    #

    list_parms.deep_merge!({'fields' =>
                    {
                      'checkbox'=> 'checkbox_header',
                      'id'=> 'Item Id',
                      'name'=> 'Name',
                      'price'=> 'Price of Item',
                      button_column_name => button_column_name.capitalize,
                    }
                 })

    list_parms.deep_merge!({'inputs' =>
                          {'checkbox'=>
                             {'type' => 'checkbox'
                             }
                          }
                       })

    list_parms.deep_merge!({'inputs' =>
                          {'checkbox'=>
                             {'items' =>
                               {
                                 'name'          => 'visible_checks[]',
                                 'value'         => 'id', #the value should be a column name mapping
                                 'class_handle'  => 'info_tables',
                               }
                             }
                          }
                       })

    list_parms.deep_merge!({'inputs' =>
                          {'checkbox_header'=>
                             {'type' => 'checkbox'
                             }
                          }
                       })

    list_parms.deep_merge!({'inputs' =>
                          {'checkbox_header'=>
                             {'items' =>
                               {
                                 'check_all'     => true,
                                 'id'            => 'info_tables_check_all',
                                 'class_handle'  => 'info_tables',
                               }
                             }
                          }
                       })

    list = WidgetList::List.new(list_parms)

    #
    # If AJAX, send back JSON
    #
    if $_REQUEST.key?('BUTTON_VALUE') && $_REQUEST['LIST_NAME'] == list_parms['name']
      ret = {}
      ret['list']     = WidgetList::Utils::fill({ '<!--CUSTOM_CONTENT-->' =>  action_buttons } , list.render() )
      ret['list_id']  = list_parms['name']
      ret['callback'] = 'ListSearchAheadResponse'
      return render :inline => WidgetList::Utils::json_encode(ret)
    else
      #
      # Else assign to variable for view
      #
      @output = WidgetList::Utils::fill({ '<!--CUSTOM_CONTENT-->' =>  action_buttons } , list.render() )
    end

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request


Meta
----

* Gems: <http://rubygems.org/gems/widget-list>


Authors
-------

David Renne :: david_renne @ ya hoo - .com :: @phpnerd

License
-------

Copyright 2012 David Renne

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
