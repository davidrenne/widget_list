# WidgetList
====================

## Introduction

This is my first gem ever!

I feel like there are not very good lists in ruby/rails and/or dont care to find any because nothing will compare to widget_list's implementation.

In rails you have will_paginate and other ones like it using the ActiveRecord approach, but widget_list adds some awesome treats to standard boring pagers:

* A sleek ajaxified list
* Supports *ALL Databases (Haven't tested everything yet though, I am sure there are tweaks for each DB)
*    mysql tested (basic example)
*    postgres tested (basic example)
*    oracle tested (basic example)
*    sqllite tested (basic example)
* Full sorting ASC/DESC of list via ajax
* Easily add row level buttons for each row
* Custom tags to pass to be replaced by actual data from each column/value
* Search bar/Ajax searching
* Column mappings and names
* Checkboxes for each row for custom selection and mass actions
* Session rememberance for each list/view of what was last sorted, which page the person was on, the limit and search filters
* Ability to set a cool custom HTML arrow which draws a hidden DIV intended for someone to put custom widgets inside of to pass new filters to the list before it executes
* Buttons for each row and areas on the bottom of the grid where you can add "Action buttons"

## Screenshots

Main Example Loaded:
![](http://davidrenne.com/github/widget_list/main.png)

Filter Drop Downs:
![](http://davidrenne.com/github/widget_list/filtered.png)

Searching a row:
![](http://davidrenne.com/github/widget_list/search.png)


## Installation

Add this line to your application's Gemfile:

    gem 'widget_list'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install widget_list

## Usage/Examples

You can either follow the below instructions or take a look at the changes here https://github.com/davidrenne/widget_list_example/commit/e4e8ab54edcf8bc4538b1850ee762c13bc6f5316

### #1 - Add widget_list CSS and JS to your application css and js

    Change application.css to:

    *= require widget_list
    *= require widgets

    Change application.js to:

    //= require widget_list

### #2 - Run `bundle exec rails s` to have widget_list create config/widget-list.yml (by default a sqlite3 memory database is created)

    Configure your connection settings for your primary or secondary widget_list connections.

    http://sequel.rubyforge.org/rdoc/files/doc/opening_databases_rdoc.html

### #3 - If you wish to integrate into an existing rails application create a new controller
    
    rails generate controller WidgetListExamples ruby_items

  Then modify app/views/widget_list_examples/ruby_items.html.erb and add 
    <div style="margin:50px;">
      <%=raw @output%>
    </div>
  
  Add config/routes.rb if it is not in there:
    match ':controller(/:action)'
  
  Add the example shown below to app/controllers/widget_list_examples_controller.rb#ruby_items
  
  Go To http://localhost:3000/widget_list_examples/ruby_items

### Example Calling Page That Sets up Config and calls WidgetList.render

   
    WidgetList::List.get_database.create_table :items do
      primary_key :id
      String :name
      Float :price
      Int :sku
      Date :date_added
    end
    items = WidgetList::List.get_database[:items]
    100.times {
      items.insert(:name => 'abc', :price => rand * 100, :date_added => '2008-02-01', :sku => 12345)
      items.insert(:name => '123', :price => rand * 100, :date_added => '2008-02-02', :sku => 54321)
      items.insert(:name => 'asdf', :price => rand * 100, :date_added => '2008-02-03', :sku => 67895)
      items.insert(:name => 'qwerty', :price => rand * 100, :date_added => '2008-02-04', :sku => 66666)
      items.insert(:name => 'poop', :price => rand * 100, :date_added => '2008-02-05', :sku => 77777)
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
    list_parms['searchIdCol']   = ['id','sku']
    list_parms['view']          = '(SELECT \'\'  as checkbox,a.* FROM items a ) a'
    list_parms['noDataMessage'] = 'No Ruby Items Found'
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
    list_parms['fieldFunction']                                      = {
                                                                          button_column_name => "''",
                                                                          'date_added'  => ['postgres','oracle'].include?(WidgetList::List.get_database.db_type) ? "TO_CHAR(date_added, 'MM/DD/YYYY')" : "date_added"
                                                                       }
    list_parms['groupByItems']    = ['All Records','Item Name']

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
    # Map out the visible fields
    #

    list_parms.deep_merge!({'fields' =>
                    {
                      'checkbox'=> 'checkbox_header',
                    }
                 })
                 
    list_parms.deep_merge!({'fields' =>
                    {
                      'id'=> 'Item Id',
                    }
                 })
                 
    list_parms.deep_merge!({'fields' =>
                    {
                      'name'=> 'Name',
                    }
                 })
                 
    list_parms.deep_merge!({'fields' =>
                    {
                      'price'=> 'Price of Item',
                    }
                 })
                 
                 
    list_parms.deep_merge!({'fields' =>
                    {
                      'sku'=> 'Sku #',
                    }
                 })
                 
    list_parms.deep_merge!({'fields' =>
                    {
                      'date_added'=> 'Date Added',
                    }
                 })
 
    list_parms.deep_merge!({'fields' =>
                    {
                      button_column_name => button_column_name.capitalize,
                    }
                 })
                 
    #
    # Setup a custom field for checkboxes stored into the session and reloaded when refresh occurs
    #

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
      @output =  WidgetList::Utils::fill({ '<!--CUSTOM_CONTENT-->' =>  action_buttons } , list.render() )
    end

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request


Meta
----

* Gems: <https://rubygems.org/gems/widget_list>


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
