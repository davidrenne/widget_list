# WidgetList
====================

## Introduction

This is my first gem ever!

I feel like there are not very good lists in ruby/rails and/or dont care to find any because nothing will compare to widget_list's implementation.

In rails you have will_paginate and other ones like it using the ActiveRecord approach, but widget_list adds some awesome treats to standard boring pagers:

* A sleek ajaxified list
* Supports *ALL Databases (Haven't tested everything yet though, I am sure there are tweaks for each DB). mysql, postgres, oracle and sqllite tested (basic example)
* Full sorting ASC/DESC of list via ajax
* Easily add row level buttons for each row
* Custom tags to pass to be replaced by actual data from each column/value
* Search bar/Ajax searching
* Column mappings and names
* Checkboxes for each row for custom selection and mass actions
* Session rememberance for each list/view of what was last sorted, which page the person was on, the limit and search filters
* Ability to set a cool custom HTML arrow which draws a hidden DIV intended for someone to put custom widgets inside of to pass new filters to the list before it executes
* Buttons for each row and areas on the bottom of the grid where you can add "Action buttons"
* Export visible data as CSV

## Screenshots

Main Example Loaded:
![](http://davidrenne.com/github/widget_list/main.png)

Filter Drop Downs:
![](http://davidrenne.com/github/widget_list/filtered.png)

Searching a row:
![](http://davidrenne.com/github/widget_list/search.png)


## Installation

Add this line to your application's Gemfile:

```ruby
    gem 'widget_list'
```
And then execute:
```ruby
    $ bundle
```
Or install it yourself as:
```ruby
    $ gem install widget_list
```
## Usage/Examples

You can either follow the below instructions or take a look at the changes here https://github.com/davidrenne/widget_list_example/commit/e4e8ab54edcf8bc4538b1850ee762c13bc6f5316

I recommend if you use widget_list in production that you use config.consider_all_requests_local = true as errors will be handled but the base lists will still draw.


## Feature Configurations

widget_list features and configurations primarily work by a single large hash passed to the constructor with the features you need for the given request which changes how the list is displayed or filtered.

`name` - The unique name/id's of all the pieces that make up your widget list `default=([*('A'..'Z'),*('0'..'9')]-%w(0 1 I O)).sample(16).join`

`database` - You can pass which DB connection you would like to use for each list.  Only two values/db connections are supported ('primary' or 'secondary') `default='primary'`

`title` - This adds an H1 title and horizontal rule on top of your list `default=''`

`listDescription` - This adds a grey header box.  It is useful for describing the main query `default=''`

`pageId` - Base path for requests (typically you never need to change this) `default=$_SERVER['PATH_INFO']`

`view` - A sub-select query to your database (ALWAYS ALIASED) `default=''`

`data` - A "sequel" formatted resultset like would be returned from _select() method.  Instead of running a SQL query, you can pass an array to populate the list `default={}`

`collClass` - Your custom <td> class for all <td>'s `default=''`

`align` - <td> align attribute for all <td>'s `default=''`

`fields` - The visible fields shown in the current list.  KEY=column name VALUE= displayed column header `default={}`

`fieldsHidden` - The non-visible fields in the current list.  Typically used when you wish to search on this column, but the main column is a drilldown or some HTML value that isnt easily searchable.  VALUE=column name `default=[]`

`bindVars` - bindVars that are passed to _select() sequel extension I wrote.  Which will replace "?" in your query with the associated bindVar `default=[]`

`bindVarsLegacy` - A Hash whose KEYS ARE CAPITALIZED and whose value is the replacement string.  Inside the "view" you would use :MY_KEY as the template to be replaced `default={}`

`links` - Turn text based record value into a link.  KEY=column name VALUE=hash of link Config.  Links should most likely pass ['tags']['field_name'] = 'get_var_name' (would yeild get_var_name=1234 for that field value 1234).  You can pass ['tags']['onclick'] if you dont want to call ButtonLinkPost which will redirect to the URL built.  If you pass ['onclick']['tags'], each field passed will be passed as a parameter for the function you designate   `default={}`

`buttons` -  Buttons to generate for each row.  KEY=column name VALUE=Hash of widget_button attributes `default={}`

`inputs` -  widget_check is the only one supported so far. (See examples) `default={}`

`filter` - << "xxx = 123" would be the syntax to add a new filter array. (See examples) `default=[]`

`groupBy` - The column name or CSV of names to group by. (See examples) `default=[]`

`rowStart` - Which page the list should start at `default=0`

`rowLimit` - How many rows per page? `default=10`

`orderBy` -  Default order by "column_name DIRECTION" `default=''`

`allowHTML` - Strip HTML from view or not `default=true`

`strlength` - Strip HTML from view or not `default=true`

`searchClear` - Clear the list's search session `default=false`

`searchClearAll` - Clear all search session for all lists `default=false`

`showPagination` - Show pagination HTML `default=true`

`searchSession` - Remember and restore the last search performed `default=true`

`carryOverRequests` -  will allow you to post custom things from request to all sort/paging URLS for each ajax.  Takes an array of GETVARS which will be passed to each request `default=['switch_grouping']`

`customFooter` -  Add buttons or HTML at bottom area of list inside the grey box `default=''`

`customHeader` -  Add buttons or HTML at top area of list above all headers (such as TABS to delineate Summary/Details) `default=''`

`ajaxFunctionAll` -  Custom javascript called asychronously during each click of each event someone interacts with on the list `default=''`

`ajaxFunction` -  Mostly an internal setting `default='ListJumpMin'`

`showSearch` -  Show top search bar `default=true`

`searchOnkeyup` -  Search on key up event `default=''`

`searchOnclick` -  Search on click event `default=''`

`searchIdCol` - By default `id` column is here because typically if you call your PK's id and are auto-increment and numeric.  This can also take in an array of numeric fields so that users can search CSV's of numbers and get back matches `default='id'`

`searchTitle` -  Set a title for the search input `default= 'Search by Id or a list of Ids and more'`

`searchFieldsIn` -  White list of fields to include in a alpha-numeric based like '%%' search  `default={}`

`searchFieldsOut` - Black list of fields to exclude in a alpha-numeric based search `default={'id'=>true}`

`showExport` - Allow users to export current list view as CSV `default=true`

`exportButtonTitle` - Title of button `default='Export CSV'`

`groupByItems` - Custom drop down's created by passing an array of modes.  Best suited to group by the data `default=[]`

`groupBySelected` - Initially selected grouping - defaults to first in list if not.  Please pass the string value of the "groupByItem" `default=false`

`groupByLabel` -  Label describing select box `default='Group By'`

`groupByClick` -  Function to call as a custom function for each click on an item `default=''`

`groupByClickDefault` -  Default group by handler inside widget_list.js `default="ListChangeGrouping('<!--NAME-->', this);"`

`listSearchForm` -  Allows you to pass a custom form for the ARROW drop down for advanced searching `default=''`

`columnStyle` -  Column styles.  KEY=column name VALUE= the inline style applied `default={}`

`columnClass` -  Column class.  KEY=column name VALUE= the class name `default={}`

`columnPopupTitle` -  Column title as you hover over.  KEY=column name VALUE=Popup text `default={}`

`columnWidth` -  Column widths.  KEY=column name VALUE= '100px' `default={}`

`columnNoSort` - Dont allow sorting on these columns (By default all visible columns have a sort link built).  KEY=column name VALUE=column name `default={}`

`borderedColumns` - Add a right border to each column. `default=false`

`borderColumnStyle` - Style of row if you use this above feature. `default='1px solid #CCCCCC'`
 
`rowClass` - Class added to all rows `default=''`

`rowColorByStatus` - {'rowColorByStatus' =>
                                {'active'=>
                                   {'No'  => '#EBEBEB' }
                                }
                     } 
Color a row based on the value of the column.
`default={}`

`rowStylesByStatus` -  {'rowStylesByStatus' =>
                                {'active'=>
                                   {'No'  => 'font-style:italic;color:red;' }
                                }
                             }
Style a row based on the value of the column.
`default={}`

`rowOffsets` - Color for each row and offset `default=['FFFFFF','FFFFFF']`

`noDataMessage` - Message to show when no data is found `default='Currently no data.'`

`useSort` - Allow sorting on list `default=true`

`headerClass` - Class of each individual header column `default={}`

`fieldFunction` - A way to wrap or inject columns or SQL formatting in place of your columns `default={}`

`template` - Pass in a custom template for outer shell `default=''`

`templateFilter` - Instead of widget list building your search box.  Pass your own HTML `default=''`

`storeSessionChecks` - See http://stackoverflow.com/questions/1928204/marshal-data-too-short for configuring larger session storage which checkboxes would eat up if you had this set to true `default=false`

`columnHooks` - Todo `default={}`

`rowHooks` - Todo `default={}`


### #1 - Add widget_list CSS and JS to your application css and js

    Change application.css to:
```ruby
    *= require widget_list
    *= require widgets
```
    Change application.js to:
```ruby
    //= require widget_list
```
### #2 - Run `bundle exec rails s` to have widget_list create config/widget-list.yml (by default a sqlite3 memory database is created)

    Configure your connection settings for your primary or secondary widget_list connections.

    http://sequel.rubyforge.org/rdoc/files/doc/opening_databases_rdoc.html

### #3 - If you wish to integrate into an existing rails application create a new controller
    
    rails generate controller WidgetListExamples ruby_items

  Then modify app/views/widget_list_examples/ruby_items.html.erb and add 
```ruby
   <div style="margin:50px;">
      <%=raw @output%>
    </div>
```  
  Add config/routes.rb if it is not in there:
```ruby
  match ':controller(/:action)'
```
  Ensure that sessions are loaded into active record because widget_list keeps track of several settings on each list for each session
```ruby
  config.session_store :active_record_store
```  
  Add the example shown below to app/controllers/widget_list_examples_controller.rb#ruby_items
  
  Go To http://localhost:3000/widget_list_examples/ruby_items

### Example Calling Page That Sets up Config and calls WidgetList.render

   
```ruby
    #
    # Load Sample "items" Data. Comment out in your first time executing a widgetlist to create the items table
    #
=begin
    begin
      WidgetList::List.get_sequel.create_table :items do
        primary_key :id
        String :name
        Float :price
        Fixnum :sku
        String :active
        Date :date_added
      end
      items = WidgetList::List.get_sequel[:items]
      100.times {
        items.insert(:name => 'ab\'c_quoted_'    + rand(35).to_s,   :price => rand * 100, :date_added => '2008-02-01', :sku => rand(9999), :active => 'Yes')
        items.insert(:name => '12"3_'            + rand(35).to_s,   :price => rand * 100, :date_added => '2008-02-02', :sku => rand(9999), :active => 'Yes')
        items.insert(:name => 'asdf_'            + rand(35).to_s,   :price => rand * 100, :date_added => '2008-02-03', :sku => rand(9999), :active => 'Yes')
        items.insert(:name => 'qwerty_'          + rand(35).to_s,   :price => rand * 100, :date_added => '2008-02-04', :sku => rand(9999), :active => 'No')
        items.insert(:name => 'meow_'            + rand(35).to_s,   :price => rand * 100, :date_added => '2008-02-05', :sku => rand(9999), :active => 'No')
      }
    rescue Exception => e
      #
      # Table already exists
      #
      logger.info "Test table in items already exists? " + e.to_s
    end
=end

    begin

      list_parms   = WidgetList::List::init_config()

      #
      # Give it a name, some SQL to feed widget_list and set a noDataMessage
      #
      list_parms['name']          = 'ruby_items_yum'

      #
      # Handle Dynamic Filters
      #
      if $_REQUEST.key?('switch_grouping') && $_REQUEST['switch_grouping'] == 'Item Name'
        groupByFilter                  = 'item'
        countSQL                       = 'COUNT(1) as cnt,'
        groupBySQL                     = 'GROUP BY name'
        groupByDesc                    = ' (Grouped By Name)'
      elsif  $_REQUEST.key?('switch_grouping') && $_REQUEST['switch_grouping'] == 'Sku Number'
        groupByFilter                  = 'sku'
        countSQL                       = 'COUNT(1) as cnt,'
        groupBySQL                     = 'GROUP BY sku'
        groupByDesc                    = ' (Grouped By Sku Number)'
      else
        groupByFilter                  = 'none'
        countSQL                       = ''
        groupBySQL                     = ''
        groupByDesc                    = ''
      end

      list_parms['filter']    = []
      list_parms['bindVars']  = []
      drillDown, filterValue  = WidgetList::List::get_filter_and_drilldown(list_parms['name'])

      case drillDown
        when 'filter_by_name'
          list_parms['filter']   << " name = ? "
          list_parms['bindVars'] << filterValue
          list_parms['listDescription']   = WidgetList::List::drill_down_back(list_parms['name']) + ' Filtered by Name (' + filterValue + ')' + groupByDesc
        when 'filter_by_sku'
          list_parms['filter']   << " sku = ? "
          list_parms['bindVars'] << filterValue
          list_parms['listDescription']   = WidgetList::List::drill_down_back(list_parms['name']) + ' Filtered by SKU (' + filterValue + ')' + groupByDesc
        else
          list_parms['listDescription']   = ''
          list_parms['listDescription']   = WidgetList::List::drill_down_back(list_parms['name']) if !groupByDesc.empty?
          list_parms['listDescription']  += 'Showing All Ruby Items' + groupByDesc
      end

      # put <%= @output %> inside your view for initial load nothing to do here other than any custom concatenation of multiple lists
      #
      # Setup your first widget_list
      #

      button_column_name = 'actions'

      #
      # customFooter will add buttons to the bottom of the list.
      #

      list_parms['customFooter'] =  WidgetList::Widgets::widget_button('Add New Item', {'page' => '/add/'} ) + WidgetList::Widgets::widget_button('Do something else', {'page' => '/else/'} )

      #
      # Give some SQL to feed widget_list and set a noDataMessage
      #
      list_parms['searchIdCol']   = ['id','sku']

      #
      # Because sku_linked column is being used and the raw SKU is hidden, we need to make this available for searching via fields_hidden
      #
      list_parms['fieldsHidden'] = ['sku']

      drill_downs = []

      drill_downs << WidgetList::List::build_drill_down( :list_id                => list_parms['name'],
                                                         :drill_down_name        => 'filter_by_name',
                                                         :data_to_pass_from_view => 'a.name',
                                                         :column_to_show         => 'a.name',
                                                         :column_alias           => 'name_linked'
                                                       )

      drill_downs << WidgetList::List::build_drill_down(
                                                         :list_id                => list_parms['name'],
                                                         :drill_down_name        => 'filter_by_sku',
                                                         :data_to_pass_from_view => 'a.sku',
                                                         :column_to_show         => 'a.sku',
                                                         :column_alias           => 'sku_linked'
                                                       )

      list_parms['view']          = '(
                                       SELECT
                                             ' + countSQL + '
                                             ' + drill_downs.join(' , ') + ',
                                             \'\'     AS checkbox,
                                             a.id         AS id,
                                             a.active     AS active,
                                             a.name       AS name,
                                             a.sku        AS sku,
                                             a.price      AS price,
                                             a.date_added AS date_added
                                         FROM
                                             items a
                                       ' + groupBySQL + '
                                     ) a'

      #
      # Map out the visible fields
      #
      list_parms['fields'] = {}
      list_parms['fields']['checkbox']         = 'checkbox_header'
      list_parms['fields']['cnt']              = 'Total Items In Group'         if groupByFilter != 'none'
      list_parms['fields']['id']               = 'Item Id'                      if groupByFilter == 'none'
      list_parms['fields']['name_linked']      = 'Name'                         if groupByFilter == 'none' or groupByFilter == 'item'
      list_parms['fields']['price']            = 'Price of Item'                if groupByFilter == 'none'
      list_parms['fields']['sku_linked']       = 'Sku #'                        if groupByFilter == 'none' or groupByFilter == 'sku'
      list_parms['fields']['date_added']       = 'Date Added'                   if groupByFilter == 'none'
      list_parms['fields']['active']           = 'Active Item'                  if groupByFilter == 'none'
      list_parms['fields'][button_column_name] = button_column_name.capitalize  if groupByFilter == 'none'


      list_parms['noDataMessage'] = 'No Ruby Items Found'
      list_parms['title']         = 'Ruby Items Using Sequel!!!'

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
        'date_added'  => ['postgres','oracle'].include?(WidgetList::List::get_db_type) ? "TO_CHAR(date_added, 'MM/DD/YYYY')" : "date_added"
      }

      list_parms['groupByItems']    = ['All Records', 'Item Name', 'Sku Number']


      #
      # Setup a custom field for checkboxes stored into the session and reloaded when refresh occurs
      #
      list_parms = WidgetList::List.checkbox_helper(list_parms,'id')

      #
      # Generate a template for the DOWN ARROW for CUSTOM FILTER
      #
      input = {}

      input['id']          = 'comments'
      input['name']        = 'comments'
      input['width']       = '170'
      input['max_length']  = '500'
      input['input_class'] = 'info-input'
      input['title']       = 'Optional CSV list'

      button_search = {}
      button_search['onclick']      = "alert('This would search, but is not coded.  That is for you to do')"

      list_parms['listSearchForm'] = WidgetList::Utils::fill( {
                                                                  '<!--BUTTON_SEARCH-->'       => WidgetList::Widgets::widget_button('Search', button_search),
                                                                  '<!--COMMENTS-->'            => WidgetList::Widgets::widget_input(input),
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
      </div>'
      # or to keep HTML out of controller render_to_string(:partial => 'partials/form_xxx')
      )

      #
      # Control widths of special fields
      #

      list_parms['columnWidth']    = {
        'date_added'=>'200px',
        'sku_linked'=>'20px',
      }

      #
      # If certain statuses of records are shown, visualize
      #

      list_parms.deep_merge!({'rowStylesByStatus' =>
                                {'active'=>
                                   {'Yes' => '' }
                                }
                             })
      list_parms.deep_merge!({'rowStylesByStatus' =>
                                {'active'=>
                                   {'No'  => 'font-style:italic;color:red;' }
                                }
                             })

      list_parms.deep_merge!({'rowColorByStatus' =>
                                {'active'=>
                                   {'Yes' => '' }
                                }
                             })
      list_parms.deep_merge!({'rowColorByStatus' =>
                                {'active'=>
                                   {'No'  => '#EBEBEB' }
                                }
                             })


      list_parms['columnPopupTitle'] = {}
      list_parms['columnPopupTitle']['checkbox']         = 'Select any record'
      list_parms['columnPopupTitle']['cnt']              = 'Total Count'
      list_parms['columnPopupTitle']['id']               = 'The primary key of the item'
      list_parms['columnPopupTitle']['name_linked']      = 'Name (Click to drill down)'
      list_parms['columnPopupTitle']['price']            = 'Price of item (not formatted)'
      list_parms['columnPopupTitle']['sku_linked']       = 'Sku # (Click to drill down)'
      list_parms['columnPopupTitle']['date_added']       = 'The date the item was added to the database'
      list_parms['columnPopupTitle']['active']           = 'Is the item active?'

      output_type, output  = WidgetList::List.build_list(list_parms)

      case output_type
        when 'html'
          # put <%= @output %> inside your view for initial load nothing to do here other than any custom concatenation of multiple lists
          @output = output
        when 'json'
          return render :inline => output
        when 'export'
          send_data(output, :filename => list_parms['name'] + '.csv')
          return
      end

    rescue Exception => e

      Rails.logger.info e.to_s + "\n\n" + $!.backtrace.join("\n\n")

      #really this block is just to catch initial ruby errors in setting up your list_parms
      #I suggest taking out this rescue when going to production
      output_type, output  = WidgetList::List.build_list(list_parms)

      case output_type
        when 'html'
          @output = output
        when 'json'
          return render :inline => output
        when 'export'
          send_data(output, :filename => list_parms['name'] + '.csv')
          return
      end

    end
```

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
