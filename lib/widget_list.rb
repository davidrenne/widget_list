require 'widget_list/sequel'
require 'widget_list/version'
require 'widget_list/hash'
require 'widget_list/string'
require 'widget_list/utils'
require 'widget_list/tpl'
require 'widget_list/widgets'
require 'widget_list/railtie'
require 'csv'
require 'json'
require 'uri'
require 'extensions/action_controller_base'
require 'sequel'


module WidgetList

  if defined?(Rails) && defined?(Rails::Engine)
    class Engine < ::Rails::Engine
      require 'widget_list/engine'
    end
  end

  class List

    @debug = true

    include ActionView::Helpers::SanitizeHelper

    def self.determine_db_type(db_type)
      the_type, void = db_type.split("://")
      if the_type == 'sqlite:/'
        the_type = 'sqlite'
      end
      return the_type.downcase
    end

    def self.connect

      begin
        if Rails.root.join("config", "widget-list.yml").file?
          config = YAML.load(ERB.new(File.new(Rails.root.join("config", "widget-list.yml")).read).result)[Rails.env]
          if config.nil?
            throw 'Configuration file widget-list.yml has no data.  Check that (' + Rails.env + ') Rails.env matches the pointers in the file'
          end
          @primary_conn   = config[:primary]
          @secondary_conn = config[:secondary]
        else
          throw 'widget-list.yml not found'
        end

        $DATABASE  = Sequel.connect(@primary_conn) if @primary_conn != 'false' and @primary_conn != false
        $DATABASE2 = Sequel.connect(@secondary_conn) if @secondary_conn != 'false' and @secondary_conn != false

        if @primary_conn.class.name != 'false' and @primary_conn != false
          $DATABASE.db_type = determine_db_type(@primary_conn)
        end

        if @primary_conn.class.name != 'false' and @secondary_conn != false
          $DATABASE2.db_type = determine_db_type(@secondary_conn)
        end
      rescue Exception => e
        p "widget-list.yml and connection to \$DATABASE failed.  Please fix and try again (" + e.to_s + ")"
      end

    end

    def self.get_database
      case $current_db_selection
        when 'primary'
          $DATABASE
        when 'secondary'
          $DATABASE2
        else
          $DATABASE
      end
    end

    # @param [Hash] list
    def initialize(list={})
      
      # Defaults for all configs
      # See https://github.com/davidrenne/widget_list/blob/master/README.md#feature-configurations
      @items = {
        'name'                => ([*('A'..'Z'),*('0'..'9')]-%w(0 1 I O)).sample(16).join,
        'database'            => 'primary', #
        'title'               => '',
        'listDescription'     => '',
        'pageId'              => $_SERVER['PATH_INFO'],
        'view'                => '',
        'data'                => {},
        'collClass'           => '',
        'collAlign'           => '',
        'fields'              => {},
        'fields_hidden'       => [],
        'bindVars'            => [],
        'bindVarsLegacy'      => {},
        'links'               => {},
        'results'             => {},
        'buttons'             => {},
        'inputs'              => {},
        'filter'              => [],
        'rowStart'            => 0,
        'rowLimit'            => 10,
        'orderBy'             => '',
        'allowHTML'           => true,
        'strlength'           => 30,
        'searchClear'         => false,
        'searchClearAll'      => false,
        'showPagination'      => true,
        'searchSession'       => true,

        #
        # carryOverRequests will allow you to post custom things from request to all sort/paging URLS for each ajax
        #
        'carryOverRequsts'    => ['switch_grouping'],

        #
        # Head/Foot
        #

        'customFooter'        => '', # add buttons or HTML at bottom area of list inside the grey box
        'customHeader'        => '', # add buttons or HTML at top area of list above all headers (such as TABS) 

        #
        # Ajax
        #
        'ajax_action'         => '',
        'ajax_function_all'   => '', #Custom javascript called asychronously during each click
        'ajax_function'       => 'ListJumpMin',
        'ajax_search_function'=> 'ListJumpMin',

        #
        #  Search
        #
        'showSearch'          => true,
        'searchOnkeyup'       => '',
        'searchOnclick'       => '',
        'searchIdCol'         => 'id',         #By default `id` column is here because typically if you call your PK's id and are auto-increment
        'searchInputLegacyCSS'=> false,
        'searchBtnName'       => 'Search by Id or a list of Ids and more',
        'searchTitle'         => '',
        'searchFieldsIn'      => {},            #White list of fields to include in a alpha-numeric based search
        'searchFieldsOut'     => {'id'=>true},  #Black list of fields to include in a alpha-numeric based search (default `id` to NEVER search when alpha seach)

        #
        #  Export
        #
        'showExport'          => true,

        #
        # Group By Box
        #
        'groupByItems'        => [],    #array of strings (each a new "select option")
        'groupBySelected'     => false, #initially selected grouping - defaults to first in list if not
        'groupByLabel'        => 'Group By',
        'groupByClick'        => '',
        'groupByClickDefault' => "ListChangeGrouping('<!--NAME-->', this);",


        #
        # Advanced searching
        #
        'list_search_form'    => '', #The HTML form used for the advanced search drop down
        'list_search_attribs' => {}, #widgetinput "search_ahead" attributes

        #
        # Column Specific
        #
        'columnStyle'         => {},
        'columnClass'         => {},
        'columnPopupTitle'    => {},
        'columnSort'          => {},
        'columnWidth'         => {},
        'columnNoSort'        => {},
        'columnFilter'        => {},

        #
        # Column Border (on right)
        #
        'borderedColumns'     => false,
        'borderColumnStyle'   => '1px solid #CCCCCC',

        #
        # Row specifics
        #
        'rowColor'            => '#FFFFFF',
        'rowClass'            => '',
        'rowColorByStatus'    => {},
        'rowStylesByStatus'   => {},
        'offsetRows'          => true,
        'rowOffsets'          => ['FFFFFF','FFFFFF'],

        'class'               => 'listContainerPassive',
        'tableclass'          => 'tableBlowOutPreventer',
        'noDataMessage'       => 'Currently no data.',
        'useSort'             => true,
        'headerClass'         => {},
        'groupBy'             => '',
        'fieldFunction'       => {},
        'buttonVal'           => 'templateListJump',
        'linkFunction'        => 'ButtonLinkPost',
        'template'            => '',
        'templateFilter'      => '',
        'pagerFull'          => true,
        'LIST_COL_SORT_ORDER' => 'ASC',
        'LIST_COL_SORT'       => '',
        'LIST_FILTER_ALL'     => '',
        'ROW_LIMIT'           => '',
        'LIST_SEQUENCE'       => 1,
        'NEW_SEARCH'          => false,

        #
        # Checkbox
        #
        'checked_class'       => 'widgetlist-checkbox',
        'checked_flag'        => {},

        #
        # Hooks
        #
        'column_hooks'        => {},
        'row_hooks'           => {}
      }

      @csv          = []
      @csv          << []
      @totalRowCount= 0
      @totalPages   = 0
      @fixHtmlLinksReplace = {}

      @sequence     = 1
      @totalRows    = 0
      @totalPage    = 0
      @listSortNext = 'ASC'
      @filter       = ''
      @listFilter   = ''
      @fieldList    = []
      @templateFill = {}
      @results      = {}

      #the main template and outer shell
      @items.deep_merge!({'template' =>
                            '
                              <!--WRAP_START-->
                              <!--HEADER-->
                              <!--CUSTOM_CONTENT_TOP-->
                              <div class="<!--CLASS-->" id="<!--NAME-->">
                                 <table class="widget_list <!--TABLE_CLASS-->" style="<!--INLINE_STYLE-->" border="0" width="100%" cellpadding="0" cellspacing="0">
                                    <!--LIST_TITLE-->
                                    <tr class="widget_list_header"><!--HEADERS--></tr>
                                       <!--DATA-->
                                    <tr>
                                       <td colspan="<!--COLSPAN_FULL-->" align="left" style="padding:0px;margin:0px;text-align:left">
                                          <div style="background-color:#ECECEC;height:50px;"><div style="padding:10px"><!--CUSTOM_CONTENT_BOTTOM--></div>
                                       </td>
                                    </tr>
                                 </table>
                                 <div class="pagination" style="float:left;text-align:left;width:100%;margin:0px;padding:0px;"><div style="margin:auto;float:left;margin:0px;padding:0px;"><!--PAGINATION_LIST--></div></div>
                                 <!--FILTER-->
                                 <input type="hidden" name="<!--JUMP_URL_NAME-->" id="<!--JUMP_URL_NAME-->" value="<!--JUMP_URL-->">
                              </div>
                            <!--WRAP_END-->
                             '
                         })

      @items.deep_merge!({'row' =>
                            '
                                          <tr style="background-color:<!--BGCOLOR-->;<!--ROWSTYLE-->" class="<!--ROWCLASS-->"><!--CONTENT--></tr>
                              '
                         })

      @items.deep_merge!({'list_description' =>
                            '
                                          <tr class="summary">
                                             <td id="<!--LIST_NAME-->_list_description" class="header" style="text-align: left;padding-bottom: 2px;padding-top: 7px;font-size: 14px;" colspan="<!--COLSPAN-->"><!--LIST_DESCRIPTION--></td>
                                          </tr>
                              '
                         })

      @items.deep_merge!({'col' =>
                            '
                                          <td class="<!--CLASS-->" align="<!--ALIGN-->" title="<!--TITLE-->" onclick="<!--ONCLICK-->" style="<!--STYLE-->"><!--CONTENT--></td>
                              '
                         })

      @items.deep_merge!({'templateSequence' =>
                            '
                                          <!--LIST_SEQUENCE--> of <!--TOTAL_PAGES-->
                              '
                         })
      #Sorting
      #
      @items.deep_merge!({'templateSortColumn' =>
                            '
                                          <td style="font-weight:bold;<!--INLINE_STYLE--><!--INLINE_STYLE-->" id="<!--COL_HEADER_ID-->" class="<!--COL_HEADER_CLASS-->" title="<!--TITLE_POPUP-->" valign="middle"><span onclick="<!--FUNCTION-->(\'<!--COLSORTURL-->\',\'<!--NAME-->\');<!--FUNCTION_ALL-->" style="cursor:pointer;background:none;"><!--TITLE--><!--COLSORTICON-></span></td>
                              '
                         })

      @items.deep_merge!({'templateNoSortColumn' =>
                            '
                                          <td style="font-weight:bold;<!--INLINE_STYLE-->" title="<!--TITLE_POPUP-->" id="<!--COL_HEADER_ID-->" class="<!--COL_HEADER_CLASS-->" valign="middle"><span style="background:none;"><!--TITLE--></span></td>
                              '
                         })

      @items.deep_merge!({'statement' =>
                            {'select'=>
                               {'view' =>
                                  '
                                   SELECT <!--FIELDS--> FROM <!--SOURCE--> <!--WHERE--> <!--GROUPBY--> <!--ORDERBY--> <!--LIMIT-->
                                   '
                               }
                            }
                         })

      @items.deep_merge!({'statement' =>
                            {'count'=>
                               {'view' =>
                                  '
                                   SELECT count(1) total FROM <!--VIEW--> <!--WHERE-->
                                   '
                               }
                            }
                         })

      #Pagintion
      #

      @items.deep_merge!({'template_pagination_wrapper' =>
                            '
                              <ul id="pagination" class="page_legacy">
                                 Page <!--PREVIOUS_BUTTON-->
                                 <input type="text" value="<!--SEQUENCE-->" size="1" style="width:15px;padding:0px;font-size:10px;" onblur="">
                                 <input type="hidden" id="<!--LIST_NAME-->_total_rows" value="<!--TOTAL_ROWS-->">
                                 <!--NEXT_BUTTON--> of <!--TOTAL_PAGES--> pages <span style="margin-left:20px">Total <!--TOTAL_ROWS--> records found</span>
                                 <span style="padding-left:20px;">Show <!--PAGE_SEQUENCE_JUMP_LIST--> per page</span>
                              </ul>
                            '
                         })

      @items.deep_merge!({'template_pagination_next_active' =>
                            "
                            <li><span onclick=\"<!--FUNCTION-->('<!--NEXT_URL-->','<!--LIST_NAME-->');<!--FUNCTION_ALL-->\" style=\"cursor:pointer;background: transparent url(<!--HTTP_SERVER-->images/page-next.gif) no-repeat\">&nbsp;</span></li>
                            "
                         })

      @items.deep_merge!({'template_pagination_next_disabled' =>
                            "
                            <li><span style=\"opacity:0.4;filter:alpha(opacity=40);background: transparent url(<!--HTTP_SERVER-->images/page-next.gif) no-repeat\">&nbsp;</span></li>
                            "
                         })

      @items.deep_merge!({'template_pagination_previous_active' =>
                            "
                            <li><span onclick=\"<!--FUNCTION-->('<!--PREVIOUS_URL-->','<!--LIST_NAME-->');<!--FUNCTION_ALL-->\" style=\"cursor:pointer;background: transparent url(<!--HTTP_SERVER-->images/page-back.gif) no-repeat\">&nbsp;</span></li>
                            "
                         })

      @items.deep_merge!({'template_pagination_previous_disabled' =>
                            "
                            <li><span style=\"opacity:0.4;filter:alpha(opacity=40);background: transparent url(<!--HTTP_SERVER-->images/page-back.gif) no-repeat\">&nbsp;</span></li>
                            "
                         })

      @items.deep_merge!({'template_pagination_jump_active' =>
                            '
                            <li><div class="active"><!--SEQUENCE--></div></li>
                            '
                         })

      @items.deep_merge!({'template_pagination_jump_unactive' =>
                            '
                            <li onclick="<!--FUNCTION-->(\'<!--JUMP_URL-->\',\'<!--LIST_NAME-->\');<!--FUNCTION_ALL-->"><div><!--SEQUENCE--></div></li>
                            '
                         })

      @items = WidgetList::Widgets::populate_items(list,@items)

      # current_db is a flag of the last known primary or secondary YML used or defaulted when running a list
      $current_db_selection = @items['database']

      if WidgetList::List.get_database.db_type == 'oracle'
        @items.deep_merge!({'statement' =>
                              {'select'=>
                                 {'view' =>
                                    '
                                        SELECT <!--FIELDS-->, rn FROM ( SELECT ' + ( (!@items['view'].include?('(')) ? '<!--SOURCE-->' : @items['view'].strip.split(" ").last ) + '.*, rank() over (<!--ORDERBY-->) rn FROM <!--SOURCE--> ) a <!--WHERE--> <!--GROUPBY--> <!--ORDERBY--> <!--LIMIT-->
                                        '
                                 }
                              }
                           })

      end

      begin
        @isJumpingList = false

        #Ajax ListJump
        if ! $_REQUEST.empty?
          if $_REQUEST.key?('LIST_FILTER_ALL')
            @items['LIST_FILTER_ALL']     = $_REQUEST['LIST_FILTER_ALL']
            @isJumpingList = true
          end

          if $_REQUEST.key?('LIST_COL_SORT')
            @items['LIST_COL_SORT']     = $_REQUEST['LIST_COL_SORT']
            @isJumpingList = true
          end

          if $_REQUEST.key?('LIST_COL_SORT_ORDER')
            @items['LIST_COL_SORT_ORDER']     = $_REQUEST['LIST_COL_SORT_ORDER']
            @isJumpingList = true
          end

          if $_REQUEST.key?('LIST_SEQUENCE')
            @items['LIST_SEQUENCE']     = $_REQUEST['LIST_SEQUENCE'].to_i
            @isJumpingList = true
          end

          if $_REQUEST.key?('ROW_LIMIT')
            @items['ROW_LIMIT']     = $_REQUEST['ROW_LIMIT']
            @isJumpingList = true

            if @items['showPagination']
              $_SESSION['pageDisplayLimit']            = $_REQUEST['ROW_LIMIT']
              $_SESSION.deep_merge!({'ROW_LIMIT' => { @items['name'] => $_REQUEST['ROW_LIMIT']} })
            end

          end

          clear_sort_get_vars()

          if $_REQUEST.key?('list_action') && $_REQUEST['list_action'] == 'ajax_widgetlist_checks'
            ajax_maintain_checks()
          end

        end

        @items['groupByClick'] = WidgetList::Utils::fill({'<!--NAME-->' => @items['name']}, @items['groupByClickDefault'] + @items['groupByClick'])

        if $_REQUEST.key?('searchClear')
          clear_search_session()
        end

        if @items['searchClear'] || @items['searchClearAll']
          clear_search_session(@items.key?('searchClearAll'))
        end

        matchesCurrentList   = $_REQUEST.key?('BUTTON_VALUE') && $_REQUEST['BUTTON_VALUE'] == @items['buttonVal']
        isSearchRequest      = $_REQUEST.key?('search_filter')
        templateCustomSearch = !@items['templateFilter'].empty? # if you define templateFilter WidgetList will not attempt to build a where clause with search

        #
        # Search restore
        #
        if !isSearchRequest && $_SESSION.key?('SEARCH_FILTER') && $_SESSION['SEARCH_FILTER'].key?(@items['name']) && @items['searchSession']
          isSearchRestore = true
        end

        if (isSearchRequest && matchesCurrentList && !templateCustomSearch && @items['showSearch']) || isSearchRestore
          if !isSearchRestore
            $_SESSION.deep_merge!({'SEARCH_FILTER' => { @items['name'] => $_REQUEST['search_filter']} })
            searchFilter = $_REQUEST['search_filter'].strip_or_self()
          else
            searchFilter = $_SESSION['SEARCH_FILTER'][@items['name']]
          end

          if ! searchFilter.empty?
            if ! @items['filter'].empty? && @items['filter'].class.name != 'Array'
              # convert string to array filter
              filterString = @items['filter']
              @items['filter'] = []
              @items['filter'] << filterString
            end

            fieldsToSearch = @items['fields'].dup

            @items['fields_hidden'].each { |columnPivot|
              fieldsToSearch[columnPivot] = columnPivot
            }

            searchCriteria = searchFilter.strip_or_self()
            searchSQL      = []
            numericSearch  = false

            #
            # Comma delimited search
            #
            if searchFilter.include?(',')
              #It is either a CSV or a comma inside the search string
              #
              criteriaTmp = searchFilter.split_it(',')

              #Assumed a CSV of numeric ids
              #
              isNumeric = true
              criteriaTmp.each_with_index { |value, key|
                if !value.empty?
                  criteriaTmp[key] = value.strip_or_self()

                  if !criteriaTmp[key].nil? &&  ! criteriaTmp[key].empty?
                    if ! WidgetList::Utils::numeric?(criteriaTmp[key])
                      isNumeric = false
                    end
                  else
                    criteriaTmp.delete(key)
                  end
                end
              }

              if isNumeric
                numericSearch = true
                if @items['searchIdCol'].class.name == 'Array'
                  @items['searchIdCol'].each { |searchIdCol|
                    if(fieldsToSearch.key?(searchIdCol))
                      searchSQL << tick_field() + searchIdCol + tick_field() + " IN(" + searchFilter  + ")"
                    end
                  }

                  if !searchSQL.empty?
                    #
                    # Assemble Numeric Filter
                    #
                    @items['filter'] << "(" + searchSQL.join(' OR ') + ")"
                  end
                elsif @items['fields'].key?(@items['searchIdCol'])
                  numericSearch = true
                  @items['filter']  << tick_field() + "#{@items['searchIdCol']}" + tick_field() + " IN(" + criteriaTmp.join(',') + ")"
                end
              end
            elsif @items['searchIdCol'].class.name == 'Array'
              if WidgetList::Utils::numeric?(searchFilter) && ! searchFilter.include?('.')
                numericSearch = true
                @items['searchIdCol'].each { |searchIdCol|
                  if fieldsToSearch.key?(searchIdCol)
                    searchSQL << tick_field() + "#{searchIdCol}" + tick_field() + " IN(#{searchFilter})"
                  end
                }

                if !searchSQL.empty?
                  #
                  # Assemble Numeric Filter
                  #
                  @items['filter'] << "(" + searchSQL.join(' OR ') + ")"
                end
              end
            elsif WidgetList::Utils::numeric?(searchFilter) && ! searchFilter.include?('.') && @items['fields'].key?(@items['searchIdCol'])
              numericSearch = true
              @items['filter'] << tick_field() + "#{@items['searchIdCol']}" + tick_field() + " IN(" + searchFilter + ")"
            end

            # If it is not an id or a list of ids then it is assumed a string search
            if !numericSearch

              fieldsToSearch.each { |fieldName,fieldTitle|

                # new lodgette. if fieldFunction exists, find all matches and skip them

                if @items['fieldFunction'].key?(fieldName)
                  theField = @items['fieldFunction'][fieldName]  + cast_col()
                else
                  theField = tick_field() + "#{fieldName}" + cast_col() + tick_field()
                end

                skip = false
                skip = skip_column(fieldName)

                #buttons must ALWAYS BE ON THE RIGHT SIDE IN ORDER FOR THIS NOT TO SEARCH A NON-EXISTENT COLUMN  (used to be hard coded to 'features' as a column to remove)
                if skip
                  next
                end

                #Search only specified fields. This can involve a dynamic field list from an advanced search form
                #
                if ! @items['searchFieldsIn'].empty?
                  #
                  # If it exists in either key or value
                  #
                  if ! @items['searchFieldsIn'].key?(fieldName) && ! @items['searchFieldsIn'].include?(fieldName)
                    next
                  end
                elsif ! @items['searchFieldsOut'].empty?
                  if @items['searchFieldsOut'].key?(fieldName) ||  @items['searchFieldsOut'].include?(fieldName)
                    next
                  end
                end

                #todo - escape bind variables using Sequel
                searchSQL <<  theField + " LIKE '%" + searchCriteria + "%'"
              }

              #
              # Assemble String Filter
              #
              if(! searchSQL.empty?)
                @items['filter'] << "(" + searchSQL.join(' OR ') + ")"
              end
            end
          end
        end

        if !$_REQUEST.key?('BUTTON_VALUE')

          #Initialize page load/Session stuff whe list first loads
          #
          WidgetList::List::clear_check_box_session(@items['name'])
        end


        if ! @items.key?('templateHeader')
          @items['templateHeader'] = ''
        end

        #Set a list title if it exists
        #

        if ! $_REQUEST.key?('BUTTON_VALUE') && !@items['title'].empty?
          @items['templateHeader'] = '
                                       <h1 style="font-size:24px;"><!--TITLE--></h1><div class="horizontal_rule"></div>
                                       <!--FILTER_HEADER-->
                                     '
        elsif !$_REQUEST.key?('BUTTON_VALUE')
          # Only if not in ajax would we want to output the filter header
          #
          @items['templateHeader'] = '<!--FILTER_HEADER-->'
        end

        # Build the filter (If any)
        #
        # todo - unit test filter
        if !@items['filter'].empty? && @items['filter'].class.name == 'Array'
          @filter = @items['filter'].join(' AND ')
        elsif !@items['filter'].empty? && @items['filter'].class.name == 'String'
          @filter = @items['filter']
        end

        #Sorting
        #

        if !@items['LIST_COL_SORT'].empty?
          @items['LIST_SEQUENCE'] = 1
        end

        if @items['LIST_SEQUENCE'].class.name == 'Fixnum' && @items['LIST_SEQUENCE'] > 0
          @sequence               = @items['LIST_SEQUENCE'].to_i
        end

        if ! @items['ROW_LIMIT'].empty?
          @items['rowLimit']      = @items['ROW_LIMIT'].to_i
        end

        if $_SESSION.key?('ROW_LIMIT') && $_SESSION['ROW_LIMIT'].key?(@items['name']) && !$_SESSION['ROW_LIMIT'][@items['name']].empty?
          @items['rowLimit'] = $_SESSION['ROW_LIMIT'][@items['name']].to_i
        end

        if ! @items['LIST_COL_SORT'].empty?
          case @items['LIST_COL_SORT_ORDER']
            when 'ASC'
              @listSortNext = 'DESC'
            else
              @listSortNext = 'ASC'
          end
        end

        generate_limits()
      rescue Exception => e
        @templateFill['<!--DATA-->']  = '<tr><td colspan="50"><div id="noListResults">' + generate_error_output(e) + @items['noDataMessage'] + '</div></td></tr>'
      end
    end

    def skip_column(fieldName)
      skip = false
      (@items['inputs']||{}).each { |k,v|
        if fieldName == k
          skip = true
        end
      }

      if @items['buttons'].key?(fieldName)
        skip = true
      end
      return skip
    end

    def tick_field()
      case WidgetList::List.get_database.db_type
        when 'postgres'
        when 'oracle'
          ''
        else
          '`'
      end
    end

    def cast_col()
      case WidgetList::List.get_database.db_type
        when 'postgres'
          '::char(1000)'
        else
          ''
      end
    end

    def ajax_maintain_checks()

      if !$_SESSION.key?('list_checks')
        $_SESSION['list_checks'] = {}
      end

      #
      # A list must be provided
      #
      if $_REQUEST.key?('LIST_NAME')
        listName  = $_REQUEST['LIST_NAME']
        sqlHash   = $_REQUEST['SQL_HASH']
        sequence  = $_REQUEST['LIST_SEQUENCE'].to_s

        #
        # The placeholder is created when the list initially forms. This validates it and makes it so
        # not just anything can be injected into the session via this method.
        #

        #
        # For each posted check box
        #

        $_REQUEST.each { |value, checked|
          if checked.to_s == '1'
            #
            # Set it as checked
            #
            $_SESSION.deep_merge!({'list_checks' => { listName + sqlHash + value => true  } })
          else
            #
            # Unset if it exists and is unchecked
            #
            if $_SESSION['list_checks'].key?(listName + sqlHash + value)
              $_SESSION['list_checks'].delete(listName + sqlHash + value)
            end
          end
        }

        #
        # Check All
        #
        if $_REQUEST.key?('checked_all') && $_REQUEST['checked_all'] == '1'
          if $_SESSION.key?('list_checks')

            if $_SESSION['list_checks'].key?('check_all_' + sqlHash + listName + sequence)
              if $_REQUEST['checked_all'].empty?
                $_SESSION['list_checks'].delete('check_all_' + sqlHash + listName + sequence)
              else
                $_SESSION.deep_merge!({'list_checks' => { 'check_all_' + sqlHash + listName + sequence => true } })
              end
            else
              if ! $_REQUEST['checked_all'].empty?
                $_SESSION.deep_merge!({'list_checks' => { 'check_all_' + sqlHash + listName +  $_REQUEST['LIST_SEQUENCE'] => true } })
              end
            end
          end
        end
      end
    end

    def self.clear_check_box_session(name='')

      if $_SESSION.key?('DRILL_DOWN_FILTERS')
        $_SESSION.delete('DRILL_DOWN_FILTERS')
      end

      if $_SESSION.key?('DRILL_DOWNS')
        $_SESSION.delete('DRILL_DOWNS')
      end

      $_SESSION['list_checks'].keys.each { |key|
        if key.include?(name)
          $_SESSION['list_checks'].delete(key)
        end
      } if $_SESSION.key?('list_checks')

    end

    def clear_search_session(all=false)

      if $_SESSION.key?('SEARCH_FILTER') && $_SESSION['SEARCH_FILTER'].key?(@items['name'])
        $_SESSION['SEARCH_FILTER'].delete(@items['name'])
      end

      if $_SESSION.key?('ROW_LIMIT') && $_SESSION['ROW_LIMIT'].key?(@items['name'])
        $_SESSION['ROW_LIMIT'].delete(@items['name'])
      end

      if $_SESSION.key?('DRILL_DOWNS') && $_SESSION['DRILL_DOWNS'].key?(@items['name'])
        $_SESSION['DRILL_DOWNS'].delete(@items['name'])
      end

      if $_SESSION.key?('DRILL_DOWN_FILTERS') && $_SESSION['DRILL_DOWN_FILTERS'].key?(@items['name'])
        $_SESSION['DRILL_DOWN_FILTERS'].delete(@items['name'])
      end

      if all && $_SESSION.key?('SEARCH_FILTER')
        $_SESSION.delete('SEARCH_FILTER')
      end

      if all && $_SESSION.key?('ROW_LIMIT')
        $_SESSION.delete('ROW_LIMIT')
      end

    end

    def clear_sql_session(all=false)

      if $_SESSION.key?('LIST_SEQUENCE') && $_SESSION['LIST_SEQUENCE'].key?(@sqlHash)
        $_SESSION['LIST_SEQUENCE'].delete(@sqlHash)
      end

      if $_SESSION.key?('LIST_COL_SORT') && $_SESSION['LIST_COL_SORT'].key?(@sqlHash)
        $_SESSION['LIST_COL_SORT'].delete(@sqlHash)
      end

      if all && $_SESSION.key?('LIST_COL_SORT')
        $_SESSION.delete('LIST_COL_SORT')
      end

      if all && $_SESSION.key?('LIST_SEQUENCE')
        $_SESSION.delete('LIST_SEQUENCE')
      end

    end

    def self.get_filter_and_drilldown(listId)
      filter = ''
      drillDown = ''
      if !$_REQUEST.key?('BUTTON_VALUE')
        # Initialize page load/Session stuff whe list first loads
        #
        WidgetList::List::clear_check_box_session(listId)
      end

      if $_REQUEST.key?('drill_down') && !$_REQUEST.key?('searchClear')
        drillDown = $_REQUEST['drill_down']
        $_SESSION.deep_merge!({'DRILL_DOWNS' => { listId => drillDown} }) && !$_REQUEST.key?('searchClear')
      elsif $_SESSION.key?('DRILL_DOWNS') && $_SESSION['DRILL_DOWNS'].key?(listId) && !$_REQUEST.key?('searchClear')
        drillDown = $_SESSION['DRILL_DOWNS'][listId]
      else
        drillDown = 'default'
      end

      if $_REQUEST.key?('filter') && !$_REQUEST.key?('searchClear')
        filter = $_REQUEST['filter']
        $_SESSION.deep_merge!({'DRILL_DOWN_FILTERS' => { listId => filter} })
      elsif $_SESSION.key?('DRILL_DOWN_FILTERS') && $_SESSION['DRILL_DOWN_FILTERS'].key?(listId) && !$_REQUEST.key?('searchClear')
        filter = $_SESSION['DRILL_DOWN_FILTERS'][listId]
      end
      return drillDown, filter
    end

    def clear_sort_get_vars()
      $_REQUEST.delete('LIST_FILTER_ALL')
      $_REQUEST.delete('ROW_LIMIT')
      $_REQUEST.delete('LIST_SEQUENCE')
      $_REQUEST.delete('LIST_COL_SORT_ORDER')
      $_REQUEST.delete('LIST_COL_SORT')
      $_REQUEST.delete('LIST_FILTER_ALL')
    end

    def generate_limits()
      #Pagination
      #
      @items['bindVarsLegacy']['LOW']  = @items['rowStart']
      @items['bindVarsLegacy']['HIGH'] = @items['rowLimit']

      if @sequence.to_i > 1 && ! @items['NEW_SEARCH']
        subtractLimit = 0
        if WidgetList::List.get_database.db_type != 'oracle'
          subtractLimit = @items['rowLimit']
        end
        @items['bindVarsLegacy']['LOW'] = (((@sequence * @items['rowLimit']) -  subtractLimit))
        if WidgetList::List.get_database.db_type == 'oracle'
          @items['bindVarsLegacy']['HIGH'] = ((((@sequence + 1) * @items['rowLimit'])))
        end

      end
    end

    # @param [Hash] results
    # pass results of $DATABASE.final_results after running a _select query
    def render(results={})

      begin
        if !results.empty?
          @items['data'] = results
        end

        #Get total records for statement validation and pagination
        #
        @items['data'].keys.each { |column|
          @items['fields'][column.downcase] = auto_column_name(column)
        } if !@items['data'].empty? && @items['fields'].empty?

        if @items['data'].empty?
          # Generate count() from database
          #
          @totalResultCount = get_total_records()
        else
          # Count the items in the passed data
          #
          @items['data'].keys.each { |column|
            @totalResultCount = @items['data'][column].count
            @totalRowCount    = @totalResultCount
            @totalRows        = @totalResultCount
            break
          }
        end

        build_rows()

        build_headers()

        listJumpUrl = {}
        listJumpUrl['PAGE_ID']             = @items['pageId']
        listJumpUrl['ACTION']              = 'AJAX'
        listJumpUrl['BUTTON_VALUE']        = @items['buttonVal']
        listJumpUrl['LIST_COL_SORT']       = @items['LIST_COL_SORT']
        listJumpUrl['LIST_COL_SORT_ORDER'] = @items['LIST_COL_SORT_ORDER']
        listJumpUrl['LIST_FILTER_ALL']     = @items['LIST_FILTER_ALL']
        listJumpUrl['ROW_LIMIT']           = @items['ROW_LIMIT']
        listJumpUrl['LIST_SEQUENCE']       = @sequence
        listJumpUrl['LIST_NAME']           = @items['name']
        listJumpUrl['SQL_HASH']            = @sqlHash

        if @items.key?('ajax_action')
          listJumpUrl['list_action'] = @items['ajax_action']
        end

        if $_REQUEST.key?('switch_grouping')
          listJumpUrl['switch_grouping'] = $_REQUEST['switch_grouping']
        end

        @templateFill['<!--CUSTOM_CONTENT_BOTTOM-->']= @items['customFooter']
        @templateFill['<!--CUSTOM_CONTENT_TOP-->']   = @items['customHeader']
        @templateFill['<!--WRAP_START-->']           = ''
        @templateFill['<!--WRAP_END-->']             = ''
        if !$_REQUEST.key?('BUTTON_VALUE')
          @templateFill['<!--WRAP_START-->']         = '<div class="widget_list_outer">
                                                   <input type="hidden" id="<!--NAME-->_jump_url_original" value="<!--JUMP_URL-->"/>'
          @templateFill['<!--WRAP_END-->']           = '</div>'
        end

        @templateFill['<!--HEADER-->']               = @items['templateHeader']
        @templateFill['<!--TITLE-->']                = @items['title']
        @templateFill['<!--NAME-->']                 = @items['name']
        @templateFill['<!--JUMP_URL-->']             = WidgetList::Utils::build_url(@items['pageId'],listJumpUrl,(!$_REQUEST.key?('BUTTON_VALUE')))
        @templateFill['<!--JUMP_URL_NAME-->']        = @items['name'] + '_jump_url'
        @templateFill['<!--CLASS-->']                = @items['class']

        if @totalRowCount > 0
          @templateFill['<!--INLINE_STYLE-->']       = ''
          @templateFill['<!--TABLE_CLASS-->']        = @items['tableclass']
        else
          @templateFill['<!--INLINE_STYLE-->']       = 'table-layout:auto;'
        end

        #Filter form
        #
        if @items['showSearch'] === true
          if ! @items['templateFilter'].empty?
            @templateFill['<!--FILTER_HEADER-->']    = @items['templateFilter']
          else
            if !$_REQUEST.key?('search_filter') && !@isJumpingList

              #Search page url
              #
              searchUrl = ''
              searchVal = ''

              if ! @items['buttonVal'].empty?
                searchVal = @items['buttonVal']
              else
                searchVal = @items['name']
              end

              filterParameters = {}
              filterParameters['BUTTON_VALUE'] = searchVal
              filterParameters['PAGE_ID']      = @items['pageId']
              filterParameters['LIST_NAME']    = @items['name']
              filterParameters['SQL_HASH']     = @sqlHash
              if @items.key?('ajax_action') && ! @items['ajax_action'].empty?
                filterParameters['list_action'] = @items['ajax_action']
              end

              @items['carryOverRequsts'].each { |value|
                if $_REQUEST.key?(value)
                  filterParameters[value] = $_REQUEST[value]
                end
              }

              searchUrl =  WidgetList::Utils::build_url(@items['pageId'], filterParameters, (!$_REQUEST.key?('BUTTON_VALUE')))

              list_search  = {}
              #
              # Search value
              #
              list_search['value'] = ''

              if @items['searchSession']
                if $_SESSION.key?('SEARCH_FILTER') && $_SESSION['SEARCH_FILTER'].key?(@items['name'])
                  list_search['value'] = $_SESSION['SEARCH_FILTER'][@items['name']]
                end
              end

              #
              # Search Input Field
              #
              list_search['list-search'] = true
              list_search['width']       = '500'
              list_search['input_class'] = 'info-input'
              list_search['title']       = (@items['searchTitle'].empty?) ? @items['searchBtnName'] :@items['searchTitle']
              list_search['id']          = 'list_search_id_' + @items['name']
              list_search['name']        = 'list_search_name_' + @items['name']
              list_search['class']       = 'inputOuter widget-search-outer ' + @items['name'].downcase + '-search'
              list_search['search_ahead']       = {
                'url'          => searchUrl,
                'skip_queue'   => false,
                'target'       => @items['name'],
                'search_form'  => @items['list_search_form'],
                'onclick'      => (! @items['searchOnclick'].empty? && ! @items['list_search_form'].empty?) ? @items['searchOnclick'] : '',
                'onkeyup'      => (! @items['searchOnkeyup'].empty?) ? @items['searchOnkeyup'] : ''
              }

              @templateFill['<!--FILTER_HEADER-->'] = WidgetList::Widgets::widget_input(list_search)

            end

            #
            # Grouping box
            #
            if ! @items['groupByItems'].empty?
              list_group = {}
              list_group['arrow_action']  = 'var stub;'
              list_group['readonly']      = true
              if @items['groupBySelected']
                list_group['value']      = @items['groupBySelected']
              else
                list_group['value']      = @items['groupByItems'][0]
              end

              list_group['style']         = 'cursor:pointer;margin-left:5px;'
              list_group['input_style']   = 'cursor:pointer;'
              list_group['outer_onclick'] = 'ToggleAdvancedSearch(this);SelectBoxResetSelectedRow(\'' + @items['name'] + '\');'
              list_group['list-search']   = false
              list_group['width']         = '200'  #hard code for now.  needs to be dynamic based on max str length if this caller is made into a "WidgetFakeSelect"
              list_group['id']            = 'list_group_id_' + @items['name']
              list_group['name']          = 'list_group_name_' + @items['name']
              list_group['class']         = 'inputOuter widget-search-outer ' + @items['name'].downcase + '-group'

              className = ''
              groupRows = []
              if !@items['groupBySelected']
                className     = 'widget-search-results-row-selected'
              end

              num = 1
              @items['groupByItems'].each { |grouping|
                if @items['groupBySelected'] && @items['groupBySelected'] === grouping
                  className     = 'widget-search-results-row-selected'
                end
                groupRows << '<div class="widget-search-results-row ' +  className + '" id="' + @items['name'] + '_row_' + num.to_s + '" title="' + grouping + '" onmouseover="jQuery(\'.widget-search-results-row\').removeClass(\'widget-search-results-row-selected\')" onclick="SelectBoxSetValue(\'' + grouping + '\',\'' + @items['name'] + '\');' + @items['groupByClick'] + '">' + grouping + '</div>'
                className = ''
                num = num + 1
              }

              list_group['search_ahead']  = {
                'skip_queue' => false,
                'search_form'=>  '
                                 <div id="advanced-search-container" style="height:100% !important;">
                                    ' + groupRows.join("\n") + '
                                 </div>',
                'onclick'    => @items['searchOnclick']
              }
              if !@templateFill.key?('<!--FILTER_HEADER-->')
                @templateFill['<!--FILTER_HEADER-->'] = ''
              end
              @templateFill['<!--FILTER_HEADER-->']  += '<div class="fake-select"><div class="label">' + @items['groupByLabel'] + ':</div> ' + WidgetList::Widgets::widget_input(list_group) + '</div>'

              if @items['showExport']
                @templateFill['<!--FILTER_HEADER-->']  +=  WidgetList::Widgets::widget_button('Export CSV', {'onclick' => 'ListExport(\'' + @items['name'] + '\');'}, true)
              end

            end
          end
        end

      rescue Exception => e
        out = '<tr><td colspan="50"><div id="noListResults">' + generate_error_output(e) + @items['noDataMessage'] + '</div></td></tr>'
        if !@templateFill.key?('<!--DATA-->')
          @templateFill['<!--DATA-->']  = out
        else
          @templateFill['<!--DATA-->'] += out
        end
      end

      if $_REQUEST.key?('export_widget_list')
        csv = ''
        @csv.each{ |v|
          csv += v.to_csv
        }
        return csv
      else
        return WidgetList::Utils::fill(@templateFill, @items['template'])
      end
    end

    def build_pagination()
      pageRange = 3
      pageNext  = 1
      pagePrev  = 1
      showPrev  = false
      showNext  = true
      prevUrl   = ''
      nextUrl   = ''
      tags      = ''
      urlTags   = {}
      templates = {}

      urlTags['SQL_HASH']        = @sqlHash
      urlTags['PAGE_ID']         = @items['pageId']
      urlTags['LIST_NAME']       = @items['name']
      urlTags['BUTTON_VALUE']    = @items['buttonVal']
      urlTags['LIST_FILTER_ALL'] = @items['LIST_FILTER_ALL']

      templates['btn_previous']  = @items['template_pagination_previous_disabled']
      templates['btn_next']      = @items['template_pagination_next_active']

      if $_REQUEST.key?('search_filter') && ! $_REQUEST['search_filter'].empty?
        urlTags['search_filter'] = $_REQUEST['search_filter']
      end

      if @items['LIST_COL_SORT'].empty?
        urlTags['LIST_COL_SORT']       = @items['LIST_COL_SORT']
        urlTags['LIST_COL_SORT_ORDER'] = @items['LIST_COL_SORT_ORDER']
        urlTags['ROW_LIMIT']           = @items['ROW_LIMIT']
      end

      if @items['links'].key?('paginate') && @items['links']['paginate'].class.name == 'Hash'
        @items['links']['paginate'].each { |tagName, tag|
          urlTags[tagName] = tag
        }
      end

      if @items.key?('ajax_action') && ! @items['ajax_action'].empty?
        urlTags['list_action'] = @items['ajax_action']
      end

      @items['carryOverRequsts'].each { |value|
        if $_REQUEST.key?(value)
          urlTags[value] = $_REQUEST[value]
        end
      }
      if (@sequence == @totalPages || ! (@totalPages > 0))
        showNext = false
      else
        urlTags['LIST_SEQUENCE'] = @sequence + 1
        nextUrl = WidgetList::Utils::build_url(@items['pageId'],urlTags,(!$_REQUEST.key?('BUTTON_VALUE')))
      end

      if @sequence > 1
        pagePrev = @sequence - 1
        urlTags['LIST_SEQUENCE'] = pagePrev
        prevUrl = WidgetList::Utils::build_url(@items['pageId'],urlTags,(!$_REQUEST.key?('BUTTON_VALUE')))
        showPrev = true
      end

      if !showNext
        templates['btn_next'] = @items['template_pagination_next_disabled']
      end

      if showPrev
        templates['btn_previous'] = @items['template_pagination_previous_active']
      end

      #Assemble navigation buttons
      #
      pieces = {
        '<!--NEXT_URL-->'     => nextUrl,
        '<!--LIST_NAME-->'    => @items['name'],
        '<!--HTTP_SERVER-->'  => $_SERVER['rack.url_scheme'] + '://' + $_SERVER['HTTP_HOST'] + '/assets/',
        '<!--PREVIOUS_URL-->' => prevUrl,
        '<!--FUNCTION-->'     => @items['ajax_function'],
        '<!--FUNCTION_ALL-->' => @items['ajax_function_all'],
      }

      templates['btn_next']     = WidgetList::Utils::fill(pieces,templates['btn_next'])
      templates['btn_previous'] = WidgetList::Utils::fill(pieces,templates['btn_previous'])

      #
      # Sequence Range Drop Down
      #
      # Show x per page
      #
      urlTags['LIST_SEQUENCE'] = @sequence
      urlTags['ROW_LIMIT']     = 10

      @items['carryOverRequsts'].each { |value|
        if $_REQUEST.key?(value)
          urlTags[value] = $_REQUEST[value]
        end
      }

      # Automate select box and rules
      #
      rowLimitSelect        = [10,20,50,100,500,1000]
      rowLimitSelectData    = {}
      rowLimitSelectConfigs = {}

      #Set a default of 10
      #
      urlTags['ROW_LIMIT'] = 10
      options = ''
      rowLimitSelect.each_with_index { |jumpCount, key|
        if (@totalRows >= jumpCount || @totalRows > rowLimitSelect[key-1])
          urlTags['ROW_LIMIT'] = jumpCount

          rowLimitUrl = WidgetList::Utils::build_url(@items['pageId'],urlTags,(!$_REQUEST.key?('BUTTON_VALUE')))
          selected = ''
          if (@items['rowLimit'] == jumpCount)
            selected = 'selected'
          end
          options += "<option value='#{rowLimitUrl}' #{selected}>#{jumpCount}</option> "
        end
      }

      # WidgetSelect( todo)
      pageSelect = <<-EOD
        <select onchange="#{@items['ajax_function']}(this.value,'#{@items['name']}');#{@items['ajax_function_all']}" style="width:58px">
          #{options}
        </select>
      EOD

      #Ensure the range does not exceed the actual number of pages
      #
      if @totalPages < pageRange
        pageRange = @totalPages
      end

      ###
      # Create a range of x or less numbers.
      #
      # Take 2 off and add 2 or as much as possible either way
      ###
      startingPoint  = @sequence
      vkill          = pageRange

      while vkill > 0 do
        vkill = vkill - 1
        if startingPoint <= 1
          break
        else
          startingPoint = startingPoint-1
        end
      end

      endPoint       = @sequence
      vkill          = pageRange

      while vkill > 0 do
        vkill = vkill - 1
        if endPoint <= 1
          endPoint = endPoint+1
        else
          break
        end
      end

      jumpSection = []

      #Builds jump section    previous 4 5 6 7 next
      #
      for page in startingPoint..endPoint
        urlTags['LIST_SEQUENCE'] = page
        urlTags['SQL_HASH']      = @sqlHash
        jumpTemplate = ''
        jumpUrl = ''
        jumpUrl = WidgetList::Utils::build_url(@items['pageId'], urlTags, (!$_REQUEST.key?('BUTTON_VALUE')))

        if page == @sequence
          jumpTemplate = @items['template_pagination_jump_active']
        else
          jumpTemplate = @items['template_pagination_jump_unactive']
        end

        jumpSection << WidgetList::Utils::fill({
                                                 '<!--SEQUENCE-->'     => page,
                                                 '<!--JUMP_URL-->'     => jumpUrl,
                                                 '<!--LIST_NAME-->'    => @items['name'],
                                                 '<!--FUNCTION-->'     => @items['ajax_function'],
                                                 '<!--FUNCTION_ALL-->' => @items['ajax_function_all'],
                                               }, jumpTemplate)
      end

      pieces = {
        '<!--PREVIOUS_BUTTON-->'         => templates['btn_previous'],
        '<!--SEQUENCE-->'                => @sequence,
        '<!--NEXT_BUTTON-->'             => templates['btn_next'],
        '<!--TOTAL_PAGES-->'             => @totalPages,
        '<!--TOTAL_ROWS-->'              => @totalRows,
        '<!--PAGE_SEQUENCE_JUMP_LIST-->' => pageSelect,
        '<!--JUMP-->'                    => jumpSection.join(''),
        '<!--LIST_NAME-->'               => @items['name'],
      }

      paginationOutput = WidgetList::Utils::fill(pieces,@items['template_pagination_wrapper'])

      if (@items['showPagination'])
        return paginationOutput
      else
        return ''
      end

    end

    def build_headers()
      headers = []
      @items['fields'].each { |field, fieldTitle|
        colWidthStyle = '';
        colClass      = '';
        popupTitle    = '';
        templateIdx   = 'templateNoSortColumn'

        #Column class
        #
        if ! @items['headerClass'].empty?
          if @items['headerClass'].key?(field.downcase)
            colClass = @items['headerClass'][field.downcase]
          end
        end

        #Column width
        #
        if ! @items['columnWidth'].empty?
          if @items['columnWidth'].key?(field.downcase)
            colWidthStyle = "width:" + @items['columnWidth'][field.downcase] + ";"
          end
        end

        if @items['borderedColumns']
          colWidthStyle += 'border-right: ' + @items['borderColumnStyle'] + ';'
        end

        $_SESSION.deep_merge!({'LIST_SEQUENCE' => { @sqlHash => @sequence} })

        #Hover Title
        #
        if @items['columnPopupTitle'].key?(field.downcase)
          popupTitle = @items['columnPopupTitle'][field.downcase]
        end


        #
        # Column is an input
        #
        if @items['inputs'].key?(fieldTitle) && @items['inputs'][fieldTitle].class.name == 'Hash'
          #
          # Default checkbox hover to "Select All"
          #
          # Do specific input type functions
          #
          case @items['inputs'][fieldTitle]['type']
            when 'checkbox'

              if popupTitle.empty? && @items['inputs'][fieldTitle]['items']['check_all']
                popupTitle = 'Select All'
              end

              #
              # No sort on this column
              #
              if ! @items['columnNoSort'].key?(fieldTitle)
                @items['columnNoSort'][field] =  field
              end

              if colClass.empty?
                @items['headerClass'] = { fieldTitle => 'widgetlist-checkbox-header'}
                colClass = @items['headerClass'][fieldTitle]
              end
          end

          #
          # Build the input
          #
          fieldTitle = build_column_input(fieldTitle)

        else

          if $_REQUEST.key?('export_widget_list') && !skip_column(field)
            @csv[0] << fieldTitle
          end

        end

        if (@items['useSort'] && (@items['columnSort'].include?(field) || (@items['columnSort'].key?(field)) && !@items['columnNoSort'].include?(field)) || (@items['columnSort'].empty? && !@items['columnNoSort'].include?(field)))

          templateIdx = 'templateSortColumn'
          colSort = {}

          #Assign the column to be sorted
          #
          if !@items['columnSort'].empty? && @items['columnSort'].key?(field)
            colSort['LIST_COL_SORT'] = @items['columnSort'][field]
          elsif (!@items['columnSort'].empty? && @items['columnSort'].include?(field)) || @items['columnSort'].empty?
            colSort['LIST_COL_SORT'] = field
          end

          colSort['PAGE_ID']             = @items['pageId']
          colSort['LIST_NAME']           = @items['name']
          colSort['BUTTON_VALUE']        = @items['buttonVal']
          colSort['LIST_COL_SORT_ORDER'] = @listSortNext
          colSort['LIST_FILTER_ALL']     = @items['LIST_FILTER_ALL']
          colSort['ROW_LIMIT']           = @items['ROW_LIMIT']
          colSort['LIST_SEQUENCE']       = @sequence

          icon = ""

          if (
          ( (@items.key?('LIST_COL_SORT') && !@items['LIST_COL_SORT'].empty?) && @items['LIST_COL_SORT'] == colSort['LIST_COL_SORT']) ||
            ( $_SESSION.key?('LIST_COL_SORT') &&  $_SESSION['LIST_COL_SORT'].key?(@sqlHash) && $_SESSION['LIST_COL_SORT'][@sqlHash].key?(field))
          )
            changedSession = false
            if @items.key?('LIST_COL_SORT') && !@items['LIST_COL_SORT'].empty?
              changedSession = ( $_SESSION.key?('LIST_COL_SORT') && $_SESSION['LIST_COL_SORT'].key?(@sqlHash) && ! $_SESSION['LIST_COL_SORT'][@sqlHash].key?(@items['LIST_COL_SORT']) )
              if $_SESSION.key?('LIST_COL_SORT') && $_SESSION['LIST_COL_SORT'].key?(@sqlHash)
                $_SESSION['LIST_COL_SORT'].delete(@sqlHash)
              end
              $_SESSION.deep_merge!({'LIST_COL_SORT' => { @sqlHash => {@items['LIST_COL_SORT']=> @items['LIST_COL_SORT_ORDER']  } } })
            end

            if !changedSession && @items.key?('LIST_COL_SORT') && ! @items['LIST_COL_SORT'].empty?
              if @items['LIST_COL_SORT_ORDER'] == 'DESC'
                icon = "&uarr;"
              else
                icon = "&darr;"
              end
            elsif !changedSession && $_SESSION['LIST_COL_SORT'].class.name == 'Hash' && $_SESSION['LIST_COL_SORT'].key?(@sqlHash)
              #load sort from session
              $_SESSION['LIST_COL_SORT'][@sqlHash].each_with_index { |order,void|
                if order[1] == 'DESC'
                  colSort['LIST_COL_SORT_ORDER'] = "ASC"
                  icon = "&uarr;"
                else
                  colSort['LIST_COL_SORT_ORDER'] = "DESC"
                  icon = "&darr;"
                end
              }
            end
          end

          #Carry over any search criteria on a sort to SORT URL
          #
          if $_REQUEST.key?('search_filter') && ! $_REQUEST['search_filter'].empty?
            if $_REQUEST['search_filter'].empty?
              colSort['search_filter'] = $_REQUEST['search_filter']
            end
          end

          @items['carryOverRequsts'].each { |value|
            if $_REQUEST.key?(value)
              colSort[value] = $_REQUEST[value]
            end
          }

          if @items.key?('ajax_action') && ! @items['ajax_action'].empty?
            colSort['list_action'] = @items['ajax_action']
          end
          colSort['SQL_HASH'] = @sqlHash

          pieces = {      '<!--COLSORTURL-->'       => WidgetList::Utils::build_url(@items['pageId'],colSort,(!$_REQUEST.key?('BUTTON_VALUE'))),
                          '<!--NAME-->'             => @items['name'],
                          '<!--COLSORTICON->'       => icon,
                          '<!--COL_HEADER_ID-->'    => strip_tags(field).gsub(/\s/,'_'),
                          '<!--INLINE_STYLE-->'     => colWidthStyle,
                          '<!--TITLE_POPUP-->'      => popupTitle,
                          '<!--COL_HEADER_CLASS-->' => colClass,
                          '<!--TITLE-->'            => fieldTitle,
                          '<!--FUNCTION-->'         => @items['ajax_function'],
                          '<!--FUNCTION_ALL-->'     => @items['ajax_function_all'],
          }
          headers << WidgetList::Utils::fill(pieces, @items[templateIdx])
        else
          pieces = {      '<!--TITLE-->'            => fieldTitle,
                          '<!--INLINE_STYLE-->'     => colWidthStyle,
                          '<!--TITLE_POPUP-->'      => popupTitle,
                          '<!--COL_HEADER_CLASS-->' => colClass,
                          '<!--COL_HEADER_ID-->'    => strip_tags(field).gsub(/\s/,'_')
          }

          headers << WidgetList::Utils::fill(pieces, @items[templateIdx])
        end

      }

      @templateFill['<!--COLSPAN_FULL-->'] = headers.count()

      @templateFill['<!--PAGINATION_LIST-->'] = build_pagination()
      @templateFill['<!--HEADERS-->']         = headers.join('')

      if ! @items['listDescription'].empty?
        fillDesc = {}
        fillDesc['<!--COLSPAN-->']          = headers.count()
        fillDesc['<!--LIST_DESCRIPTION-->'] = @items['listDescription']
        fillDesc['<!--LIST_NAME-->']        = @items['name']
        @templateFill['<!--LIST_TITLE-->']  = WidgetList::Utils::fill(fillDesc,@items['list_description'])
      else
        @templateFill['<!--LIST_TITLE-->'] = ''
      end

    end

    # @param [String] column (the name)
    # @param [Fixnum] row (the id or pointer in the loop to fetch the data)
    def build_column_input(column, row='')
      content = ''

      inputManager = @items['inputs'][column]
      case inputManager['type']
        when "checkbox"


          input = {}
          input['name']         = 'widget_check_name'
          input['id']           = 'widget_check_id'
          input['check_all']    = false
          input['value']        = ''
          input['checked']      = ''
          input['onclick']      = ''
          input['input_class']  = 'widgetlist-checkbox-input'

          input['class_handle'] = ''

          input = WidgetList::Widgets::populate_items(inputManager['items'],input)

          onClick    = []
          checkAllId = ''

          #
          # Get a value. Assumes it is a column initially.
          #
          # @note headers are ignored and would fail as row would be null
          #
          if @results.key?(input['value'].upcase) && !@results[input['value'].upcase][row].to_s.empty?
            input['value'] = @results[ input['value'].upcase ][row]
          end

          #
          # Append class handle
          #
          input['input_class'] = "#{input['input_class']} #{input['class_handle']}"

          if input['check_all']
            checkAllId = input['id']
            if $_SESSION.key?('list_checks') &&  $_SESSION['list_checks'].key?('check_all_' + @sqlHash.to_s  + @items['name'].to_s + @sequence.to_s)
              input['checked'] = true
            end

            #
            # Set header class
            #
            if @items['headerClass'].class.name == 'Array' && @items['headerClass'].key?('checkbox')
              if $_SESSION['list_checks'].key?('check_all_' + @sqlHash.to_s  + @items['name'].to_s + @sequence.to_s)
                input['checked'] = true
              end
            end
          else
            input['input_class'] = "#{input['input_class']} #{input['class_handle']} #{input['class_handle']}_list"
          end

          #
          # Setup onclick action
          #
          if input['onclick'].empty?
            listJumpUrl = {}
            listJumpUrl['BUTTON_VALUE']        = @items['buttonVal']
            listJumpUrl['LIST_COL_SORT']       = @items['LIST_COL_SORT']
            listJumpUrl['LIST_COL_SORT_ORDER'] = @items['LIST_COL_SORT_ORDER']
            listJumpUrl['LIST_FILTER_ALL']     = @items['LIST_FILTER_ALL']
            listJumpUrl['ROW_LIMIT']           = @items['ROW_LIMIT']
            listJumpUrl['LIST_SEQUENCE']       = @sequence
            listJumpUrl['LIST_NAME']           = @items['name']
            listJumpUrl['SQL_HASH']            = @sqlHash
            listJumpUrl['list_action']         = 'ajax_widgetlist_checks'

            onClick << "AjaxMaintainChecks(this, '#{input['class_handle']}', '#{@items['name']}', '" + WidgetList::Utils::build_url(@items['pageId'],listJumpUrl,(!$_REQUEST.key?('BUTTON_VALUE'))) + "', '#{checkAllId}');"
          end

          input['onclick'] = onClick.join(' ')

          #
          # Checkbox is checked or not per query value
          #
          if ! @items['checked_flag'].empty?
            if @items['checked_flag'].key?(column)
              input['checked'] =  !!@results[ @items['checked_flag'][column].upcase ][row]
            end
          end

          #
          # Checkbox is checked or not per session (overwrites query)
          #
          if $_SESSION.key?('list_checks') && $_SESSION['list_checks'].key?(@items['name'] + @sqlHash + input['value'].to_s)
            input['checked'] = true
          end

          content = WidgetList::Widgets::widget_check(input)

        #todo never implemented

        when "text"
          a=1
        #content = WidgetInput()

        when "select"
          a=1
        #content = WidgetSelect()

      end

      return content
    end

    # build_list controls a default AJAX/Export and full HTML return output
    # in some cases you should copy and paste this logic for custom scenarios in your controller, but in most cases, this is okay

    def self.build_list(list_parms)

      list = WidgetList::List.new(list_parms)

      #
      # If AJAX, send back JSON
      #
      if $_REQUEST.key?('BUTTON_VALUE') && $_REQUEST['LIST_NAME'] == list_parms['name']

        if $_REQUEST.key?('export_widget_list')
          return ['export',list.render()]
        end

        ret = {}

        if $_REQUEST['list_action'] != 'ajax_widgetlist_checks'
          ret['list']     = list.render()
          ret['list_id']  = list_parms['name']
          ret['callback'] = 'ListSearchAheadResponse'
        end

        return ['json',WidgetList::Utils::json_encode(ret)]
      else
        #
        # Else assign to variable for view
        #
        return ['html', list.render() ]
      end

    end

    # checkbox_helper just builds the proper Hashes to setup a checkbox widget row
    # it assumes you have a fake column called '' AS checkbox to fill in with the widget_check

    def self.checkbox_helper(list_parms,primary_key)

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
                                        'name'          => list_parms['name'] + '_visible_checks[]',
                                        'value'         => primary_key, #the value should be a column name mapping
                                        'class_handle'  => list_parms['name'] + '_info_tables',
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
                                        'id'            => list_parms['name'] + '_info_tables_check_all',
                                        'class_handle'  => list_parms['name'] + '_info_tables',
                                      }
                                   }
                                }
                             })
      return list_parms
    end

    def self.drill_down_back(list_name='')
      '<div class="goback" onclick="ListHome(\'' + list_name + '\');" title="Go Back"></div>'
    end

    def self.build_drill_down_link(listId,drillDownName,dataToPassFromView,columnToShow,columnAlias='',extraFunction='',functionName='ListDrillDown',columnClass='',color='blue',extraJSFunctionParams='')
      if columnAlias.empty?
        columnAlias = columnToShow
      end

      if !columnClass.empty?
        columnClass = ' "' + WidgetList::List::concat_string() + columnClass + WidgetList::List::concat_string() + '"'
      end

      link = %[#{WidgetList::List::concat_inner()}"<a style='cursor:pointer;color:#{color};' class='#{columnAlias}_drill#{columnClass}' onclick='#{functionName}(#{WidgetList::List::double_quote()}#{drillDownName}#{WidgetList::List::double_quote()}, ListDrillDownGetRowValue(this) ,#{WidgetList::List::double_quote()}#{listId}#{WidgetList::List::double_quote()}#{extraJSFunctionParams});#{extraFunction}'>"#{WidgetList::List::concat_string()}#{columnToShow}#{WidgetList::List::concat_string()}"</a><script class='val-db' type='text'>"#{WidgetList::List::concat_string()} #{dataToPassFromView} #{WidgetList::List::concat_string()}"</script>"#{WidgetList::List::concat_outer()}  as #{columnAlias}]
    end

    def self.concat_string
      case WidgetList::List.get_database.db_type
        when 'mysql'
          ' , '
        when 'oracle','sqlite'
          ' || '
        else
          ','
      end
    end

    def self.double_quote
      case WidgetList::List.get_database.db_type
        when 'mysql'
          '\\"'
        when 'oracle','sqlite'
          '""'
        else
          '"'
      end
    end

    def self.concat_outer
      case WidgetList::List.get_database.db_type
        when 'mysql'
          ')'
        else
          ''
      end
    end

    def self.concat_inner
      case WidgetList::List.get_database.db_type
        when 'mysql'
          'CONCAT('
        else
          ''
      end
    end

    def build_column_button(column,j)
      buttons     = @items['buttons'][column]
      columnValue = @results[column.upcase][j]
      btnOut      = []
      strCnt      = 0
      nameId      = ''

      buttons.each { |buttonId,buttonAttribs|
        #url          = array('PAGE_ID')
        function     = @items['linkFunction']
        parameters   = ''
        renderButton = true

        if buttonAttribs.key?('tags')
          buttonAttribs['tags'].each { | tagName , tag |
            #only uppercase will be replaced
            #

            if @results.key?(tag.upcase) && @results[tag.upcase][j]

              buttonAttribs.deep_merge!({'args' =>
                                           {
                                             tagName => @results[tag.upcase][j]
                                           }
                                        })
            else
              buttonAttribs.deep_merge!({'args' =>
                                           {
                                             tagName => tag
                                           }
                                        })
            end
          }
        end
        nameId = buttonId.to_s + '_' + j.to_s

        buttonAttribs['name'] = nameId
        buttonAttribs['id']   = nameId

        #if  buttonAttribs.key?('condition')
        #never show button if you pass a condition unless explicitly matching the value of the features
        #
        #renderButton = false
        #allConditions = columnValue.split(':')
        #if (in_array(ltrim($buttonAttribs['condition'], ':'), $allConditions))
        #   renderButton = true
        #end
        #end

        if (renderButton)
          strCnt += (buttonAttribs['text'].length * 15)
          btnOut << WidgetList::Widgets::widget_button(buttonAttribs['text'], buttonAttribs, true)
        end
      }

      #BS width algorithm. HACK/TWEAK/OMG Get it working.
      #
      colWidth = ((strCnt + (btnOut.count * 35)) / 2) + 10

      return '<div style="border:0px solid black;text-align:center;white-space:nowrap;margin:auto;width:' + colWidth.to_s + 'px"><div style="margin:auto;display:inline-block">' + btnOut.join('') + '</div></div>'
    end

    # @param [String] column
    def build_column_link(column,j)

      links      = @items['links'][column]
      url        = {'PAGE_ID' => @items['pageId']}
      function   = @items['linkFunction']
      parameters = ''

      if links.key?('PAGE_ID') && ! links['PAGE_ID'].empty?
        url['PAGE_ID'] = links['PAGE_ID']
      end

      if links.key?('ACTION') && ! links['ACTION'].empty?
        url['list_action'] = links['ACTION']
      end

      if links.key?('BUTTON_VALUE') && ! links['BUTTON_VALUE'].empty?
        url['BUTTON_VALUE'] = links['BUTTON_VALUE']
      end

      #todo unit test this and all of column links
      if links.key?('tags')
        links['tags'].each { | tagName, tag |
          if @results[tag][j]
            url[tagName] = @results[tag][j]
          else
            url[tagName] = tag
          end
        }
      end

      if links.key?('onclick') && links['onclick'].class.name == 'Hash'
        if links['onclick'].key?('function') && !links['onclick']['function'].empty?
          function = links['onclick']['function']
        end

        if links['onclick'].key?('tags') && !links['onclick']['tags'].empty?
          links['onclick']['tags'].each { | tagName , tag|
            if @results.key?(tag.upcase)
              parameters = ", '" + @results[tag.upcase][j] + "'"
            end
          }
        end
      end

      if @items.key?('ajax_action') && !@items['ajax_action'].empty?
        url['list_action'] = @items['ajax_action']
      end

      url['SQL_HASH']      = @sqlHash
      linkUrl = WidgetList::Utils::build_url(@items['pageId'], url, (!$_REQUEST.key?('BUTTON_VALUE')))

      "#{function}('#{linkUrl}'#{parameters})"
    end

    def build_rows()
      sql = build_statement()
      if @totalResultCount > 0
        if @items['data'].empty?
          #Run the actual statement
          #
          @totalRowCount = WidgetList::List.get_database._select(sql, @items['bindVars'], @items['bindVarsLegacy'])
        end

        if @totalRowCount > 0
          if @items['data'].empty?
            @results = WidgetList::List.get_database.final_results
          else
            @results = @items['data']
          end

          #Build each row
          #
          max  = @totalRowCount-1
          rows = []
          j    = 0
          for j in j..max
            columns        = []
            row_values     = []
            customRowColor = ''
            customRowStyle = ''

            #
            # For each column (field) in this row
            #

            @items['fields'].each { |column , fieldTitle|
              colPieces        = {}
              colClasses       = []
              theStyle         = ''
              colData          = ''
              colClass         = ''
              onClick          = ''
              colWidthStyle    = ''
              content          = ''
              contentTitle     = ''



              #todo unit test build_column_link

              #
              # Column is a Link
              #
              if @items['links'].key?(column) && @items['links'][column].class.name == 'Hash'
                onClick = build_column_link(column,j)
              end

              #
              # Column is a Button
              #
              if @items['buttons'].key?(column) && @items['buttons'][column].class.name == 'Hash'
                content = build_column_button(column, j)


                #
                # Column is an input
                #
              elsif @items['inputs'].key?(column) && @items['inputs'][column].class.name == 'Hash'
                colClasses << @items['checked_class']
                content = build_column_input(column, j)


                #
                # Column is text
                #
              else
                cleanData = strip_tags(@results[column.upcase][j].to_s)

                row_values << cleanData

                #
                # For now disable length parser
                #
                if false && cleanData.length > @items['strlength']
                  content = @results[column.upcase][j].to_s[ 0, @items['strlength'] ] + '...'
                else
                  content = @results[column.upcase][j].to_s
                end

                #
                #Strip HTML
                #
                if !@items['allowHTML']
                  content = strip_tags(content)
                end

                content = WidgetList::List.get_database._bind(content, @items['bindVarsLegacy'])

                # Column color
                #
                if ! @items['columnStyle'].empty?
                  if @items['columnStyle'].key?(column.downcase)
                    colHeader  = @items['columnStyle'][column.downcase]

                    if @results.key?(colHeader.upcase)
                      theStyle = @results[colHeader.upcase][j]
                    else
                      theStyle = colHeader
                    end

                  end
                end

                # Column width
                #
                if ! @items['columnWidth'].empty?
                  if @items['columnWidth'].key?(column.downcase)
                    colWidthStyle = "width:" + @items['columnWidth'][column.downcase] + ";"
                  end
                end

                # Column Class
                #
                if !@items['columnClass'].empty?
                  if @items['columnClass'].key?(column.downcase)
                    colClasses << @items['columnClass'][column.downcase]
                  end
                end

              end


              #
              # Setup any column classes
              #
              colClasses << @items['collClass']
              colClass = colClasses.join(' ')

              #
              # Row Color
              #
              if !@items['rowColorByStatus'].empty? && @items['rowColorByStatus'].key?(column) &&  !@items['rowColorByStatus'][column].empty?
                @items['rowColorByStatus'][column].each { |status,color|
                  if status === content
                    customRowColor = color
                  end
                }
              end

              #
              # Row Style
              #
              if !@items['rowStylesByStatus'].empty? && @items['rowStylesByStatus'].key?(column) &&  !@items['rowStylesByStatus'][column].empty?
                @items['rowStylesByStatus'][column].each { |status,inlineStyle|
                  if status === content
                    customRowStyle = inlineStyle
                  end
                }
              end

              #
              # Set up Column Pieces
              #
              colPieces['<!--CLASS-->']   = colClass
              colPieces['<!--ALIGN-->']   = @items['collAlign']
              colPieces['<!--STYLE-->']   = theStyle  + colWidthStyle

              if @items['borderedColumns']
                colPieces['<!--STYLE-->'] += 'border-right: ' + @items['borderColumnStyle'] + ';'
              end

              colPieces['<!--ONCLICK-->'] = onClick
              colPieces['<!--TITLE-->']   = contentTitle #todo htmlentities needed ?
              colPieces['<!--CONTENT-->'] = content

              #
              # Assemble the Column
              #
              columns << WidgetList::Utils::fill(colPieces, @items['col'])
            }


            if $_REQUEST.key?('export_widget_list')
              @csv << row_values
            end

            #Draw the row
            #

            pieces = {'<!--CONTENT-->' => columns.join('') }
            if @items['rowColorByStatus'].empty? &&  @items['rowStylesByStatus'].empty?
              #Set the row color
              #
              rowColor = @items['rowColor']

              if @items['offsetRows']
                if( j % 2 ==0)
                  rowColor = @items['rowOffsets'][1]
                else
                  rowColor = @items['rowOffsets'][0]
                end
              end

              #Draw default color
              #
              pieces['<!--BGCOLOR-->']  = rowColor
              pieces['<!--ROWSTYLE-->'] = ''
              pieces['<!--ROWCLASS-->'] = @items['rowClass']
            else
              pieces['<!--BGCOLOR-->']   = !customRowColor.empty? ? customRowColor : @items['rowColor']
              pieces['<!--ROWSTYLE-->']  = !customRowStyle.empty? ? customRowStyle : ''
              pieces['<!--ROWCLASS-->']  = @items['rowClass']
            end
            rows << WidgetList::Utils::fill(pieces, @items['row'])

          end

          @templateFill['<!--DATA-->'] = rows.join('')

        else

          err_message = (WidgetList::List.get_database.errors) ? @items['noDataMessage'] + ' <span style="color:red">(An error occurred)</span>' : @items['noDataMessage']

          @templateFill['<!--DATA-->'] = '<tr><td colspan="50"><div id="noListResults">' + generate_error_output() + err_message + '</div></td></tr>'

        end

      else

        err_message = (WidgetList::List.get_database.errors) ? @items['noDataMessage'] + ' <span style="color:red">(An error occurred)</span>' : @items['noDataMessage']

        @templateFill['<!--DATA-->'] = '<tr><td colspan="50"><div id="noListResults">' + generate_error_output() + err_message + '</div></td></tr>'
      end

    end

    def generate_error_output(ex='')
      sqlDebug = ""
      if Rails.env == 'development'
        sqlDebug += "<br/><br/><textarea style='width:100%;height:400px;'>" + WidgetList::List.get_database.last_sql.to_s + "</textarea>"
      end

      if Rails.env == 'development' && WidgetList::List.get_database.errors
        sqlDebug += "<br/><br/><strong style='color:red'>(" + WidgetList::List.get_database.last_error.to_s + ")</strong>"
      end

      if Rails.env == 'development' && ex != ''
        sqlDebug += "<br/><br/><strong style='color:red'>(" + ex.to_s + ") <pre>"  + $!.backtrace.join("\n\n") +  "</pre></strong>"
      end
      Rails.logger.info sqlDebug

      sqlDebug
    end

    def build_statement()
      statement = ''
      pieces    =       { '<!--FIELDS-->'  => '',
                          '<!--SOURCE-->'  => '',
                          '<!--WHERE-->'   => '',
                          '<!--GROUPBY-->' => '',
                          '<!--ORDERBY-->' => '',
                          '<!--LIMIT-->'   => ''}

      #Build out a list of columns to select from
      #
      @items['fields'].each { |column, fieldTitle|
        if @items['fieldFunction'].key?(column) && !@items['fieldFunction'][column].empty?
          # fieldFunction's should not have an alias, just the database functions
          column = @items['fieldFunction'][column] + " " + column
        end

        @fieldList << column
      }

      viewPieces = {}
      viewPieces['<!--FIELDS-->'] = @fieldList.join(',')
      viewPieces['<!--SOURCE-->'] = @items['view']

      statement = WidgetList::Utils::fill(viewPieces, @items['statement']['select']['view'])

      @sqlHash = Digest::SHA2.hexdigest( WidgetList::Utils::fill(pieces, statement) )

      if @items['searchClear'] || @items['searchClearAll']
        clear_sql_session(@items.key?('searchClearAll'))
      end

      if !$_REQUEST.key?('BUTTON_VALUE') && $_SESSION.key?('LIST_SEQUENCE') && $_SESSION['LIST_SEQUENCE'].key?(@sqlHash) &&  $_SESSION['LIST_SEQUENCE'][@sqlHash] > 0
        @sequence = $_SESSION['LIST_SEQUENCE'][@sqlHash]
        generate_limits
      end

      if !@filter.empty?
        pieces['<!--WHERE-->'] = ' WHERE ' + @filter
      end

      if !@items['groupBy'].empty?
        pieces['<!--GROUPBY-->'] += ' GROUP BY ' + @items['groupBy']
      end

      if !@items['LIST_COL_SORT'].empty? || ($_SESSION.key?('LIST_COL_SORT') && $_SESSION['LIST_COL_SORT'].class.name == 'Hash' && $_SESSION['LIST_COL_SORT'].key?(@sqlHash))
        if ! @items['LIST_COL_SORT'].empty?
          if @items['fields'].key?(@items['LIST_COL_SORT'])
            pieces['<!--ORDERBY-->'] += ' ORDER BY ' + tick_field() + @items['LIST_COL_SORT'] + tick_field() + " " + @items['LIST_COL_SORT_ORDER']
          end
        else
          $_SESSION['LIST_COL_SORT'][@sqlHash].each_with_index { |order,void|
            if @items['fields'].key?(order[0])
              pieces['<!--ORDERBY-->'] += ' ORDER BY ' + tick_field() + order[0] + tick_field() +  " " + order[1]
            end
          } if $_SESSION.key?('LIST_COL_SORT') && $_SESSION['LIST_COL_SORT'].class.name == 'Hash' && $_SESSION['LIST_COL_SORT'].key?(@sqlHash)
        end

        # Add base order by
        if ! @items['orderBy'].empty?
          pieces['<!--ORDERBY-->'] += ',' + @items['orderBy']
        end

      elsif !@items['orderBy'].empty?
        pieces['<!--ORDERBY-->'] += ' ORDER BY ' + @items['orderBy']
      end

      if WidgetList::List.get_database.db_type == 'oracle' && pieces['<!--ORDERBY-->'].empty?
        keys = @items['fields'].keys
        pieces['<!--ORDERBY-->'] += ' ORDER BY ' + keys.first + ' ASC'
      end

      case WidgetList::List.get_database.db_type
        when 'postgres'
          pieces['<!--LIMIT-->'] = ' LIMIT :HIGH OFFSET :LOW'
        when 'oracle'
          pieces['<!--LIMIT-->'] = ''

          if !@filter.empty?
            and_where = ' AND '
          else
            and_where = ' WHERE '
          end
          pieces['<!--WHERE-->'] += and_where +
            '
            (
                 a.rn >= :LOW
              AND
                 a.rn <= :HIGH
            )
            '
        else
          pieces['<!--LIMIT-->'] = ' LIMIT :LOW, :HIGH'
      end


      statement = WidgetList::Utils::fill(pieces, statement)

      if @items['rowLimit'] >= @totalRows
        @items['bindVarsLegacy']['LOW'] = 0
        @sequence = 1
      end

      statement
    end

    def auto_column_name(name='')
      name.gsub(/\_/,' ').gsub(/\-/,' ').capitalize
    end

    def get_total_records()

      filter = ''
      fields = {}
      sql    = ''
      hashed = false
      
      if !@items['view'].empty?
        sql = WidgetList::Utils::fill({'<!--VIEW-->' => @items['view']}, @items['statement']['count']['view'])
      end

      if ! @filter.empty?
        filter = ' WHERE ' + @filter
      end

      sql = WidgetList::Utils::fill({'<!--WHERE-->' => filter}, sql)

      if ! sql.empty?
        if @items['showPagination']
          if WidgetList::List.get_database._select(sql, @items['bindVars'], @items['bindVarsLegacy']) > 0
            rows = WidgetList::List.get_database.final_results['TOTAL'][0]
          else
            rows = 0
          end
          if rows > 0
            @totalRows = rows
          end
        else
          rows = 1
        end
      else
        rows = 0
      end

      if @totalRows > 0
        @totalPages = (@totalRows.to_f / @items['rowLimit'].to_f).ceil()
      end

      rows
    end

  end

end