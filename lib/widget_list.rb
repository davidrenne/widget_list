require 'ransack'
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

module WidgetList

  #
  # WidgetList Administration/Setup
  #
  def self.go!()
    if $_REQUEST.key?('iframe')
      eval(WidgetList::Administration.new.translate_config_to_code())
      return @output
    else
      list = WidgetList::List.new()
      return list.render()
    end
  end

  class Administration
    def show_interface()
      config_file = Rails.root.join("config", "widget-list-administration.json")
      config_file_all = Rails.root.join("config", "widget-list-administration-all.json")
      if config_file.file? && !$_REQUEST.key?('ajax') && !$_REQUEST.key?('name')
        File.delete(Rails.root.join("config", "widget-list-administration.json"))
      end


      ac = ActionController::Base.new()
      default_config = WidgetList::List::get_defaults()
      config_id, page_config = get_configuration()
      page_json   = JSON.parse(ajax_get_field_json(page_config['view']))


      #Loop models
      models = Dir[ Rails.root.join("app", "models").to_s + '**/*'].reject {|fn| File.directory?(fn) }
      if !models.empty?
        model_options = '<option value="">Select a Model</option>' + models.collect { |model|
          model_name = model.split('/').last.to_s.camelize.gsub(/.rb/,'')
          "<option value='#{model_name}' #{((@isEditing && page_config['view'] == model_name) ? 'selected' : '')}>#{model_name}</option>"
        }.sort.uniq.join('')
      else
        model_options = '<option value="">No Models Found in ' + Rails.root.join("app", "models").to_s + '</option>'
      end

      #Groupings
      #default_grouping  : editing_grouping

      @fill = {}
      #
      # Writing most of this interface while drunk trancing/coding out on ah.fm.
      # This administration form should help people new to widget_list to easily stub out new implementations
      #

      #
      # INIT PROMPT
      #

      if config_file_all.file? && !$_REQUEST.key?('restore')
        @fill['<!--BUTTON_CSS-->']       = 'style="display:none"'
        @fill['<!--START_CSS-->']        = 'style="display:none"'
        options = ''
        json = JSON.parse(File.new(Rails.root.join("config", "widget-list-administration-all.json")).read)
        json.keys.each { |val|
          void, controller_action = val.split('|')
          controller, action = controller_action.split('-')
          options += '<option value="' + val + '">' + (json[val].key?('savedOn') ? "(on #{json[val]['savedOn']}) - " : '') + controller + '/' + action + ' => Model used is "' + json[val]['view'] + '"</option>'
        }
        @fill['<!--EDIT_OR_ADD_NEW-->']  = WidgetList::Utils::fill({
                                                                       '<!--NEW-->'   => WidgetList::Widgets::widget_button('New',   { 'onclick' => "ClickTab('.start','ShowStart',true);jQuery('#sections').fadeIn('slow');"  , 'innerClass'  => "primary"  } ),
                                                                       '<!--EDIT-->'  => WidgetList::Widgets::widget_button('Edit',   { 'onclick' => "isSubmitting = true; document.location = document.location + '?restore=' + escape(jQuery('#edit_widget_list').val());"  , 'innerClass'  => "primary"  } ),
                                                                       '<!--ITEMS-->' => '<select name="edit_widget_list" id="edit_widget_list">' + options + '</select>',
                                                                   } ,'
                                                                      <tr class="init">
                                                                        <td>
                                                                          <h3>Start a New Widget List <!--NEW--></h3>
                                                                        </td>
                                                                        <td>
                                                                          <h3>Edit Existing: <!--ITEMS--> <!--EDIT--></h3>
                                                                        </td>
                                                                        <td>
                                                                          &#160;
                                                                        </td>
                                                                      </tr>')
      else
        @fill['<!--BUTTON_CSS-->'] = ''
        @fill['<!--START_CSS-->']  = ''
      end

      #
      # BASE
      #
      @fill['<!--POST_URL-->']                  = $_SERVER['SCRIPT_NAME'] + $_SERVER['PATH_INFO']
      @fill['<!--BUTTONS-->']                   = WidgetList::Widgets::widget_button('Step One - Start ->',           {'id' => 'start'      , 'onclick' => "ShowStart();"    , 'innerClass' => "primary"  } ) +
          WidgetList::Widgets::widget_button('Step Two - Fields ->',          {'id' => 'fields'     , 'onclick' => "ShowFields();"  , 'innerClass' => "primary disabled"  } ) +
          WidgetList::Widgets::widget_button('Step Three - Rows ->',          {'id' => 'rows'       , 'onclick' => "ShowRows();"    , 'innerClass' => "primary disabled"  } ) +
          WidgetList::Widgets::widget_button('Step Four - Search ->',         {'id' => 'search'     , 'onclick' => "ShowSearch();"  , 'innerClass' => "primary disabled"  } ) +
          WidgetList::Widgets::widget_button('Step Four - Footer Actions ->', {'id' => 'footer'     , 'onclick' => "ShowFooter();"  , 'innerClass' => "primary disabled"  } ) +
          WidgetList::Widgets::widget_button('Step Five - Misc & Submit ->',  {'id' => 'misc_submit', 'onclick' => "ShowSubmit();"  , 'innerClass' => "success disabled"  } )


      #
      # START
      #
      @fill['<!--TITLE-->']                     = 'Stub Out A New WidgetList Implementation'
      @fill['<!--CONTROLLER_VALUE-->']          = (!@isEditing) ? $_REQUEST['controller'] : page_config['desiredController']
      @fill['<!--ACTION_VALUE-->']              = (!@isEditing) ? $_REQUEST['action'] : page_config['desiredAction']
      @fill['<!--NAME_VALUE-->']                = (!@isEditing) ? config_id : page_config['name']
      @fill['<!--VIEW_OPTIONS-->']              = model_options
      @fill['<!--TITLE_VALUE-->']               = (!@isEditing) ? '' : page_config['title']
      @fill['<!--DESC_VALUE-->']                = (!@isEditing) ? '' : page_config['listDescription']
      @fill['<!--PRIMARY_CHECKED-->']           = (!@isEditing) ? 'checked' : (page_config['primaryDatabase'] == "1") ? 'checked' : ''

      #
      # FIELD LEVEL
      #

      @fill['<!--NO_DATA_VALUE-->']             = (!@isEditing) ? ''        : page_config['noDataMessage']
      @fill['<!--SORTING_CHECKED-->']           = (!@isEditing) ? 'checked' : (page_config['useSort'] == "1") ? 'checked' : ''

      @fieldFill     = {}
      @fieldFill['<!--REMOVE_FIELD_BUTTON-->']  = remove_field_button() + WidgetList::Widgets::widget_button('Hide',  {'onclick' => "MoveField(this)", 'innerClass' => "danger" }, true ) + WidgetList::Widgets::widget_button('Function',  {'onclick' => "AddFunction(this)", 'innerClass' => "success" }, true ) + WidgetList::Widgets::widget_button('Options',  {'onclick' => "ShowOptions(this)", 'innerClass' => "info" }, true )
      @fieldFill['<!--FIELD_VALUE-->']          = ''
      @fieldFill['<!--FIELD_DESC-->']           = ''
      @fieldFill['<!--SUBJECT-->']              = 'fields'
      @fieldFill['<!--FIELD-->']                = 'Field'
      @fieldFill['<!--DESC-->']                 = 'Desc'
      @fieldFill['<!--DISABLED-->']             = ''
      @fieldFill['<!--TR_STYLE-->']             = ''

      @fieldFillRow2 = {}
      @fieldFillRow2['<!--REMOVE_FIELD_BUTTON-->']  = 'Link To:&#160;<br/><br/><input type="text" style="width:350px" class="misc_links" onblur="jQuery(this).attr(\'value\',jQuery(this).val().trim());" name="misc[link][]" id="misc[link][]" value=""/>' + WidgetList::Widgets::widget_button('?',  {'onclick' => "alert('Please use /my_page/field_name/field_name/ and it will be linked and replaced with the column value.')", 'innerClass' => "default" }, true )
      @fieldFillRow2['<!--FIELD_VALUE-->']          = ''
      @fieldFillRow2['<!--FIELD_DESC-->']           = ''
      @fieldFillRow2['<!--SUBJECT-->']              = 'misc'
      @fieldFillRow2['<!--FIELD-->']                = 'Column Width<br/><br/>'
      @fieldFillRow2['<!--DESC-->']                 = 'Header Title Popup<br/><br/>'
      @fieldFillRow2['<!--DISABLED-->']             = ''
      @fieldFillRow2['<!--TR_STYLE-->']             = 'display:none'
      @fieldFillRow2['<!--TR1_STYLE-->']            = 'padding-left:100px'

      @fieldFill['<!--EXTRA-->']                    = WidgetList::Utils::fill(@fieldFillRow2 , ac.render_to_string(:partial => 'widget_list/administration/field_row') )


      @fieldFillRow3 = {}

      @fieldFillRow3['<!--1_DESC-->']               = 'Searchable?<br/><br/>'
      @fieldFillRow3['<!--1_KEY-->']                = 'searchable'
      @fieldFillRow3['<!--1_VALUE-->']              = 'checked'

      @fieldFillRow3['<!--2_DESC-->']               = 'Summarize Totals?<br/><br/>'
      @fieldFillRow3['<!--2_KEY-->']                = 'summarize'
      @fieldFillRow3['<!--2_HELP-->']               = 'If this is a numeric column, the widget_list will add a record at the bottom of all your results adding up every value'
      @fieldFillRow3['<!--2_VALUE-->']              = ''

      @fieldFillRow3['<!--3_DESC-->']               = 'Sortable?'
      @fieldFillRow3['<!--3_KEY-->']                = 'sortable'
      @fieldFillRow3['<!--3_VALUE-->']              = 'checked'

      @fieldFillRow3['<!--SUBJECT-->']              = 'flags'
      @fieldFillRow3['<!--CHECKBOX_STYLE-->']       = 'display:none;'

      @fieldFill['<!--EXTRA-->']                   += WidgetList::Utils::fill(@fieldFillRow3 , ac.render_to_string(:partial => 'widget_list/administration/checkbox_row') )

      #Fill all three rows now for default template
      @fill['<!--FIELD_TEMPLATE-->']            = WidgetList::Utils::fill(@fieldFill , ac.render_to_string(:partial => 'widget_list/administration/field_row') )
      @fill['<!--ADD_FIELD_BUTTON-->']          = WidgetList::Widgets::widget_button('Add Field',  {'onclick' => "AddField();", 'innerClass' => "success" } )
      @fill['<!--ALL_FIELDS-->']                = (!@isEditing) ? '' : page_json['fields']


      @fill['<!--SHOW_HIDDEN_CHECKED-->']       = (!@isEditing) ? '' : (page_config['showHidden'] == "1")  ? 'checked' : ''
      @fieldFill = {}
      @fieldFill['<!--REMOVE_FIELD_BUTTON-->']  = remove_field_button() + WidgetList::Widgets::widget_button('Show',  {'onclick' => "ShowField(this)", 'innerClass' => "success" }, true )
      @fieldFill['<!--FIELD_VALUE-->']          = ''
      @fieldFill['<!--FIELD_DESC-->']           = ''
      @fieldFill['<!--SUBJECT-->']              = 'fields_hidden'
      @fieldFill['<!--FIELD-->']                = 'Field'
      @fieldFill['<!--DESC-->']                 = 'Desc'
      @fieldFill['<!--DISABLED-->']             = 'disabled'
      @fieldFill['<!--TR_STYLE-->']             = ''
      @fill['<!--HIDDEN_FIELD_TEMPLATE-->']     = WidgetList::Utils::fill(@fieldFill , ac.render_to_string(:partial => 'widget_list/administration/field_row') )
      @fill['<!--ADD_HIDDEN_FIELD_BUTTON-->']   = WidgetList::Widgets::widget_button('Add Hidden Field',  {'onclick' => "AddHiddenField();", 'innerClass' => "success" } )
      @fill['<!--ALL_HIDDEN_FIELDS-->']         = (!@isEditing) ? '' : page_json['fields_hidden']


      @fill['<!--SHOW_FUNCTION_CHECKED-->']     = (!@isEditing) ? '' : (page_config['fieldFunctionOn'] == "1") ? 'checked' : ''
      @fieldFill = {}
      @fieldFill['<!--REMOVE_FIELD_BUTTON-->']  = remove_field_button()
      @fieldFill['<!--FIELD_VALUE-->']          = ''
      @fieldFill['<!--FIELD_DESC-->']           = ''
      @fieldFill['<!--SUBJECT-->']              = 'fields_function'
      @fieldFill['<!--FIELD-->']                = 'Field'
      @fieldFill['<!--DESC-->']                 = 'Database Function'
      @fieldFill['<!--DISABLED-->']             = ''
      @fieldFill['<!--TR_STYLE-->']             = ''
      @fill['<!--FIELD_FUNCTION_TEMPLATE-->']   = WidgetList::Utils::fill(@fieldFill , ac.render_to_string(:partial => 'widget_list/administration/field_row') )
      @fill['<!--ADD_FIELD_FUNCTION_BUTTON-->'] = WidgetList::Widgets::widget_button('Add Function',  {'onclick' => "AddFieldFunction();", 'innerClass' => "success" } )
      @fill['<!--ALL_FIELD_FUNCTIONS-->']       = (!@isEditing) ? '' : page_json['fields_function']

      #
      # ROW LEVEL
      #

      @fill['<!--ROW_LIMIT_VALUE-->']           = (!@isEditing) ? default_config['rowLimit'] : page_config['rowLimit']
      @fill['<!--BUTTON_NAME_VALUE-->']         = (!@isEditing) ? 'Actions' : page_config['rowButtonsName']
      @fill['<!--BUTTONS_ON_CHECKED-->']        = (!@isEditing) ? '' : (page_config['rowButtonsOn'] == "1")  ? 'checked' : ''
      @fill['<!--DRILL_DOWN_CHECKED-->']        = (!@isEditing) ? '' : (page_config['drillDownsOn'] == "1")  ? 'checked' : ''

      @fieldFill = {}
      @fieldFill['<!--REMOVE_FIELD_BUTTON-->']  = remove_field_button()
      @fieldFill['<!--BUTTON_TEXT-->']          = 'Button Text'
      @fieldFill['<!--BUTTON_URL-->']           = (!@isEditing) ? '/' : '/' + page_config['desiredController'] + '/'
      @fieldFill['<!--BUTTON_CLASS-->']         = 'info'
      @fieldFill['<!--ONBLUR3-->']              = 'GoodClass(this)'

      @fieldFill['<!--TEXT_DESC-->']            = 'Text'
      @fieldFill['<!--TEXT_KEY-->']             = 'text'
      @fieldFill['<!--TEXT_HELP-->']            = 'The Button Text'

      @fieldFill['<!--URL_DESC-->']             = 'URL'
      @fieldFill['<!--URL_KEY-->']              = 'url'
      @fieldFill['<!--URL_HELP->']              = 'URLs include a RESTful path where you will pass controller/field_name/field_name/ where those will be replaced'

      @fieldFill['<!--COLOR_DESC-->']           = 'Color'
      @fieldFill['<!--COLOR_KEY-->']            = 'class'
      @fieldFill['<!--COLOR_HELP-->']           = 'primary=(blue) info=(light-blue) success=(green) danger=(red) disabled=(light grey) default=(grey)'
      @fieldFill['<!--SUBJECT-->']              = 'buttons'

      @fill['<!--THE_BUTTON_TEMPLATE-->']       = WidgetList::Utils::fill(@fieldFill , ac.render_to_string(:partial => 'widget_list/administration/button_row') )
      @fill['<!--ADD_THE_BUTTON_BUTTON-->']     = WidgetList::Widgets::widget_button('Add Button To Each Row',  {'onclick' => "AddButton();", 'innerClass' => "info" } )
      @fill['<!--ALL_BUTTONS-->']               = page_json['buttons']

      @fieldFill = {}
      @fieldFill['<!--REMOVE_FIELD_BUTTON-->']  = remove_field_button()
      @fieldFill['<!--BUTTON_TEXT-->']          = 'filter_col_name'
      @fieldFill['<!--BUTTON_URL-->']           = 'col_name'
      @fieldFill['<!--BUTTON_CLASS-->']         = 'col_name'
      @fieldFill['<!--ONBLUR2-->']              = 'ReplaceColumnsToLinked(this)'
      @fieldFill['<!--ONBLUR3-->']              = 'ReplaceColumnsToLinked(this)'

      @fieldFill['<!--TEXT_DESC-->']            = 'Internal Filter Name (:drill_down_name)<br/>'
      @fieldFill['<!--TEXT_KEY-->']             = 'drill_down_name'
      @fieldFill['<!--TEXT_HELP-->']            = ':drill_down_name is a parameter of build_drill_down that is what is passed and returned from get_filter_and_drilldown when you handle the request after clicked'

      @fieldFill['<!--URL_DESC-->']             = 'Data To Pass From View (:data_to_pass_from_view)<br/>'
      @fieldFill['<!--URL_KEY-->']              = 'data_to_pass_from_view'
      @fieldFill['<!--URL_HELP->']              = ':data_to_pass_from_view is the internal/hidden value that is inserted into a hidden <script> id block and passed when clicked'

      @fieldFill['<!--COLOR_DESC-->']           = 'Column to Show (:column_to_show)<br/>'
      @fieldFill['<!--COLOR_KEY-->']            = 'column_to_show'
      @fieldFill['<!--COLOR_HELP-->']           = ':column_to_show should either be the column or possibly a formatted column like CONCAT or COUNT'
      @fieldFill['<!--SUBJECT-->']              = 'drill_downs'

      @fill['<!--THE_DRILL_DOWN_TEMPLATE-->']   = WidgetList::Utils::fill(@fieldFill , ac.render_to_string(:partial => 'widget_list/administration/button_row') )
      @fill['<!--ADD_DRILL_DOWN_BUTTON-->']     = WidgetList::Widgets::widget_button('Add New Drill Down',  {'onclick' => "AddDrillDown();", 'innerClass' => "success" } )
      @fill['<!--ALL_DRILL_DOWNS-->']           = page_json['drill_downs']

      #
      # SEARCH
      #
      @fill['<!--SHOW_SEARCH_CHECKED-->']       = (!@isEditing) ? 'checked' : (page_config['showSearch'] == "1")  ? 'checked' : ''
      @fill['<!--SHOW_EXPORT_CHECKED-->']       = (!@isEditing) ? 'checked' : (page_config['showExport'] == "1")  ? 'checked' : ''
      @fill['<!--EXPORT_VALUE-->']              = (!@isEditing) ? default_config['exportButtonTitle'] : page_config['exportButtonTitle']
      @fill['<!--USE_RANSACK-->']               = (!@isEditing) ? ($is_mongo) ? '' : 'checked' : (page_config['useRansack'] == "1")  ? 'checked' : ''
      @fill['<!--USE_RANSACK_ADV-->']           = (!@isEditing) ? ''        : (page_config['ransackAdvancedForm'] == "1")  ? 'checked' : ''
      @fill['<!--USE_GROUPING-->']              = (!@isEditing) ? ''        : (page_config['useGrouping'] == "1") ? 'checked' : ''
      @fill['<!--SEARCH_TITLE-->']              = (!@isEditing) ? default_config['searchTitle'] : page_config['searchTitle']

      @fieldFill = {}
      @fieldFill['<!--REMOVE_FIELD_BUTTON-->']  = remove_field_button()
      @fieldFill['<!--FIELD_VALUE-->']          = 'column_name'
      @fieldFill['<!--FIELD_DESC-->']           = 'User Desc'
      @fieldFill['<!--SUBJECT-->']              = 'group_by'
      @fieldFill['<!--FIELD-->']                = 'Field'
      @fieldFill['<!--DESC-->']                 = 'Desc'
      @fieldFill['<!--DISABLED-->']             = ''
      @fieldFill['<!--ONBLUR1-->']              = 'InvalidField(this)'
      @fieldFill['<!--TR_STYLE-->']             = ''
      @fill['<!--DEFAULT_GROUPING-->']          = WidgetList::Utils::fill(@fieldFill , ac.render_to_string(:partial => 'widget_list/administration/field_row') )
      @fill['<!--ADD_GROUP_BY_BUTTON-->']       = WidgetList::Widgets::widget_button('Add New Group By',  {'onclick' => "AddGroupBy();", 'innerClass' => "success" } )
      @fill['<!--GROUPING_ITEMS-->']            = (!@isEditing) ? '' : page_json['group_by']



      #
      # FOOTER
      #

      @fieldFill = {}
      @fieldFill['<!--REMOVE_FIELD_BUTTON-->']  = remove_field_button()
      @fieldFill['<!--BUTTON_TEXT-->']          = 'Button Text'
      @fieldFill['<!--BUTTON_URL-->']           = (!@isEditing) ? '/' : '/' + page_config['desiredController'] + '/your_action'
      @fieldFill['<!--BUTTON_CLASS-->']         = 'info'

      @fieldFill['<!--TEXT_DESC-->']            = 'Text'
      @fieldFill['<!--TEXT_KEY-->']             = 'text'
      @fieldFill['<!--TEXT_HELP-->']            = 'The Button Text'

      @fieldFill['<!--URL_DESC-->']             = 'URL'
      @fieldFill['<!--URL_KEY-->']              = 'url'
      @fieldFill['<!--URL_HELP->']              = 'URLs include a RESTful path where you will pass controller/field_name/field_name/ where those will be replaced'

      @fieldFill['<!--COLOR_DESC-->']           = 'Color'
      @fieldFill['<!--COLOR_KEY-->']            = 'class'
      @fieldFill['<!--COLOR_HELP-->']           = 'primary=(blue) info=(light-blue) success=(green) danger=(red) disabled=(light grey) default=(grey)'
      @fieldFill['<!--SUBJECT-->']              = 'footer_buttons'

      @fieldFill['<!--ONBLUR3-->']              = 'GoodClass(this)'
      @fill['<!--FOOTER_BUTTON_TEMPLATE-->']    = WidgetList::Utils::fill(@fieldFill , ac.render_to_string(:partial => 'widget_list/administration/button_row') )
      @fill['<!--ADD_THE_FOOTER_BUTTON-->']     = WidgetList::Widgets::widget_button('Add Footer Button',  {'onclick' => "AddFooterButton();", 'innerClass' => "success" } )
      @fill['<!--ALL_FOOTER_BUTTONS-->']        = page_json['footer_buttons']
      @fill['<!--FOOTER_CHECKED-->']            = (!@isEditing) ? '' : (page_config['footerOn'] == "1")  ? 'checked' : ''
      @fill['<!--PAGINATION_CHECKED-->']        = (!@isEditing) ? 'checked' : (page_config['showPagination'] == "1")  ? 'checked' : ''




      #
      # MISC & SUBMIT
      #

      @fill['<!--SHOW_CHECKBOX_CHECKED-->']     = (!@isEditing) ? ''        : (page_config['checkboxEnabled'] == "1")  ? 'checked' : ''
      @fill['<!--CHECKBOX_SELECTED_FIELDS-->']  = (!@isEditing) ? ''        : build_field_options(page_json['all_fields'], page_config['checkboxField'])
      @fill['<!--SUBMIT_WIDGET_LIST-->']        = WidgetList::Widgets::widget_button('Submit',  {'onclick' => "Submit();"  , 'innerClass' => "success"  } )

      #
      # HELP BUTTONS
      #
      @help = {}
      @help['<!--TITLE_HELP_BUTTON-->']         = "The title list_params will show above the list similar to the title of this page to stub out an implementation of the list."
      @help['<!--RANSACK_HELP_BUTTON-->']       = "Ransack gem will provide multiple column filtering abilities in the advanced drop down arrow form"
      @help['<!--SEARCH_TITLE_BUTTON-->']       = "This is the grey description of the wild card search"
      @help['<!--HIDDEN_HELP_BUTTON-->']        = "Hidden fields are not shown, but you can use the record values inside of important tags passed from buttons and drill downs"
      @help['<!--CHECK_HELP_BUTTON-->']         = "This value is supposed to be the primary key to identify the row"
      @help['<!--ACTION_HELP_BUTTON-->']        = "Internal use only reserved for future use.  Not really important as of yet"
      @help['<!--NAME_HELP_BUTTON-->']          = "The name of the controller drives most session level storage and javascript pointers and IDs of a list"
      @help['<!--ROW_HELP_BUTTON-->']           = "10,20,50,100,500,1000 are supported"
      @help['<!--CONTROLLER_HELP_BUTTON-->']    = "Controller is used to generate button URLs internally in this utility and as a way to restore configurations for future editing and code re-generation"
      @help['<!--DRILL_DOWN_HELP_BUTTON-->']    = "Link drill downs allow you to build a link around a field value, in which allows you to select which column value to pass to a drill down.  It allows you to CONCAT or run a query for the display of the column and it then handles the filtering of the data"
      @help['<!--FUNC_HELP_BUTTON-->']          = "A fieldFunction is a wrapper to call functions around columns that exist or possibly adding new fields that dont exist.  It is good for formatting data after the where clause."
      @help['<!--GROUP_BY_HELP_BUTTON-->']      = "Enter a field name to group by and a description to show to the user.  If you leave the field name blank it will NOT group by the field, but will show all records"
      @help['<!--BUTTON_HELP_BUTTON-->']        = "For each record.  Add several buttons which will pass tags which are the record values to another page or javascript function"
      @help['<!--ADV_RANSACK_HELP_BUTTON-->']   = "By default, widget_list will build the advanced form for you when this option is unchecked.  By checking, the code builder will place the advanced form inside your controller so you can add additional filtering options you will have to handle on your own"

      @help.each { |k,v|
        @fill[k]   =  WidgetList::Widgets::widget_button('?',  {'onclick' => "alert('" + v + "')", 'innerClass' => "default" }, true )
      }


      return WidgetList::Utils::fill(@fill , ac.render_to_string(:partial => 'widget_list/administration/output') )
    end

    def add_pointer(key,subtract=0)
      whitespace = 31 - subtract
      "['#{key}'] " + "".ljust(whitespace - key.length) + " = "
    end

    def add_conditional(key,conditional)
      whitespace = 19
      "'#{escape_code key}' " + "".ljust(whitespace - key.length) + " #{conditional}"
    end

    def escape_code(code)
      if $_REQUEST.key?('iframe')
        #It is so weird, during output return, you need an extra slash to populate the code properly, but during rendering this is needed
        code.gsub(/'/,"\\\\'")
      else
        code.gsub(/'/,"\\\\\\\\'")
      end
    end

    def translate_config_to_code()
      config_id, page_config = get_configuration()
      fields,fields_hidden,fields_function,buttons,footer_buttons,group_by,drill_downs,flags,misc = normalize_configs(page_config)

      drill_down_code  = ''
      case_statements  = ''
      case_statements2 = ''
      view_code        = ''
      export_code      = ''
      visible_field_code       = ''
      hidden_field_code       = ''
      variable_code    = ''
      checkbox_code    = ''
      button_code      = ''
      grouping_code    = ''
      grouping_code2   = ''
      search_out       = ''
      field_function_code      = ''
      database_type    = WidgetList::List.get_db_type(page_config['primaryDatabase'] == '1' ? true : false)
      using_grouping   = (page_config['useGrouping'] == '1' && page_config['showSearch'] == '1' && !group_by.empty?)
      #------------ DRILL DOWNS ------------
      if page_config['drillDownsOn'] == "1" && !drill_downs.empty?

        search_out += "

      #
      # Search Fields Removed
      #
      list_parms['searchFieldsOut'] = {}"

        drill_downs.each { |field|

          search_out += "
      list_parms['searchFieldsOut']#{add_pointer(field[1]['column_to_show'],9)} true"

          column_to_show = "'#{field[1]['column_to_show'].gsub(/_linked/,'')}'"
          if using_grouping
            if database_type == 'oracle'
              column_to_show = "groupByFilter == 'none' ? '#{escape_code field[1]['column_to_show'].gsub(/_linked/,'')}' : 'MAX(#{escape_code field[1]['column_to_show'].gsub(/_linked/,'')})'"
            end
          end

          field_function_code += "
      list_parms['fieldFunction']#{add_pointer(field[1]['column_to_show'],7)} WidgetList::List::build_drill_down(
        :list_id => list_parms['name'],
        :drill_down_name => '#{escape_code field[0]}',
        :data_to_pass_from_view => #{column_to_show},
        :column_to_show => #{column_to_show},
        :column_alias => '#{escape_code field[1]['column_to_show']}',
        :primary_database => #{page_config['primaryDatabase'] == '1' ? 'true' : 'false'}
      )"
          if $is_mongo
            code = "filterValue"
          else
            code = "#{page_config['view']}.sanitize(filterValue)"
          end
          case_statements += <<-EOD

        when '#{field[0]}'
          list_parms['filter']          << " #{field[1]['column_to_show'].gsub(/_linked/,'')} = ? "
          list_parms['bindVars']        << #{code}
          list_parms['listDescription']  = drillDownBackLink + ' Filtered by #{escape_code field[1]['column_to_show'].gsub(/_linked/,'').camelize} (' + filterValue + ')'
          EOD
        }

        drill_down_code = <<-EOD

      #
      # Handle Dynamic Filters
      #

      drillDown, filterValue  = WidgetList::List::get_filter_and_drilldown(list_parms['name'])

      drillDownBackLink       = WidgetList::List::drill_down_back(list_parms['name'])
      case drillDown#{case_statements}
        else
          list_parms['listDescription']  = '#{escape_code page_config['listDescription']}'
      end
        EOD

      else
        drill_down_code = "
      list_parms['listDescription']   = '#{escape_code page_config['listDescription']}'
        "
      end


      searchables = flags['searchable'].select {|i| flags['searchable'][i] == '' }

      unless searchables.empty?
        if search_out.empty?
          search_out += "

      #
      # Search Fields Removed
      #
      list_parms['searchFieldsOut'] = {}"
        end
        searchables.each { |val|
          field_name = val[0]
          search_out += "
      list_parms['searchFieldsOut']#{add_pointer(field_name,9)} true"
        }
      end


      summarizables = flags['summarize'].select {|i| flags['summarize'][i] == 'checked' }

      unless summarizables.empty?

        search_out += "

      #
      # Total Columns
      #
      "
        summarizables.each { |val|
          field_name = val[0]
          search_out += "
      list_parms['totalRow']#{add_pointer(field_name,2)} true"
        }
      end


      sortables = flags['sortable'].select {|i| flags['sortable'][i] == '' }

      unless sortables.empty?

        search_out += "

      #
      # Remove Sort Links
      #
      "
        sortables.each { |val|
          field_name = val[0]
          search_out += "
      list_parms['columnNoSort']#{add_pointer(field_name,6)} true"
        }
      end

      popupTitles = misc['title'].select {|i| misc['title'][i] != '' }

      unless popupTitles.empty?

        search_out += "

      #
      # Popup Titles
      #
      "
        popupTitles.each { |val|
          field_name = val[0]
          description = val[1]
          search_out += "
      list_parms['columnPopupTitle']#{add_pointer(field_name,10)} '#{escape_code description}'"
        }
      end

      widths = misc['width'].select {|i| misc['width'][i] != '' }

      unless widths.empty?

        search_out += "

      #
      # Column Widths
      #
      "
        widths.each { |val|
          field_name = val[0]
          pixels = val[1]

          add_config = true
          unless pixels.include?('px')
            if pixels.to_i == 0
              add_config = false
            end
            pixels += 'px'
          end

          search_out += "
      list_parms['columnWidth']#{add_pointer(field_name,5)} '#{escape_code pixels}'" if add_config == true
        }
      end

      links = misc['link'].select {|i| misc['link'][i] != '' }

      unless links.empty?

        search_out += "

      #
      # Column Links
      #
      "
        links.each { |val|
          field_name = val[0]
          page_name  = val[1]

          search_out += "
      list_parms['links']#{add_pointer(field_name,-1)} { 'page' => '#{escape_code page_name}', 'tags' => {'all' => 'all'}}
      list_parms['columnStyle']#{add_pointer(field_name,5)} 'color:blue;'"
        }
      end


      if page_config['rowButtonsOn'] == '1'
        variable_code += "
      button_column_name              = '#{escape_code page_config['rowButtonsName']}'"
      end

      #------------ VIEW ------------

      if page_config['useRansack'] == '1' && page_config['showSearch'] == '1' && $is_mongo == false
        view_code = "
      list_parms#{add_pointer('ransackSearch',-10)} #{page_config['view']}.search(#{($_REQUEST.key?('iframe')) ? '$_REQUEST' : 'params'}[:q])
      list_parms#{add_pointer('view',-10)} list_parms['ransackSearch'].result
        "
        if page_config['ransackAdvancedForm'] == '1'
          view_code += "
      list_parms['listSearchForm'] = WidgetList::Utils::fill( {
                                                                      '<!--BUTTON_SEARCH-->'       => WidgetList::Widgets::widget_button('Search', WidgetList::List::build_search_button_click(list_parms)),
                                                                      '<!--BUTTON_CLOSE-->'        => \"HideAdvancedSearch(this)\" } ,
                                                                  '
      <!-- Customize your form as well as keep RANSACK tag -->
      <div id=\"advanced-search-container\">
          <div class=\"widget-search-drilldown-close\" onclick=\"<!--BUTTON_CLOSE-->\">X</div>
            <ul class=\"advanced-search-container-inline\" id=\"search_columns\">
              <li>
                <!--RANSACK-->
              </li>
            </ul>
           <br/>
                <div style=\"text-align:right;width:100%;height:30px;\" class=\"advanced-search-container-buttons\"><!--BUTTON_RESET--><!--BUTTON_SEARCH--></div>
      </div>
                                                                  '
        "

        end

      else
        view_code = "
      list_parms#{add_pointer('view',-10)} #{page_config['view']}
        "
      end

      #------------ EXPORT ------------

      if page_config['showExport'] == '1' && page_config['showSearch'] == '1'
        export_code += "list_parms['showExport']        = #{page_config['showExport'] == '1' ? 'true' : 'false'}
      list_parms['exportButtonTitle'] = '#{escape_code page_config['exportButtonTitle']}'"
      end

      if page_config['showSearch'] == '1'
        export_code += "
      list_parms['searchTitle']       = '#{escape_code page_config['searchTitle']}'"
      end


      #------------ VISIBLE FIELDS ------------
      if page_config['checkboxEnabled'] == '1'
        checkbox_code += "
      list_parms = WidgetList::List.checkbox_helper(list_parms,'#{page_config['checkboxField']}')
        "
        if using_grouping
          visible_field_code += "
      list_parms['fields']#{add_pointer('checkbox')} #{add_conditional('checkbox_header',"if groupByFilter == 'none'")}"
        else
          visible_field_code += "
      list_parms['fields']#{add_pointer('checkbox')} 'checkbox_header'"
        end
      end

      fields.each { |field,description|
        conditional = ''
        if using_grouping
          conditional = ' if groupByFilter == \'none\''
          if group_by.key?(field) || group_by.key?(field.gsub(/_linked/,''))
            conditional = " if groupByFilter == 'none' || groupByFilter == 'group_#{escape_code group_by[field.gsub(/_linked/,'')].gsub(/ /,'_').downcase}'"
          end
        end
        visible_field_code += "
      list_parms['fields']#{add_pointer(field)} #{add_conditional(description,conditional)}"
      }




      #------------ GROUPING ------------

      if using_grouping
        variable_code += "
      groupByDesc                     = ''     # Initialize a variable you can use in listDescription to show what the current grouping selection is
      groupByFilter                   = 'none' # This variable should be used to control business logic based on the grouping and is a short hand key rather than using what is returned from get_group_by_selection
        "

        visible_field_code += "
      list_parms['fields']#{add_pointer('cnt')} #{add_conditional('Count'," if groupByFilter != 'none'")}
        "
        if database_type == 'oracle'
          count = 'TO_CHAR(COUNT(1))'
        else
          count = 'COUNT(1)'
        end

        field_function_code += "
      list_parms['fieldFunction']#{add_pointer('cnt',7)} #{add_conditional(count," if groupByFilter != 'none'")}"
        descriptions = []
        group_by.each { |field,description|
          descriptions << "'" + escape_code(description) + "'"
          desc = ''
          filter = ''
          unless field.empty?
            desc = " (Grouped By #{escape_code field.camelize})"
            filter = "group_#{description.gsub(/ /,'_').downcase}"
          else
            filter = 'none'
          end
          case_statements2 += <<-EOD

        when '#{escape_code description}'
          list_parms['groupBy']  = '#{escape_code field}'
          groupByFilter          = '#{escape_code filter}'
          groupByDesc            = '#{escape_code desc}'
          EOD
        }
        grouping_code = <<-EOD

      #
      # Group By
      #

      groupBy  = WidgetList::List::get_group_by_selection(list_parms)

      case groupBy#{case_statements2}
        else
          list_parms['groupBy']  = ''
      end
        EOD

        grouping_code += "
      list_parms['groupByItems'] = " + '[' + descriptions.join(', ') + ']'

        grouping_code2 = "
      #
      # Prevent Oracle grouping errors
      #
      list_parms = WidgetList::List.group_by_max_each_field(list_parms,groupByFilter)
      " if database_type == 'oracle'
      end


      #------------ BUTTONS ------------

      if page_config['rowButtonsOn'] == '1'
        visible_field_code += "
      list_parms['fields'][button_column_name.downcase]        =  button_column_name.capitalize"
        visible_field_code += " if groupByFilter == 'none'"    if using_grouping



        button_code += "
      #
      # Buttons
      #
      mini_buttons = {}
      "

        buttons.each { |field|
          button_code += "
      mini_buttons['button_#{escape_code field[0].downcase}'] = {'page'       => '#{escape_code field[1]['url']}',
                                                     'text'       => '#{escape_code field[0]}',
                                                     'function'   => 'Redirect',
                                                     'innerClass' => '#{escape_code field[1]['class']}',
                                                     'tags'       => {'all'=>'all'}
                                                    }
      "
        }

        button_code += "
      list_parms['buttons']       = {button_column_name.downcase => mini_buttons}
      "
      end



      #------------ FOOTER ------------
      if page_config['footerOn'] == '1' && !footer_buttons.empty?
        btns = []
        footer_buttons.each {|field|
          btns << " WidgetList::Widgets::widget_button('#{escape_code field[0]}', {'page'       => '#{escape_code field[1]['url']}','innerClass' => '#{escape_code field[1]['class']}'})"
        }

        button_code += "
      list_parms['customFooter'] = " + btns.join(' + ')
      end



      #------------ FIELD FUNCTIONS ------------

      if page_config['fieldFunctionOn'] == '1' && !fields_function.empty?
        fields_function.each { |field,command|
          field_function_code += "
      list_parms['fieldFunction']#{add_pointer(field,7)} '#{escape_code command}'"
        }
      end

      if page_config['showHidden'] == '1'
        fields_hidden.each { |field|
          hidden_field_code += "
      list_parms['fieldsHidden'] << '#{escape_code field[1]}'"
        }
      end

      if page_config['rowButtonsOn'] == '1'
        field_function_code += "
      list_parms['fieldFunction'][button_column_name.downcase] = \"''\""
      end


      if page_config['checkboxEnabled'] == '1'
        field_function_code += "
      list_parms['fieldFunction']#{add_pointer('checkbox',7)} \"''\""
      end

      <<-EOD
    begin

      #{variable_code}
      list_parms                      = WidgetList::List::init_config()
      list_parms['name']              = '#{escape_code page_config['name']}'
      list_parms['noDataMessage']     = '#{escape_code page_config['noDataMessage']}'
      list_parms['rowLimit']          = #{page_config['rowLimit']}
      list_parms['title']             = '#{escape_code page_config['title']}'
      list_parms['useSort']           = #{page_config['useSort'] == '1' ? 'true' : 'false'}
      list_parms['showPagination']    = #{page_config['showPagination'] == '1' ? 'true' : 'false'}
      list_parms['database']          = '#{page_config['primaryDatabase'] == '1' ? 'primary' : 'secondary'}'
      #{export_code}

      #{drill_down_code}
      #{grouping_code}

      #
      # Fields
      #
      #{visible_field_code}
      #{hidden_field_code}
      #{field_function_code}
      #{search_out}
      #{grouping_code2}

      #
      # Model
      #
      #{view_code}

      #{checkbox_code}
      #{button_code}

      #
      # Render List
      #
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

    rescue Exception => e

      #
      # Rescue Errors
      #
      Rails.logger.info e.to_s + "\\n\\n" + $!.backtrace.join("\\n\\n")

      if Rails.env == 'development'
        list_parms['errors'] << '<br/><br/><strong style="color:maroon;">(Ruby Exception - Still attempted to render list with given config ' + list_parms.inspect + ') Exception ==> ' + e.to_s + "<br/><br/>Backtrace:<br/><br/>" + $!.backtrace.join("<br/><br/>") + "</strong>"
      end

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
      EOD
    end

    def get_configuration()

      config_id =  config_id()

      @isEditing  = false
      config_file = Rails.root.join("config", "widget-list-administration.json")
      config_file_all = Rails.root.join("config", "widget-list-administration-all.json")

      if config_file.file? && ($_REQUEST.key?('iframe') || $_REQUEST.key?('name'))
        configuration = JSON.parse(File.new(Rails.root.join("config", "widget-list-administration.json")).read)
      elsif $_REQUEST.key?('restore')
        configuration = JSON.parse(File.new(Rails.root.join("config", "widget-list-administration-all.json")).read)
      else
        configuration = {}
      end

      if configuration.key?(config_id)
        if config_file_all.file?
          configuration_all = JSON.parse(File.new(Rails.root.join("config", "widget-list-administration-all.json")).read)
          if configuration_all.key?(config_id)
            @isEditing  = true
          end
        end
        page_config = configuration[config_id]

        ['useSort','showHidden','fieldFunctionOn','rowButtonsOn','drillDownsOn','showSearch','showExport','useRansack','ransackAdvancedForm','useGrouping','footerOn','checkboxEnabled'].each { |item|
          unless page_config.key?(item)
            page_config[item] = "0"
          end
        }
      else
        page_config = {}
      end
      return [config_id,page_config]
    end

    def build_field_options(fields,selected='')
      options = ''
      fields.each { |field,description|
        options += "<option value='#{field}' #{((selected == field) ? 'selected' : '')}>#{description}</option>"
      }
      return options
    end

    def normalize_configs(page_config)
      fields             = {}
      misc               = {}
      misc['width']      = {}
      misc['title']      = {}
      misc['link']       = {}
      flags              = {}
      flags['searchable']= {}
      flags['summarize'] = {}
      flags['sortable']  = {}
      fields_hidden      = {}
      fields_function    = {}
      buttons            = {}
      footer_buttons     = {}
      group_by           = {}
      drill_downs        = {}

      if page_config.key?('fields')
        page_config['fields']['key'].each_with_index { |v,k|
          fields[v] = page_config['fields']['description'][k.to_i]

          if page_config.key?('misc') &&  page_config['misc'].key?('key')
            misc['width'][v] = page_config['misc']['key'][k.to_i]
          end

          if page_config.key?('misc') &&  page_config['misc'].key?('description')
            misc['title'][v] = page_config['misc']['description'][k.to_i]
          end

          if page_config.key?('misc') &&  page_config['misc'].key?('link')
            misc['link'][v] = page_config['misc']['link'][k.to_i]
          end

          if page_config.key?('flags') &&  page_config['flags'].key?('searchable')
            flags['searchable'][v] = page_config['flags']['searchable'][k.to_i]
          end

          if page_config.key?('flags') &&  page_config['flags'].key?('summarize')
            flags['summarize'][v] = page_config['flags']['summarize'][k.to_i]
          end

          if page_config.key?('flags') &&  page_config['flags'].key?('sortable')
            flags['sortable'][v] = page_config['flags']['sortable'][k.to_i]
          end
        }
      end

      if page_config.key?('fields_hidden')
        page_config['fields_hidden']['key'].each { |v|
          fields_hidden[v] = v
        }
      end

      if page_config.key?('fields_function')
        page_config['fields_function']['key'].each_with_index { |v,k|
          fields_function[v] = page_config['fields_function']['description'][k.to_i]
        }
      end

      if page_config.key?('group_by')
        page_config['group_by']['key'].each_with_index { |v,k|
          group_by[v] = page_config['group_by']['description'][k.to_i]
        }
      end

      if page_config.key?('buttons')
        page_config['buttons']['text'].each_with_index { |v,k|
          buttons[v] = {}
          buttons[v]['url']   = page_config['buttons']['url'][k.to_i]
          buttons[v]['class'] = page_config['buttons']['class'][k.to_i]
        }
      end

      if page_config.key?('footer_buttons')
        page_config['footer_buttons']['text'].each_with_index { |v,k|
          footer_buttons[v] = {}
          footer_buttons[v]['url']   = page_config['footer_buttons']['url'][k.to_i]
          footer_buttons[v]['class'] = page_config['footer_buttons']['class'][k.to_i]
        }
      end

      if page_config.key?('drill_downs')
        page_config['drill_downs']['drill_down_name'].each_with_index { |v,k|
          drill_downs[v] = {}
          drill_downs[v]['data_to_pass_from_view']   = page_config['drill_downs']['data_to_pass_from_view'][k.to_i]
          drill_downs[v]['column_to_show']           = page_config['drill_downs']['column_to_show'][k.to_i]
        }
      end

      return [fields,fields_hidden,fields_function,buttons,footer_buttons,group_by,drill_downs,flags,misc]
    end

    def ajax_get_field_json(model_name)
      config_id, page_config = get_configuration()
      ac = ActionController::Base.new()
      @response          = {}
      fields             = {}
      flags              = {}
      misc               = {}
      fields_hidden      = {}
      all_fields         = {}
      fields_function    = {}
      buttons            = {}
      footer_buttons     = {}
      group_by           = {}
      drill_downs        = {}

      if @isEditing
        model         = page_config['view'].constantize.new
        model.attributes.keys.each { |field|
          all_fields[field] = field.gsub(/_/,' _').camelize
        }

        fields,fields_hidden,fields_function,buttons,footer_buttons,group_by,drill_downs,flags,misc = normalize_configs(page_config)
      else
        controller = ($_REQUEST.key?('desiredController') ? $_REQUEST['desiredController'] :  $_REQUEST['controller'] )

        if $_REQUEST.key?('ajax')
          model         = model_name.constantize
          model.columns.each { |field|
            fields[field.name] = field.name.gsub(/_/,' _').camelize
            all_fields[field.name] = field.name.gsub(/_/,' _').camelize
            fields_function[field.name] = 'CNT(' + field.name + ') or NVL(' + field.name + ') or TO_DATE(' + field.name + ') etc...'
          }
          footer_buttons['Add New ' + model_name]            = {}
          footer_buttons['Add New ' + model_name]['url']     = '/' + controller + '/add/'
          footer_buttons['Add New ' + model_name]['class']   = 'info'
        end
        buttons['Edit']              = {}
        buttons['Delete']            = {}

        buttons['Delete']['class']   = 'danger'
        buttons['Delete']['url']     = '/' + controller + '/delete/id/'
        buttons['Edit']['url']       = '/' + controller + '/edit/id/'
        buttons['Edit']['class']     = 'info'
        if $_REQUEST.key?('ajax')
          group_by['']               = 'All ' + model_name + 's'
          group_by['field_name']     = 'This will group by field_name and show Count'
          buttons['Delete']['url']   = '/' + controller + '/delete/' + fields.keys.first + '/'
          buttons['Edit']['url']     = '/' + controller + '/edit/' + fields.keys.first + '/'
        end
      end

      @response['fields']          = ''
      @response['fields_hidden']   = ''
      @response['fields_function'] = ''
      @response['buttons']         = ''
      @response['group_by']        = ''
      @response['footer_buttons']  = ''
      @response['drill_downs']     = ''

      fields.each { |field,description|
        @fieldFill = {}
        @fieldFill['<!--SUBJECT-->']             = 'fields'
        @fieldFill['<!--FIELD_VALUE-->']         = field
        @fieldFill['<!--FIELD_DESC-->']          = description
        @fieldFill['<!--REMOVE_FIELD_BUTTON-->'] = remove_field_button() + WidgetList::Widgets::widget_button('Hide',  {'onclick' => "MoveField(this)", 'innerClass' => "danger" }, true ) + WidgetList::Widgets::widget_button('Function',  {'onclick' => "AddFunction(this)", 'innerClass' => "success" }, true )  + WidgetList::Widgets::widget_button('Options',  {'onclick' => "ShowOptions(this)", 'innerClass' => "info" }, true )
        @fieldFill['<!--FIELD-->']               = 'Field'
        @fieldFill['<!--DESC-->']                = 'Desc'
        @fieldFill['<!--DISABLED-->']            = ''
        @fieldFill['<!--TR_STYLE-->']            = ''


        if misc.key?('width') && misc['width'].key?(field) && !misc['width'][field].nil?
          width = misc['width'][field]
        else
          width = ''
        end

        if misc.key?('link') && misc['link'].key?(field) && !misc['link'][field].nil?
          link = misc['link'][field]
        else
          link = ''
        end

        if misc.key?('title') && misc['title'].key?(field) && !misc['title'][field].nil?
          title = misc['title'][field]
        else
          title = ''
        end

        @fieldFillRow2 = {}
        @fieldFillRow2['<!--REMOVE_FIELD_BUTTON-->']  = 'Link To:&#160;<br/><br/><input type="text" style="width:350px" class="misc_links" onblur="jQuery(this).attr(\'value\',jQuery(this).val().trim());" name="misc[link][]" id="misc[link][]" value="' + link + '"/>' + WidgetList::Widgets::widget_button('?',  {'onclick' => "alert('Please use /my_page/field_name/field_name/ and it will be linked and replaced with the column value.')", 'innerClass' => "default" }, true )
        @fieldFillRow2['<!--FIELD_VALUE-->']          = width
        @fieldFillRow2['<!--FIELD_DESC-->']           = title
        @fieldFillRow2['<!--SUBJECT-->']              = 'misc'
        @fieldFillRow2['<!--FIELD-->']                = 'Column Width<br/><br/>'
        @fieldFillRow2['<!--DESC-->']                 = 'Header Title Popup<br/><br/>'
        @fieldFillRow2['<!--DISABLED-->']             = ''
        @fieldFillRow2['<!--TR_STYLE-->']             = (link.empty? && title.empty? && width.empty?) ? 'display:none' : ''
        @fieldFillRow2['<!--TR1_STYLE-->']            = 'padding-left:100px'

        @fieldFill['<!--EXTRA-->']                    = WidgetList::Utils::fill(@fieldFillRow2 , ac.render_to_string(:partial => 'widget_list/administration/field_row') )


        if flags.key?('searchable') && flags['searchable'].key?(field) && !flags['searchable'][field].nil?
          searchable = flags['searchable'][field]
        else
          searchable = (!@isEditing) ? 'checked' : ''
        end

        if flags.key?('summarize') && flags['summarize'].key?(field) && !flags['summarize'][field].nil?
          summarize = flags['summarize'][field]
        else
          summarize = ''
        end

        if flags.key?('sortable') && flags['sortable'].key?(field) && !flags['sortable'][field].nil?
          sortable = flags['sortable'][field]
        else
          sortable = (!@isEditing) ? 'checked' : ''
        end

        @fieldFillRow3 = {}

        @fieldFillRow3['<!--1_DESC-->']               = 'Searchable?<br/><br/>'
        @fieldFillRow3['<!--1_KEY-->']                = 'searchable'
        @fieldFillRow3['<!--1_VALUE-->']              = searchable

        @fieldFillRow3['<!--2_DESC-->']               = 'Summarize Totals?<br/><br/>'
        @fieldFillRow3['<!--2_KEY-->']                = 'summarize'
        @fieldFillRow3['<!--2_HELP-->']               = 'If this is a numeric column, the widget_list will add a record at the bottom of all your results adding up every value'
        @fieldFillRow3['<!--2_VALUE-->']              = summarize

        @fieldFillRow3['<!--3_DESC-->']               = 'Sortable?'
        @fieldFillRow3['<!--3_KEY-->']                = 'sortable'
        @fieldFillRow3['<!--3_VALUE-->']              = sortable

        @fieldFillRow3['<!--SUBJECT-->']              = 'flags'
        @fieldFillRow3['<!--CHECKBOX_STYLE-->']       = ((@isEditing && searchable == 'checked' && summarize.empty? && sortable  == 'checked') || !@isEditing) ? 'display:none' : ''

        @fieldFill['<!--EXTRA-->']                   += WidgetList::Utils::fill(@fieldFillRow3 , ac.render_to_string(:partial => 'widget_list/administration/checkbox_row') )

        @response['fields'] += WidgetList::Utils::fill(@fieldFill , ac.render_to_string(:partial => 'widget_list/administration/field_row') )
      }

      fields_hidden.each { |field|
        @fieldFill = {}
        @fieldFill['<!--SUBJECT-->']             = 'fields_hidden'
        @fieldFill['<!--FIELD_VALUE-->']         = field[1]
        @fieldFill['<!--FIELD_DESC-->']          = ''
        @fieldFill['<!--REMOVE_FIELD_BUTTON-->'] = remove_field_button()+ WidgetList::Widgets::widget_button('Show',  {'onclick' => "ShowField(this)", 'innerClass' => "success" }, true )
        @fieldFill['<!--DESC-->']                = 'Desc'
        @fieldFill['<!--FIELD-->']               = 'Field'
        @fieldFill['<!--DISABLED-->']            = 'disabled'
        @fieldFill['<!--TR_STYLE-->']            = ''
        @response['fields_hidden'] += WidgetList::Utils::fill(@fieldFill , ac.render_to_string(:partial => 'widget_list/administration/field_row') )
      }

      group_by.each { |field,description|

        @fieldFill = {}
        @fieldFill['<!--REMOVE_FIELD_BUTTON-->']  = remove_field_button()
        @fieldFill['<!--FIELD_VALUE-->']          = field
        @fieldFill['<!--FIELD_DESC-->']           = description
        @fieldFill['<!--SUBJECT-->']              = 'group_by'
        @fieldFill['<!--FIELD-->']                = 'Field'
        @fieldFill['<!--DESC-->']                 = 'Desc'
        @fieldFill['<!--DISABLED-->']             = ''
        @fieldFill['<!--ONBLUR1-->']              = 'InvalidField(this)'
        @fieldFill['<!--TR_STYLE-->']            = ''
        @response['group_by'] += WidgetList::Utils::fill(@fieldFill , ac.render_to_string(:partial => 'widget_list/administration/field_row') )
      }

      fields_function.each { |field,description|
        @fieldFill = {}
        @fieldFill['<!--SUBJECT-->']             = 'fields_function'
        @fieldFill['<!--FIELD_VALUE-->']         = field
        @fieldFill['<!--FIELD_DESC-->']          = description
        @fieldFill['<!--REMOVE_FIELD_BUTTON-->'] = remove_field_button()
        @fieldFill['<!--DESC-->']                = 'Database Function'
        @fieldFill['<!--FIELD-->']               = 'Field'
        @fieldFill['<!--DISABLED-->']            = ''
        @fieldFill['<!--TR_STYLE-->']            = ''
        @response['fields_function'] += WidgetList::Utils::fill(@fieldFill , ac.render_to_string(:partial => 'widget_list/administration/field_row') )
      }

      buttons.each { |field|
        @fieldFill = {}
        @fieldFill['<!--REMOVE_FIELD_BUTTON-->']  = remove_field_button()
        @fieldFill['<!--BUTTON_TEXT-->']          = field[0]
        @fieldFill['<!--BUTTON_URL-->']           = field[1]['url']
        @fieldFill['<!--BUTTON_CLASS-->']         = field[1]['class']

        @fieldFill['<!--ONBLUR3-->']              = 'GoodClass(this)'

        @fieldFill['<!--TEXT_DESC-->']            = 'Text'
        @fieldFill['<!--TEXT_KEY-->']             = 'text'
        @fieldFill['<!--TEXT_HELP-->']            = 'The Button Text'

        @fieldFill['<!--URL_DESC-->']             = 'URL'
        @fieldFill['<!--URL_KEY-->']              = 'url'
        @fieldFill['<!--URL_HELP->']              = 'URLs include a RESTful path where you will pass controller/field_name/field_name/ where those will be replaced'

        @fieldFill['<!--COLOR_DESC-->']           = 'Color'
        @fieldFill['<!--COLOR_KEY-->']            = 'class'
        @fieldFill['<!--COLOR_HELP-->']           = 'primary=(blue) info=(light-blue) success=(green) danger=(red) disabled=(light grey) default=(grey)'
        @fieldFill['<!--SUBJECT-->']              = 'buttons'

        @response['buttons']             +=  WidgetList::Utils::fill(@fieldFill , ac.render_to_string(:partial => 'widget_list/administration/button_row') )
      }

      drill_downs.each { |field|
        @fieldFill = {}
        @fieldFill['<!--REMOVE_FIELD_BUTTON-->']  = remove_field_button()
        @fieldFill['<!--BUTTON_TEXT-->']          = field[0]
        @fieldFill['<!--BUTTON_URL-->']           = field[1]['data_to_pass_from_view']
        @fieldFill['<!--BUTTON_CLASS-->']         = field[1]['column_to_show']
        @fieldFill['<!--ONBLUR2-->']              = 'ReplaceColumnsToLinked(this)'
        @fieldFill['<!--ONBLUR3-->']              = 'ReplaceColumnsToLinked(this)'

        @fieldFill['<!--TEXT_DESC-->']            = 'Internal Filter Name (:drill_down_name)<br/>'
        @fieldFill['<!--TEXT_KEY-->']             = 'drill_down_name'
        @fieldFill['<!--TEXT_HELP-->']            = ':drill_down_name is a parameter of build_drill_down that is what is passed and returned from get_filter_and_drilldown when you handle the request after clicked'

        @fieldFill['<!--URL_DESC-->']             = 'Data To Pass From View (:data_to_pass_from_view)<br/>'
        @fieldFill['<!--URL_KEY-->']              = 'data_to_pass_from_view'
        @fieldFill['<!--URL_HELP->']              = ':data_to_pass_from_view is the internal/hidden value that is inserted into a hidden <script> id block and passed when clicked'

        @fieldFill['<!--COLOR_DESC-->']           = 'Column to Show (:column_to_show)<br/>'
        @fieldFill['<!--COLOR_KEY-->']            = 'column_to_show'
        @fieldFill['<!--COLOR_HELP-->']           = ':column_to_show should either be the column or possibly a formatted column like CONCAT or COUNT'
        @fieldFill['<!--SUBJECT-->']              = 'drill_downs'

        @response['drill_downs']                     +=  WidgetList::Utils::fill(@fieldFill , ac.render_to_string(:partial => 'widget_list/administration/button_row') )
      }

      footer_buttons.each { |field|
        @fieldFill = {}
        @fieldFill['<!--REMOVE_FIELD_BUTTON-->']  = remove_field_button()
        @fieldFill['<!--BUTTON_TEXT-->']          = field[0]
        @fieldFill['<!--BUTTON_URL-->']           = field[1]['url']
        @fieldFill['<!--BUTTON_CLASS-->']         = field[1]['class']
        @fieldFill['<!--ONBLUR3-->']              = 'GoodClass(this)'

        @fieldFill['<!--TEXT_DESC-->']            = 'Text'
        @fieldFill['<!--TEXT_KEY-->']             = 'text'
        @fieldFill['<!--TEXT_HELP-->']            = 'The Button Text'

        @fieldFill['<!--URL_DESC-->']             = 'URL'
        @fieldFill['<!--URL_KEY-->']              = 'url'
        @fieldFill['<!--URL_HELP->']              = 'The URL'

        @fieldFill['<!--COLOR_DESC-->']           = 'Color'
        @fieldFill['<!--COLOR_KEY-->']            = 'class'
        @fieldFill['<!--COLOR_HELP-->']           = 'primary=(blue) info=(light-blue) success=(green) danger=(red) disabled=(light grey) default=(grey)'
        @fieldFill['<!--SUBJECT-->']              = 'footer_buttons'

        @response['footer_buttons']             +=  WidgetList::Utils::fill(@fieldFill , ac.render_to_string(:partial => 'widget_list/administration/button_row') )
      }

      if $_REQUEST.key?('ajax') || @isEditing
        @response['all_fields']     = all_fields
        @response['checked_fields'] = build_field_options(all_fields, page_config.key?('checkboxField') ? page_config['checkboxField'] : '')
      end

      return @response.to_json
    end

    def remove_field_button()
      WidgetList::Widgets::widget_button('Remove',  {'onclick' => "RemoveField(this)", 'innerClass' => "danger" }, true )
    end

    def config_id()
      config_id =  ''
      if $_REQUEST.key?('restore')
        config_id = $_REQUEST['restore']
      else
        config_id += $_REQUEST['controller'] if $_REQUEST.key?('controller')
        config_id += $_REQUEST['action'] if $_REQUEST.key?('action')
        config_id += '|' + $_REQUEST['desiredController'] if $_REQUEST.key?('desiredController')
        config_id += '-' + $_REQUEST['desiredAction'] if $_REQUEST.key?('desiredAction')
      end
      return config_id
    end

    def save_and_show_code()
      ac = ActionController::Base.new()

      config_id =  config_id()

      config_file = Rails.root.join("config", "widget-list-administration.json")
      if config_file.file?
        configuration = JSON.parse(File.new(Rails.root.join("config", "widget-list-administration.json")).read)
      else
        configuration = {}
      end
      configuration[config_id] = $_REQUEST
      time = Time.new
      configuration[config_id]['savedOn'] = time.year.to_s + '-' + time.month.to_s.rjust(2, "0") + '-' + time.day.to_s.rjust(2, "0")

      File.open(Rails.root.join("config", "widget-list-administration.json"), "w") do |file|
        file.puts configuration.to_json
      end

      if !$_REQUEST.key?('iframe') && !$_REQUEST.key?('ajax')
        config_file_all = Rails.root.join("config", "widget-list-administration-all.json")
        if config_file_all.file?
          configuration_all = JSON.parse(File.new(Rails.root.join("config", "widget-list-administration-all.json")).read)
        else
          configuration_all = {}
        end
        configuration_all[config_id] = $_REQUEST
        configuration_all[config_id]['savedOn'] = time.year.to_s + '-' + time.month.to_s.rjust(2, "0") + '-' + time.day.to_s.rjust(2, "0")

        File.open(Rails.root.join("config", "widget-list-administration-all.json"), "w") do |file|
          file.puts configuration_all.to_json
        end
      end


      @fill = {}
      unless $_REQUEST.key?('ajax')
        @fill['<!--CODE-->'] = translate_config_to_code()
      end
      return WidgetList::Utils::fill(@fill ,ac.render_to_string(:partial => 'widget_list/administration/output_save') )  unless $_REQUEST.key?('ajax')
      return @fill.to_json
    end
  end


  #
  # WidgetList Core Logic
  #
  if defined?(Rails) && defined?(Rails::Engine)
    class Engine < ::Rails::Engine
      require 'widget_list/engine'
    end

  end

  class List

    @debug = true

    attr_accessor :isAdministrating

    include ActionView::Helpers::SanitizeHelper
    include ActionView::Helpers::NumberHelper

    # @param [Hash] list
    def initialize(list={})

      # Defaults for all configs
      # See https://github.com/davidrenne/widget_list/blob/master/README.md#feature-configurations

      @items        = WidgetList::List::get_defaults()

      if list.empty? || list == @items
        @isAdministrating = true
        return
      else
        @isAdministrating = false
      end

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
      @headerPieces = {}

      ac = ActionController::Base.new()

      #the main template and outer shell
      @items.deep_merge!({ 'template'                              => ac.render_to_string(:partial => 'widget_list/list_partials/outer_shell') })
      @items.deep_merge!({ 'row'                                   => ac.render_to_string(:partial => 'widget_list/list_partials/row') })
      @items.deep_merge!({ 'list_description'                      => ac.render_to_string(:partial => 'widget_list/list_partials/list_description') })
      @items.deep_merge!({ 'col'                                   => ac.render_to_string(:partial => 'widget_list/list_partials/col') })
      @items.deep_merge!({ 'templateSequence'                      => ac.render_to_string(:partial => 'widget_list/list_partials/sequence') })

      #Sorting
      #
      @items.deep_merge!({ 'templateSortColumn'                    => ac.render_to_string(:partial => 'widget_list/list_partials/sort_column') })
      @items.deep_merge!({ 'templateNoSortColumn'                  => ac.render_to_string(:partial => 'widget_list/list_partials/no_sort_column') })

      #Pagintion
      #
      @items.deep_merge!({ 'template_pagination_wrapper'           => ac.render_to_string(:partial => 'widget_list/list_partials/pagination_wrapper') })
      @items.deep_merge!({ 'template_pagination_next_active'       => ac.render_to_string(:partial => 'widget_list/list_partials/pagination_next_active') })
      @items.deep_merge!({ 'template_pagination_next_disabled'     => ac.render_to_string(:partial => 'widget_list/list_partials/pagination_next_disabled') })
      @items.deep_merge!({ 'template_pagination_previous_active'   => ac.render_to_string(:partial => 'widget_list/list_partials/pagination_previous_active') })
      @items.deep_merge!({ 'template_pagination_previous_disabled' => ac.render_to_string(:partial => 'widget_list/list_partials/pagination_previous_disabled') })
      @items.deep_merge!({ 'template_pagination_jump_active'       => ac.render_to_string(:partial => 'widget_list/list_partials/pagination_jump_active') })
      @items.deep_merge!({ 'template_pagination_jump_unactive'     => ac.render_to_string(:partial => 'widget_list/list_partials/pagination_jump_unactive') })

      if list['view'].class.name == 'ActiveRecord::Relation'
        tag_fields = '<!--FIELDS_PLAIN-->'
      else
        #In a case where someone passes a SQL query raw with Sequel, we need to support fieldFunction's like action buttons which wouldnt be in your query, so use FIELDS to build entire query
        tag_fields = '<!--FIELDS-->'
      end

      @items.deep_merge!({ 'statement' =>
                               {'select'=>
                                    {'view' =>'SELECT ' + tag_fields + ' FROM <!--SOURCE--> <!--WHERE--> <!--GROUPBY--> <!--ORDERBY--> <!--LIMIT-->'}
                               }
                         })

      @items.deep_merge!({ 'statement' =>
                               {'count'=>
                                    {'view' => 'SELECT count(1) total FROM <!--VIEW--> <!--WHERE--> <!--GROUPBY-->'}
                               }
                         })
      #inject site wide configs before list specific configs if a helper exists

      if defined?(WidgetListHelper) == 'constant' && WidgetListHelper::SiteDefaults.class == Class && WidgetListHelper::SiteDefaults.respond_to?('get_site_widget_list_defaults')
        @items = WidgetList::Widgets::populate_items(WidgetListHelper::SiteDefaults::get_site_widget_list_defaults() ,@items)
      end

      if defined?(WidgetListThemeHelper) == 'constant' && WidgetListThemeHelper::ThemeDefaults.class == Class && WidgetListThemeHelper::ThemeDefaults.respond_to?('get_theme_widget_list_defaults')
        @items = WidgetList::Widgets::populate_items(WidgetListThemeHelper::ThemeDefaults::get_theme_widget_list_defaults() ,@items)
      end

      @items = WidgetList::Widgets::populate_items(list,@items)

      # If ransack is used
      if @items['view'].class.name == 'ActiveRecord::Relation' && @items['ransackSearch'].class.name == 'Ransack::Search'
        @items['ransackSearch'].build_condition if @items['ransackSearch'].conditions.empty?

        if @items['listSearchForm'].empty?

          #
          # if no one passed a listSearchForm inject a default one to show the ransack form
          #
          fill = {
              '<!--BUTTON_SEARCH-->'       => WidgetList::Widgets::widget_button('Search', {'onclick' => WidgetList::List::build_search_button_click(@items), 'innerClass' => @items['defaultButtonClass'] }),
              '<!--BUTTON_CLOSE-->'        => "HideAdvancedSearch(this)"
          }
          @items['listSearchForm'] = WidgetList::Utils::fill( fill , ac.render_to_string(:partial => 'widget_list/ransack_widget_list_advanced_search') )

        end
      end

      # I have several different styles for borders, but using borders Everywhere will setup everything with one call
      if @items['bordersEverywhere?']
        @items['borderedColumns'] = @items['borderHeadFoot'] = @items['borderedRows'] = true
        @items['borderColumnStyle'] = @items['borderRowStyle'] = @items['headFootBorderStyle'] = @items['tableBorder'] = @items['borderEverywhere']
      end

      # current_db is a flag of the last known primary or secondary YML used or defaulted when running a list
      @current_db_selection = @items['database']

      if get_database.db_type == 'oracle'

        @items.deep_merge!({'statement' =>
                                {'count'=>
                                     {'view' =>
                                          '
                                   SELECT count(1) total FROM <!--VIEW--> ' + ((@items['groupBy'].empty? && !@active_record_model) ? '<!--WHERE-->  <!--GROUPBY-->' : '' )
                                     }
                                }
                           })
        @items.deep_merge!({'statement' =>
                                {'select'=>
                                     {'view' =>
                                          'SELECT <!--FIELDS_PLAIN--> FROM ( SELECT a.*, DENSE_RANK() over (<!--ORDERBY-->) rn FROM ( SELECT ' + ( (!get_view().include?('(')) ? '<!--SOURCE-->' : get_view().strip.split(" ").last ) + '.* FROM <!--SOURCE--> ) a ' + ((@items['groupBy'].empty?) ? '<!--WHERE-->' : '') + ' <!--ORDERBY--> ) <!--LIMIT--> ' + ((!@active_record_model) ? '<!--GROUPBY-->' : '')
                                     }
                                }
                           })

      end


      if $_REQUEST.key?('searchClear')
        clear_search_session()
      end

      begin
        @isJumpingList = false

        #Ajax ListJump
        if ! $_REQUEST.empty?
          if $_REQUEST.key?('LIST_FILTER_ALL') && !$_REQUEST['LIST_FILTER_ALL'].empty?
            @items['LIST_FILTER_ALL']     = $_REQUEST['LIST_FILTER_ALL']
            @isJumpingList = true
          end

          if $_REQUEST.key?('LIST_COL_SORT') && !$_REQUEST['LIST_COL_SORT'].empty?
            @items['LIST_COL_SORT']     = $_REQUEST['LIST_COL_SORT']
            @isJumpingList = true
          end

          if $_REQUEST.key?('LIST_COL_SORT_ORDER') && !$_REQUEST['LIST_COL_SORT_ORDER'].empty?
            @items['LIST_COL_SORT_ORDER']     = $_REQUEST['LIST_COL_SORT_ORDER']
            @isJumpingList = true
          end

          if $_REQUEST.key?('LIST_SEQUENCE') && !$_REQUEST['LIST_SEQUENCE'].empty?
            @items['LIST_SEQUENCE']     = $_REQUEST['LIST_SEQUENCE'].to_i
            @isJumpingList = true
          end

          if $_REQUEST.key?('ROW_LIMIT') && !$_REQUEST['ROW_LIMIT'].empty?
            @items['ROW_LIMIT']     = $_REQUEST['ROW_LIMIT']
            @isJumpingList = true

            if @items['showPagination']
              $_SESSION['pageDisplayLimit']            = $_REQUEST['ROW_LIMIT']
              $_SESSION.deep_merge!({'ROW_LIMIT' => { @items['name'] => $_REQUEST['ROW_LIMIT']} })
            end

          end

          clear_sort_get_vars()

          if $_REQUEST.key?('list_action') && $_REQUEST['list_action'] == 'ajax_widgetlist_checks' && @items['storeSessionChecks']
            ajax_maintain_checks()
          end

        end

        @items['groupByClick'] = WidgetList::Utils::fill({'<!--NAME-->' => @items['name']}, @items['groupByClickDefault'] + @items['groupByClick'])

        begin
          if @items['searchClear'] || @items['searchClearAll']
            clear_search_session(@items.key?('searchClearAll'))
          end

          matchesCurrentList   = $_REQUEST.key?('BUTTON_VALUE') && $_REQUEST['BUTTON_VALUE'] == @items['buttonVal']
          isSearchRequest      = $_REQUEST.key?('search_filter') && $_REQUEST['search_filter'] != 'undefined'
          templateCustomSearch = !@items['templateFilter'].empty? # if you define templateFilter WidgetList will not attempt to build a where clause with search

          #
          # Search restore
          #
          if !isSearchRequest && !$_SESSION.empty? && $_SESSION.key?('SEARCH_FILTER') && $_SESSION['SEARCH_FILTER'].key?(@items['name']) && @items['searchSession']
            isSearchRestore = true
          end

          if (isSearchRequest && matchesCurrentList && !templateCustomSearch && @items['showSearch']) || isSearchRestore


            get_view() if $is_mongo # call function to fill in @active_record_model

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
                @items['filter'] = [] unless $is_mongo
                @items['filter'] << filterString unless $is_mongo
              end

              fieldsToSearch = @items['fields'].dup

              if @items['fieldsHidden'].class.name == 'Array'
                @items['fieldsHidden'].each { |columnPivot|
                  fieldsToSearch[columnPivot] = strip_aliases(columnPivot)
                }
              elsif @items['fieldsHidden'].class.name == 'Hash'
                @items['fieldsHidden'].each { |columnPivot|
                  fieldsToSearch[columnPivot[0]] = strip_aliases(columnPivot[0])
                }
              end
              fieldsToSearch.delete('cnt') if fieldsToSearch.key?('cnt')
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

                        if $is_mongo
                          criteriaTmp.each_with_index { |value, key|

                            if !@items['groupBy'].empty?
                              @items['filter']   <<  searchIdCol
                              @items['predicate']<<  '='
                              @items['bindVars'] <<  value
                            end
                            @active_record_model = @active_record_model.where('$or' => [{searchIdCol=>value}]) if @items['groupBy'].empty?
                          }
                        end
                      end
                    }

                    if !searchSQL.empty?
                      #
                      # Assemble Numeric Filter
                      #
                      @items['filter'] << "(" + searchSQL.join(' OR ') + ")" unless $is_mongo
                    end
                  elsif @items['fields'].key?(@items['searchIdCol'])
                    numericSearch = true
                    @items['filter']  << tick_field() + "#{@items['searchIdCol']}" + tick_field() + " IN(" + criteriaTmp.join(',') + ")" unless $is_mongo

                    if $is_mongo
                      criteriaTmp.each_with_index { |value, key|
                        if !@items['groupBy'].empty?
                          @items['filter']   <<  @items['searchIdCol']
                          @items['predicate']<<  '='
                          @items['bindVars'] <<  value
                        end
                        @active_record_model = @active_record_model.where('$or' => [{@items['searchIdCol']=>value}]) if @items['groupBy'].empty?
                      }
                    end
                  end
                end
              elsif @items['searchIdCol'].class.name == 'Array'
                if WidgetList::Utils::numeric?(searchFilter) && ! searchFilter.include?('.')
                  numericSearch = true
                  @items['searchIdCol'].each { |searchIdCol|
                    if fieldsToSearch.key?(searchIdCol)
                      searchSQL << tick_field() + "#{searchIdCol}" + tick_field() + " IN(#{searchFilter})"

                      if $is_mongo

                        if !@items['groupBy'].empty?
                          @items['filter']   <<  searchIdCol
                          @items['predicate']<<  '='
                          @items['bindVars'] <<  searchFilter
                        end
                        @active_record_model = @active_record_model.where('$or' => [{searchIdCol=>searchFilter}]) if @items['groupBy'].empty?
                      end
                    end
                  }

                  if !searchSQL.empty?
                    #
                    # Assemble Numeric Filter
                    #
                    @items['filter'] << "(" + searchSQL.join(' OR ') + ")" unless $is_mongo
                  end
                end
              elsif WidgetList::Utils::numeric?(searchFilter) && ! searchFilter.include?('.') && @items['fields'].key?(@items['searchIdCol'])
                numericSearch = true
                @items['filter'] << tick_field() + "#{@items['searchIdCol']}" + tick_field() + " IN(" + searchFilter + ")" unless $is_mongo

                if $is_mongo

                  if !@items['groupBy'].empty?
                    @items['filter']   <<  @items['searchIdCol']
                    @items['predicate']<<  '='
                    @items['bindVars'] <<  searchFilter
                  end
                  @active_record_model = @active_record_model.where('$or' => [{@items['searchIdCol']=>searchFilter}]) if @items['groupBy'].empty?
                end
              end

              # If it is not an id or a list of ids then it is assumed a string search
              if !numericSearch

                fieldValues = {}

                fieldsToSearch.each { |fieldName,fieldTitle|

                  fieldName = strip_aliases(fieldName)
                  # new lodgette. if fieldFunction exists, find all matches and skip them

                  if @items['fieldFunction'].key?(fieldName)
                    if get_database.db_type == 'oracle'
                      theField = fieldName
                    else
                      theField = @items['fieldFunction'][fieldName]  + cast_col()
                    end
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
                  fieldValues[theField] = searchCriteria

                  if $is_mongo

                    if !@items['groupBy'].empty?
                      @items['filter']   <<  fieldName
                      @items['predicate']<<  '='
                      @items['bindVars'] <<  searchCriteria
                    end

                    if @items['groupBy'].empty? && (@active_record_model.respond_to?(:serializers) &&  ['DateTime','Time','Date'].include?(@active_record_model.serializers[fieldName].type.to_s)) == false
                      if searchCriteria.include?(',')
                        criteriaTmp = searchCriteria.split_it(',')
                        criteriaTmp.each_with_index { |value, key|
                          if !value.empty?
                            @active_record_model = @active_record_model.where('$or' => [{fieldName=>value.strip_or_self()}])
                          end
                        }
                      else
                        @active_record_model = @active_record_model.where('$or' => [{fieldName=>searchCriteria}])
                      end
                    end

                  end
                }

                #
                # Assemble String Filter
                #
                if(! searchSQL.empty?)
                  @items['filter'] << "(" + searchSQL.join(' OR ') + ")" unless $is_mongo
                end
              end
            end
          end

        rescue Exception => e
          @templateFill['<!--DATA-->']  = '<tr><td colspan="50"><div id="noListResults">' + generate_error_output(e) + @items['noDataMessage'] + '</div></td></tr>'
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
                                       <h1 style="font-size:' + get_header_px_value() + ';"><!--TITLE--></h1><div class="horizontal_rule"></div>
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

        if $_SESSION.key?('ROW_LIMIT') && !$_SESSION['ROW_LIMIT'].nil? && $_SESSION['ROW_LIMIT'].key?(@items['name']) && !$_SESSION['ROW_LIMIT'][@items['name']].empty?
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

    def get_grouping_functions()
      #http://docs.oracle.com/cd/E11882_01/server.112/e10592/functions003.htm
      [
          'AVG(',
          'COLLECT(',
          'CORR(',
          'COUNT(',
          'COVAR_POP(',
          'COVAR_SAMP(',
          'CUME_DIST(',
          'DENSE_RANK(',
          'FIRST(',
          'GROUP_ID(',
          'GROUPING_ID(',
          'LAST(',
          'LISTAGG(',
          'MAX(',
          'MEDIAN(',
          'MIN(',
          'PERCENT_RANK(',
          'PERCENTILE_CONT(',
          'PERCENTILE_DISC(',
          'RANK(',
          'REGR_SLOPE(',
          'REGR_INTERCEPT(',
          'REGR_COUNT(',
          'REGR_R2(',
          'REGR_AVGX(',
          'REGR_AVGY(',
          'REGR_SXX(',
          'REGR_SYY(',
          'REGR_SXY(',
          'STATS_MINOMIAL_TEST(',
          'STATS_CROSSTAB(',
          'STATS_F_TEST(',
          'STATS_KS_TEST(',
          'STATS_MODE(',
          'STATS_MW_TEST(',
          'STDDEV(',
          'STDDEV_POP(',
          'STDDEV_SAMP(',
          'SUM(',
          'SYS_XMLAGG(',
          'VAR_POP(',
          'VAR_SAMP(',
          'VARIANCE(',
          'XMLAGG(',
      ]
    end

    def self.get_defaults()
      {
          'errors'              => [],
          'name'                => ([*('A'..'Z'),*('0'..'9')]-%w(0 1 I O)).sample(16).join,
          'database'            => 'primary', #
          'title'               => '',
          'listDescription'     => '',
          'pageId'              => $_SERVER['SCRIPT_NAME'] + $_SERVER['PATH_INFO'],
          'view'                => '',
          'data'                => {},
          'bindVars'            => [],
          'bindVarsLegacy'      => {},
          'links'               => {},
          'buttons'             => {},
          'inputs'              => {},
          'filter'              => [],
          'predicate'           => [],
          'groupBy'             => '',
          'rowStart'            => 0,
          'rowLimit'            => 10,
          'orderBy'             => '',
          'allowHTML'           => true,
          'showPagination'      => true,

          #
          # carryOverRequests will allow you to post custom things from request to all sort/paging URLS for each ajax
          #
          'carryOverRequsts'    => ['switch_grouping','group_row_id','q'],

          #
          # Head/Foot
          #

          'customFooter'        => '',
          'customHeader'        => '',

          #
          # Ajax
          #
          'ajaxFunctionAll'     => '',
          'ajaxFunction'        => 'ListJumpMin',

          #
          #  Search
          #
          'showSearch'          => true,
          'searchOnkeyup'       => "SearchWidgetList('<!--URL-->', '<!--TARGET-->', this);",
          'searchIdCol'         => ($is_mongo) ? '_id' : 'id',
          'searchTitle'         => 'Search by Id or CSV of Ids and more',
          'searchFieldsIn'      => {},
          'searchClear'         => false,
          'searchClearAll'      => false,
          'searchSession'       => true,
          'searchFieldsOut'     => {($is_mongo) ? '_id' : 'id'=>true},
          'templateFilter'      => '',

          #
          #  Export
          #
          'showExport'          => true,
          'exportButtonTitle'   => 'Export CSV',

          #
          # Group By Box
          #
          'groupByItems'        => [],
          'groupBySelected'     => false,
          'groupByLabel'        => 'Group By',
          'groupByClick'        => '',
          'groupByClickDefault' => "ListChangeGrouping('<!--NAME-->', this);",


          #
          # Advanced searching
          #
          'listSearchForm'      => '',
          'ransackSearch'       => false,

          #
          # Column Specific
          #
          'colClass'            => '',
          'colAlign'            => 'center',
          'fields'              => {},
          'fieldsHidden'        => [],
          'columnStyle'         => {},
          'columnClass'         => {},
          'columnPopupTitle'    => {},
          'columnSort'          => {},
          'columnWidth'         => {},
          'columnNoSort'        => {},

          #
          # Column Border (on right of each column)
          #
          'borderedColumns'     => false,
          'borderColumnStyle'   => '1px solid #CCCCCC',

          #
          # Row Border (on top of each row)
          #
          'borderedRows'        => true,
          'borderRowStyle'      => '1px solid #CCCCCC',

          #
          # Head/Foot border
          #
          'borderHeadFoot'      => false,
          'headFootBorderStyle' => '1px solid #CCCCCC',

          'bordersEverywhere?'  => false,
          'borderEverywhere'    => '1px solid #CCCCCC',

          #
          # Buttons
          #
          'defaultButtonClass'  => 'info',

          #
          # Font
          #
          'fontFamily'           => false,  #'"Times New Roman", Times, serif',
          'headerFooterFontSize' => '14px',
          'dataFontSize'         => '14px',
          'titleFontSize'        => '24px',

          #
          # Table Colors
          #
          'footerBGColor'       => '#ECECEC',
          'headerBGColor'       => '#ECECEC',
          'footerFontColor'     => '#494949',
          'headerFontColor'     => '#494949',
          'tableBorder'         => '1',
          'cornerRadius'        => 15,

          'useBoxShadow'        => true,
          'shadowInset'         => 10,
          'shadowSpread'        => 20,
          'shadowColor'         => '#888888',

          #
          # Row specifics
          #
          'rowClass'            => '',
          'rowFontColor'        => 'black',
          'rowColorByStatus'    => {},
          'rowStylesByStatus'   => {},
          'rowOffsets'          => ['#FFFFFF','#FFFFFF'],

          'class'               => 'listContainerPassive',
          'tableclass'          => 'tableBlowOutPreventer',
          'noDataMessage'       => 'Currently no data.',
          'useSort'             => true,
          'headerClass'         => {},
          'fieldFunction'       => {},
          'buttonVal'           => 'templateListJump',
          'linkFunction'        => 'ButtonLinkPost',
          'template'            => '',
          'LIST_COL_SORT_ORDER' => 'ASC',
          'LIST_COL_SORT'       => '',
          'LIST_FILTER_ALL'     => '',
          'ROW_LIMIT'           => '',
          'LIST_SEQUENCE'       => 1,
          'NEW_SEARCH'          => false,

          #
          # Checkbox
          #
          'checkedClass'        => 'widgetlist-checkbox',
          'checkedFlag'         => {},
          'storeSessionChecks'  => false,

          #
          # Summary Row
          #
          'totalRow'            => {},
          'totalRowFirstCol'    => '<strong>Total:</strong>',
          'totalRowMethod'      => {},
          'totalRowPrefix'      => {},
          'totalRowSuffix'      => {},
          'totalRowSeparator'   => '.',
          'totalRowDelimiter'   => ',',
          'totalRowDefault'     => 'N/A',

          #
          # Hooks
          #
          'columnHooks'         => {},
          'rowHooks'            => {}
      }
    end

    def self.init_config()
      list_parms = {}
      WidgetList::List::get_defaults.each { |k,v|
        if (v.is_a?(Array) || v.is_a?(Hash)) && v.empty?
          list_parms[k] = v
        end
      }
      return list_parms
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
      case get_database.db_type
        when 'postgres','mongo','oracle'
          ''
        else
          '`'
      end
    end

    def cast_col()
      case get_database.db_type
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
      } if $_SESSION.key?('list_checks')  && !$_SESSION['list_checks'].nil? && !$_SESSION['list_checks'].empty?

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

      if $_REQUEST.key?('LIST_FILTER_ALL')
        $_REQUEST.delete('LIST_FILTER_ALL')
      end

      if $_REQUEST.key?('LIST_COL_SORT')
        $_REQUEST.delete('LIST_COL_SORT')
      end

      if $_REQUEST.key?('LIST_COL_SORT_ORDER')
        $_REQUEST.delete('LIST_COL_SORT_ORDER')
      end

      if $_REQUEST.key?('LIST_SEQUENCE')
        $_REQUEST.delete('LIST_SEQUENCE')
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
        $_SESSION.deep_merge!({'DRILL_DOWNS' => { listId => drillDown} })
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

    def self.get_group_by_selection(list_parms)
      groupBy = ''

      if $_REQUEST.key?('switch_grouping')
        groupBy = $_REQUEST['switch_grouping']
        $_SESSION.deep_merge!({'CURRENT_GROUPING' => { list_parms['name'] => groupBy} })
      elsif $_SESSION.key?('CURRENT_GROUPING') && !$_SESSION['CURRENT_GROUPING'].nil? && $_SESSION['CURRENT_GROUPING'].key?(list_parms['name'])
        groupBy = $_SESSION['CURRENT_GROUPING'][list_parms['name']]
        list_parms['groupBySelected'] =  groupBy
      else
        groupBy = ''
      end

      return groupBy
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
        if get_database.db_type != 'oracle'
          subtractLimit = @items['rowLimit']
        end
        @items['bindVarsLegacy']['LOW'] = (((@sequence * @items['rowLimit']) -  subtractLimit))
        if get_database.db_type == 'oracle'
          @items['bindVarsLegacy']['HIGH'] = ((((@sequence + 1) * @items['rowLimit'])))
          @items['bindVarsLegacy']['LOW'] = @items['bindVarsLegacy']['LOW'] - @items['rowLimit']
          @items['bindVarsLegacy']['HIGH'] = @items['bindVarsLegacy']['HIGH'] - @items['rowLimit']
        end

      end
    end

    # @param [Hash] results
    # pass results of $DATABASE.final_results after running a _select query
    def render(results={})

      if @isAdministrating
        if $_REQUEST.key?('name')
          return WidgetList::Administration.new.save_and_show_code()
        elsif $_REQUEST.key?('ajax') && $_REQUEST.key?('model')
          return WidgetList::Administration.new.ajax_get_field_json($_REQUEST['model'])
        elsif $_REQUEST.key?('ajax') && $_REQUEST.key?('save')
          return WidgetList::Administration.new.save_and_show_code()
        else
          return WidgetList::Administration.new.show_interface()
        end
      end

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

        build_summary_row()

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

        if $_REQUEST.key?('switch_grouping')
          listJumpUrl['switch_grouping'] = $_REQUEST['switch_grouping']
        end

        @templateFill['<!--CORNER_RADIUS-->']        = get_radius_value()
        @templateFill['<!--BOX_SHADOW-->']           = @items['useBoxShadow'] ? 'box-shadow: <!--SHADOW_INSET--> <!--SHADOW_INSET--> <!--SHADOW_SPREAD--> <!--SHADOW_COLOR-->;'  : ''
        @templateFill['<!--SHADOW_INSET-->']         = get_shadow_inset_value()
        @templateFill['<!--SHADOW_SPREAD-->']        = get_shadow_spread_value()
        @templateFill['<!--SHADOW_COLOR-->']         = @items['shadowColor']
        @templateFill['<!--BORDER_HEAD_FOOT_TOP-->'] = @items['borderHeadFoot'] ? 'border-top:' + @items['headFootBorderStyle'] + ';' : ''
        if @items['fontFamily']
          @templateFill['<!--FONT-->']               = 'font-family:' + @items['fontFamily'] + ';'
        end
        @templateFill['<!--FONT_HEADER-->']          = @items['headerFooterFontSize']


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
        @templateFill['<!--TABLE_BORDER-->']         = @items['tableBorder']
        @templateFill['<!--HEADER_COLOR-->']         = @items['headerBGColor']
        @templateFill['<!--FOOTER_COLOR-->']         = @items['footerBGColor']
        @templateFill['<!--HEADER_TXT_COLOR-->']     = @items['headerFontColor']
        @templateFill['<!--FOOTER_TXT_COLOR-->']     = @items['footerFontColor']
        @templateFill['<!--TITLE-->']                = @items['title']
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

            @templateFill['<!--FILTER_HEADER-->'] = ''

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
                if $_SESSION.key?('SEARCH_FILTER') && !$_SESSION['SEARCH_FILTER'].nil? && $_SESSION['SEARCH_FILTER'].key?(@items['name'])
                  list_search['value'] = $_SESSION['SEARCH_FILTER'][@items['name']]
                end
              end

              #
              # Search Input Field
              #
              list_search['list-search'] = true
              list_search['width']       = '500'
              list_search['input_class'] = 'info-input'
              list_search['title']       = @items['searchTitle']
              list_search['id']          = 'list_search_id_' + @items['name']
              list_search['name']        = 'list_search_name_' + @items['name']
              list_search['class']       = 'inputOuter widget-search-outer ' + @items['name'].downcase + '-search'
              list_search['search_ahead']       = {
                  'url'               => searchUrl,
                  'skip_queue'        => false,
                  'target'            => @items['name'],
                  'search_form'       => @items['listSearchForm'],
                  'onkeyup'           => (! @items['searchOnkeyup'].empty?) ? WidgetList::Utils::fill({'<!--URL-->'=>searchUrl, '<!--TARGET-->' => @items['name'], '<!--FUNCTION_ALL-->' => @items['ajaxFunctionAll']}, @items['searchOnkeyup'] + '<!--FUNCTION_ALL-->') : ''
              }

              fillRansack = {}
              if @items['ransackSearch'] != false
                fillRansack['<!--RANSACK-->'] = ActionController::Base.new.render_to_string(:partial => 'widget_list/ransack_fields', :locals => { 'search_object' => @items['ransackSearch'], 'url' => '--JUMP_URL--'})
              end

              @headerPieces['searchBar']            = WidgetList::Utils::fill(fillRansack,WidgetList::Widgets::widget_input(list_search))
              @templateFill['<!--FILTER_HEADER-->'] = @headerPieces['searchBar']

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
              elsif $_REQUEST.key?('group_row_id')
                tmp                      = $_REQUEST['group_row_id'].gsub(@items['name'] + '_row_','')
                if Float(tmp.to_i) != nil
                  list_group['value']      = @items['groupByItems'][tmp.to_i - 1]
                end
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
                                 </div>'
              }
              if !@templateFill.key?('<!--FILTER_HEADER-->')
                @templateFill['<!--FILTER_HEADER-->'] = ''
              end
              @headerPieces['groupByItems']           = '<div class="fake-select ' + @items['name'] + '-group-by"><div class="label">' + @items['groupByLabel'] + ':</div> ' + WidgetList::Widgets::widget_input(list_group) + '</div>'
              @templateFill['<!--FILTER_HEADER-->']  += @headerPieces['groupByItems']

            end

            if @items['showExport']
              @headerPieces['exportButton']           =  '<span class="' + @items['name'] + '-export">' + WidgetList::Widgets::widget_button(@items['exportButtonTitle'], { 'onclick' => 'ListExport(\'' + @items['name'] + '\');' , 'innerClass' => @items['defaultButtonClass'] }, true) + '</span>'
              @templateFill['<!--FILTER_HEADER-->']  += @headerPieces['exportButton']
            end

          end
        end

        @templateFill['<!--NAME-->']                 = @items['name']
        @templateFill['<!--JUMP_URL-->']             = WidgetList::Utils::build_url(@items['pageId'],listJumpUrl,(!$_REQUEST.key?('BUTTON_VALUE')))
        @templateFill['--JUMP_URL--']                = @templateFill['<!--JUMP_URL-->']
        @templateFill['<!--JUMP_URL_NAME-->']        = @items['name'] + '_jump_url'

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

    def get_radius_value()
      @items['cornerRadius'].to_s.include?('px') ? @items['cornerRadius'].to_s : @items['cornerRadius'].to_s + 'px'
    end

    def get_shadow_inset_value()
      @items['shadowInset'].to_s.include?('px') ? @items['shadowInset'].to_s : @items['shadowInset'].to_s + 'px'
    end

    def get_shadow_spread_value()
      @items['shadowSpread'].to_s.include?('px') ? @items['shadowSpread'].to_s : @items['shadowSpread'].to_s + 'px'
    end

    def get_header_px_value()
      @items['titleFontSize'].to_s.include?('px') ? @items['titleFontSize'].to_s : @items['titleFontSize'].to_s + 'px'
    end

    def get_header_pieces()
      @headerPieces
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
          '<!--PREVIOUS_URL-->' => prevUrl,
          '<!--FUNCTION-->'     => @items['ajaxFunction'],
          '<!--FUNCTION_ALL-->' => @items['ajaxFunctionAll'],
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
        <select id="<!--LIST_NAME-->_per_page" onchange="#{@items['ajaxFunction']}(this.value,'#{@items['name']}');#{@items['ajaxFunctionAll']}" style="width:58px">
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
                                                   '<!--FUNCTION-->'     => @items['ajaxFunction'],
                                                   '<!--FUNCTION_ALL-->' => @items['ajaxFunctionAll'],
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

    def self.build_search_button_click(list_parms)

      extra_get_vars  = ''
      extra_func       = ''
      filterParameters = {}
      if list_parms.key?('ajaxFunctionAll')
        extra_func = list_parms['ajaxFunctionAll']
      end

      if list_parms.key?('carryOverRequsts')
        list_parms['carryOverRequsts'].each { |value|
          if $_REQUEST.key?(value)
            filterParameters[value] = $_REQUEST[value]
          end
        }
        extra_get_vars = WidgetList::Utils::build_query_string(filterParameters)
      end

      "ListJumpMin(jQuery('##{list_parms['name']}_jump_url').val() + '&advanced_search=1&' + jQuery('#list_search_id_#{list_parms['name']}_results *').serialize() + '&#{extra_get_vars}', '#{list_parms['name']}');HideAdvancedSearch(this);" + extra_func
    end

    def build_headers()
      headers = []

      ii = 0
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

        colWidthStyle +=  @items['borderHeadFoot'] ? 'border-bottom:' + @items['headFootBorderStyle'] + ';' : ''

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

        #Add in radius
        if ii == @items['fields'].length - 1 && @items['listDescription'] == ''
          colWidthStyle += '-moz-border-radius-topright:' + get_radius_value() + ';-webkit-border-top-right-radius:' + get_radius_value() + ';border-top-right-radius:' + get_radius_value() + ';'
        end

        if ii == 0 && @items['listDescription'] == ''
          colWidthStyle += '-moz-border-radius-topleft:' + get_radius_value() + ';-webkit-border-top-left-radius:' + get_radius_value() + ';border-top-left-radius:' + get_radius_value() + ';'
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
              ( $_SESSION.key?('LIST_COL_SORT') && !$_SESSION['LIST_COL_SORT'].nil? && $_SESSION['LIST_COL_SORT'].key?(@sqlHash) && $_SESSION['LIST_COL_SORT'][@sqlHash].key?(field))
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

          colSort['SQL_HASH'] = @sqlHash

          pieces = {      '<!--COLSORTURL-->'       => WidgetList::Utils::build_url(@items['pageId'],colSort,(!$_REQUEST.key?('BUTTON_VALUE'))),
                          '<!--NAME-->'             => @items['name'],
                          '<!--COLSORTICON->'       => icon,
                          '<!--COL_HEADER_ID-->'    => strip_tags(field).gsub(/\s/,'_'),
                          '<!--INLINE_STYLE-->'     => colWidthStyle,
                          '<!--TITLE_POPUP-->'      => popupTitle,
                          '<!--ALIGN-->'            => @items['colAlign'],
                          '<!--COL_HEADER_CLASS-->' => colClass,
                          '<!--TITLE-->'            => fieldTitle,
                          '<!--FUNCTION-->'         => @items['ajaxFunction'],
                          '<!--FUNCTION_ALL-->'     => @items['ajaxFunctionAll'],
          }
          headers << WidgetList::Utils::fill(pieces, @items[templateIdx])
        else
          pieces = {      '<!--TITLE-->'            => fieldTitle,
                          '<!--INLINE_STYLE-->'     => colWidthStyle,
                          '<!--ALIGN-->'            => @items['colAlign'],
                          '<!--TITLE_POPUP-->'      => popupTitle,
                          '<!--COL_HEADER_CLASS-->' => colClass,
                          '<!--COL_HEADER_ID-->'    => strip_tags(field).gsub(/\s/,'_')
          }

          headers << WidgetList::Utils::fill(pieces, @items[templateIdx])
        end

        ii = ii + 1
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

          if input.key?('disabled_if') && input['disabled_if'].class.name == 'Proc'
            row_tmp = {}
            @results.map { |column| column }.each { |col|
              row_tmp[ col[0] ] = col[1][row]
            }

            if input['disabled_if'].call(row_tmp)
              input['disabled'] = true
            end
          end

          #
          # Append class handle
          #
          input['input_class'] = "#{input['input_class']} #{input['class_handle']}"

          if input['check_all']
            checkAllId = input['id']
            if $_SESSION.key?('list_checks') && !$_SESSION['list_checks'].nil? && $_SESSION['list_checks'].key?('check_all_' + @sqlHash.to_s  + @items['name'].to_s + @sequence.to_s)
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
          if ! @items['checkedFlag'].empty?
            if @items['checkedFlag'].key?(column)
              input['checked'] =  !!@results[ @items['checkedFlag'][column].upcase ][row]
            end
          end

          #
          # Checkbox is checked or not per session (overwrites query)
          #
          if $_SESSION.key?('list_checks') && !$_SESSION['list_checks'].nil? && $_SESSION['list_checks'].key?(@items['name'] + @sqlHash + input['value'].to_s)
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

      ret = {}
      #
      # If AJAX, send back JSON
      #
      if $_REQUEST.key?('BUTTON_VALUE') && $_REQUEST['LIST_NAME'] == list_parms['name']

        if $_REQUEST.key?('export_widget_list')
          return ['export',list.render()]
        end

        if $_REQUEST['list_action'] != 'ajax_widgetlist_checks'
          ret['list']           = list.render()
          ret['search_bar']     = list.get_header_pieces['searchBar']
          ret['group_by_items'] = list.get_header_pieces['groupByItems']
          ret['export_button']  = list.get_header_pieces['exportButton']
          ret['list_id']        = list_parms['name']
          ret['callback']       = 'ListSearchAheadResponse'
        end

        return ['json',WidgetList::Utils::json_encode(ret)]
      else
        #
        # Else assign to variable for view
        #
        if list.isAdministrating
          return list.render()
        else
          if $widget_list_conf.key?(:api_mode) && $widget_list_conf[:api_mode]
            ret['list']           = list.render()
            return ['json',WidgetList::Utils::json_encode(ret)]
          else
            return ['html', list.render() ]
          end
        end
      end

    end


    def self.parse_inputs_for_mongo_predicates(active_record_model, field, predicate, value_original)
      if active_record_model.respond_to?(:serializers) &&  !active_record_model.serializers.key?(field)
        throw "field #{field} doesnt seem to exist in active record object here are the fields in the model class ==>>>> " + active_record_model.serializers.keys.inspect
      end
      is_int = (active_record_model.respond_to?(:serializers) &&  active_record_model.serializers[field].type.to_s == 'Integer')
      if predicate == '$in'
        #caste CSV string into proper array
        values = value_original.to_i if is_int
        values = value_original unless is_int
        if value_original.include?(',')
          #It is either a CSV or a comma inside the search string
          #
          values = []
          value_original.split_it(',').each { |val|
            values << val.to_i if is_int
            values << val.strip unless is_int
          }
        else
          values = [values]
        end

        return values
      else

        if value_original.class.name == 'Hash'
          the_value = value_original[value_original.keys.first]
        else
          the_value = value_original
        end

        if the_value.include?(',')
          values = []
          the_value.split_it(',').each { |val|
            values << val.strip
          }
          if value_original.class.name == 'Hash'
            final_value = {value_original.keys.first => values}
          else
            final_value = values
          end

        else
          final_value = value_original
        end

        return final_value
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


    def self.group_by_max_each_field(list_parms,group_by_filter)

      #
      # Oracle needs MAX on most fields when grouping in order to shy away from 'not a GROUP BY expression' errors
      #
      if group_by_filter != 'none'
        if list_parms.key?('fieldFunction') && !list_parms['fieldFunction'].empty?
          list_parms['fieldFunction'].each { |k, v|
            if !k.include?('_linked') && k != 'cnt'
              list_parms['fieldFunction'][k] = "MAX(#{v})"
            end
          }
        end

        if list_parms.key?('fieldsHidden') && !list_parms['fieldsHidden'].empty?
          list_parms['fieldsHidden'].each { |k|
            if (list_parms.key?('fieldFunction') && !list_parms['fieldFunction'].empty? && !list_parms['fieldFunction'].key?(k))  || list_parms['fieldFunction'].empty?
              list_parms['fieldFunction'][k] = "MAX(#{k})"
            end
          }
        end

        list_parms['fields'].each { |k|
          if !k.include?('_linked') && k != 'cnt'
            if (list_parms.key?('fieldFunction') && !list_parms['fieldFunction'].empty? && !list_parms['fieldFunction'].key?(k))  || list_parms['fieldFunction'].empty?
              list_parms['fieldFunction'][k] = "MAX(#{k})"
            end
          end
        }
      end

      return list_parms
    end

    def self.drill_down_back(list_name='')
      '<div class="goback" onclick="ListHome(\'' + list_name + '\');" title="Go Back"></div>'
    end

    def self.build_drill_down(*params)
      required_params = {
          :list_id                  => true,              # -- your widget_list name (used for JS)
          :drill_down_name          => true,              # -- an identifier that is pass for the "column" or "type of drill down" which is passed as $_REQUEST['drill_down'] when the user clicks and returned from get_filter_and_drilldown based on session or request
          :data_to_pass_from_view   => true,              # -- Any SQL function or column name/value in the resultset in which would be the value passed when the user clicks the drill down
          :column_to_show           => true,              # -- The visible column or SQL functions to display to user for the link
      }

      optional_params = {
          :column_alias             => '',                # -- AS XXXX
          :extra_function           => '',                # -- Onclick of link, call another JS function after the drill down function is called
          :js_function_name         => 'ListDrillDown',   # -- name of JS Function
          :column_class             => '',                # -- custom class on the <a> tag
          :link_color               => 'blue',            # -- whatever color you want the link to be
          :extra_js_func_params     => '',                # -- Add extra params to ListDrillDown outside of the default
          :primary_database         => true,              # -- Since this function builds a column before widget_list is instantiated, tell which connection you are using
      }

      valid = WidgetList::Widgets::validate_items(params[0],required_params)
      items = WidgetList::Widgets::populate_items(params[0],optional_params)

      if items[:column_alias].empty?
        items[:column_alias] = items[:column_to_show]
      end

      if !items[:column_class].empty?
        items[:column_class] = ' "' + WidgetList::List::concat_string(items[:primary_database]) + items[:column_class] + WidgetList::List::concat_string(items[:primary_database]) + '"'
      end

      if WidgetList::List.get_db_type(items[:primary_database]) == 'oracle'
        link = %[q'[<a style='cursor:pointer;color:#{items[:link_color]};' class='#{items[:column_alias]}_drill#{items[:column_class]}' onclick='#{items[:js_function_name]}("#{items[:drill_down_name]}", ListDrillDownGetRowValue(this) ,"#{items[:list_id]}"#{items[:extra_js_func_params]});#{items[:extra_function]}'>]' #{WidgetList::List::concat_string(items[:primary_database])}#{items[:column_to_show]}#{WidgetList::List::concat_string(items[:primary_database])}q'[</a><script class='val-db' type='text'>]' #{WidgetList::List::concat_string(items[:primary_database])} #{items[:data_to_pass_from_view]} #{WidgetList::List::concat_string(items[:primary_database])} q'[</script>]' #{WidgetList::List::concat_outer(items[:primary_database])} #{WidgetList::List::is_sequel(items[:primary_database]) ? " as #{items[:column_alias]} " : ""}]
      else
        if WidgetList::List.get_db_type(items[:primary_database]) == 'postgres'
          link = %['<a style="cursor:pointer;color:#{items[:link_color]};" class="#{items[:column_alias]}_drill#{items[:column_class]}" onclick="#{items[:js_function_name]}(''#{items[:drill_down_name]}'', ListDrillDownGetRowValue(this) ,''#{items[:list_id]}''#{items[:extra_js_func_params]});#{items[:extra_function]}">"' #{WidgetList::List::concat_string(items[:primary_database])}#{items[:column_to_show]}#{WidgetList::List::concat_string(items[:primary_database])}'</a><script class="val-db" type="text">' #{WidgetList::List::concat_string(items[:primary_database])} #{items[:data_to_pass_from_view]} #{WidgetList::List::concat_string(items[:primary_database])}'</script>' #{WidgetList::List::is_sequel(items[:primary_database]) ? " as #{items[:column_alias]} " : ""}]
        else
          link = %[#{WidgetList::List::concat_inner(items[:primary_database])}"<a style='cursor:pointer;color:#{items[:link_color]};' class='#{items[:column_alias]}_drill#{items[:column_class]}' onclick='#{items[:js_function_name]}(#{WidgetList::List::double_quote(items[:primary_database])}#{items[:drill_down_name]}#{WidgetList::List::double_quote(items[:primary_database])}, ListDrillDownGetRowValue(this) ,#{WidgetList::List::double_quote(items[:primary_database])}#{items[:list_id]}#{WidgetList::List::double_quote(items[:primary_database])}#{items[:extra_js_func_params]});#{items[:extra_function]}'>"#{WidgetList::List::concat_string(items[:primary_database])}#{items[:column_to_show]}#{WidgetList::List::concat_string(items[:primary_database])}"</a><script class='val-db' type='text'>"#{WidgetList::List::concat_string(items[:primary_database])} #{items[:data_to_pass_from_view]} #{WidgetList::List::concat_string(items[:primary_database])}"</script>"#{WidgetList::List::concat_outer(items[:primary_database])} #{WidgetList::List::is_sequel(items[:primary_database]) ? " as #{items[:column_alias]} " : ""}]
        end
      end

      if $_REQUEST.key?('export_widget_list')
        link = "#{items[:column_to_show]} #{WidgetList::List::is_sequel(items[:primary_database]) ? " as #{items[:column_alias]} " : ""}"
      end

      return link

    end

    def self.concat_string(primary)

      case WidgetList::List.get_db_type(primary)
        when 'mysql'
          ' , '
        when 'oracle','sqlite','postgres'
          ' || '
        else
          ','
      end
    end

    def self.double_quote(primary)
      case WidgetList::List.get_db_type(primary)
        when 'mysql'
          '\\"'
        when 'oracle','sqlite'
          '""'
        else
          '"'
      end
    end

    def self.concat_outer(primary)
      case WidgetList::List.get_db_type(primary)
        when 'mysql'
          ')'
        else
          ''
      end
    end

    def self.concat_inner(primary)
      case WidgetList::List.get_db_type(primary)
        when 'mysql'
          'CONCAT('
        else
          ''
      end
    end

    def build_column_button(column,j)
      buttons     = @items['buttons'][column]
      btnOut      = []
      strCnt      = 0
      nameId      = ''

      buttons.each { |buttonId,buttonAttribs|
        function     = @items['linkFunction']
        parameters   = ''
        renderButton = true

        page = buttonAttribs['page'].dup
        if buttonAttribs.key?('tags')
          tags = buttonAttribs['tags'].dup
          all_wildcard = false
          if buttonAttribs['tags'].first[0] == 'all'
            all_wildcard = true
            tags = {}
            @results.keys.each { |tag|
              tags[tag.downcase] = tag.downcase
            }
          end

          tags.each { | tagName , tag |
            if @results.key?(tag.upcase) && @results[tag.upcase][j]
              #
              # Data exists, lets check to see if page has any lowercase tags for restful URLs
              #

              if buttonAttribs.key?('page') && buttonAttribs['page'].include?(tag.downcase)
                page.gsub!(tag.downcase,@results[tag.upcase][j])
              else
                #
                # Will build ?tagname=XXXX based on your hash passed to your page
                #
                buttonAttribs.deep_merge!({ 'args' => { tagName => @results[tag.upcase][j] } }) unless all_wildcard
              end
            else

              #
              # User is passing hard coded tags such as 'tags'       => {'my_static_var' => '1234'}
              # Just fill in normally wherever anything is matched
              #
              if buttonAttribs.key?('page') && buttonAttribs['page'].include?(tag.downcase)
                page.gsub!(tagName,tag)
              else
                buttonAttribs.deep_merge!({ 'args' => { tagName => tag } })
              end
            end
          }
        end
        nameId = buttonId.to_s + '_' + j.to_s

        buttonAttribs['name'] = nameId
        buttonAttribs['id']   = nameId

        if buttonAttribs.key?('hide_if') && input['hide_if'].class.name == 'Proc'
          row_tmp = {}
          @results.map { |column| column }.each { |col|
            row_tmp[ col[0] ] = col[1][row]
          }
          if buttonAttribs['hide_if'].call(row_tmp)
            renderButton = false
          end
        end

        if (renderButton)
          strCnt += (buttonAttribs['text'].length * 15)
          attributes = buttonAttribs.dup
          attributes['page'] = page
          attributes['innerClass'] = @items['defaultButtonClass'] if !attributes.key?('innerClass')
          btnOut << WidgetList::Widgets::widget_button(buttonAttribs['text'], attributes , true)
        end
      }

      #BS width algorithm. HACK/TWEAK/OMG Get it working.
      #
      colWidth = ((strCnt + (btnOut.count * 35)) / 2) + 10

      width = ''
      center = ''

      if @items['colAlign'] == 'center'
        center = 'text-align:center;'
        width = 'width:' + colWidth.to_s + 'px'
      end

      return '<div style="border:0px solid black;white-space:nowrap;margin:auto;' + center + width + '"><div style="margin:auto;display:inline-block">' + btnOut.join('') + '</div></div>'
    end

    # @param [String] column
    def build_column_link(column,j)

      links      = @items['links'][column].dup
      if links.key?('page')
        page      = links['page'].dup
      end
      url        = {'PAGE_ID' => @items['pageId']}
      function   = @items['linkFunction']
      parameters = []

      if links.key?('tags')
        tags = links['tags'].dup
        all_wildcard = false
        if links['tags'].first[0] == 'all'
          all_wildcard = true
          tags = {}
          @results.keys.each { |tag|
            tags[tag.downcase] = tag.downcase
          }
        end

        tags.each { | tagName, tag |

          if links.key?('page') && links['page'].include?(tag.downcase) && @results.key?(tag.upcase)
            page.gsub!(tag.downcase,@results[tag.upcase][j])
          else
            if @results[tag.upcase][j]
              url[tagName] = @results[tag.upcase][j]
            else
              url[tagName] = tag
            end
          end
        }
      end

      if links.key?('onclick')
        function = links['onclick']

        if links.key?('tags')
          tags.each { | tagName, tag |
            if @results.key?(tag.upcase)
              parameters << "'" + @results[tag.upcase][j].gsub(/'/,"\\\\'") + "'"
            end
          }
        end
      end

      if links.key?('page')
        linkUrl = page
        return "#{function}('#{linkUrl}')"
      else
        url['SQL_HASH']      = @sqlHash
        linkUrl = WidgetList::Utils::build_url(@items['pageId'], url, (!$_REQUEST.key?('BUTTON_VALUE')))
        if !parameters.empty?
          return "#{function}(#{parameters.join(',')})"
        else
          return "#{function}('#{linkUrl}')"
        end
      end
    end

    def build_rows()
      sql = build_statement()
      if @totalResultCount > 0
        if @items['data'].empty?
          #Run the actual statement
          #

          #code flow forces me to merge the sort array here
          if !@group_match.nil?
            @group_match = @group_match.merge({"sort"  =>  { "$sort"  =>  @mongo_sort  } }) if !@mongo_sort.empty?
            @group_match = @group_match.merge({"skip"  =>  { "$skip"  =>  @mongo_skip  } })
            @group_match = @group_match.merge({"limit" =>  { "$limit" =>  @mongo_limit } })
            @group_match = @group_match.merge({"match" =>   @mongo_match })
          end

          @totalRowCount = get_database._select(sql , @items['bindVars'], @items['bindVarsLegacy'], @active_record_model, @group_match)
        end

        if @totalRowCount > 0
          if @items['data'].empty?
            @results = get_database.final_results
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

            changedFontColor = false

            @items['fields'].each { |column , fieldTitle|
              column = strip_aliases(column)

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
                colClasses << @items['checkedClass']
                content     = build_column_input(column, j)


                #
                # Column is text
                #
              else

                unless @results.key?(column.upcase)
                  throw "Are you sure that the column #{column} exists in your fields array?  The resultset does not have this field returned from the database"
                end

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

                content = get_database._bind(content, @items['bindVarsLegacy'])

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
              colClasses << @items['colClass']
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
                    if inlineStyle.include?('color:') || inlineStyle.include?('color :')
                      changedFontColor = true
                    end
                  end
                }
              end

              #
              # Set up Column Pieces
              #
              colPieces['<!--CLASS-->']   = colClass
              colPieces['<!--ALIGN-->']   = @items['colAlign']
              colPieces['<!--STYLE-->']   = colWidthStyle

              if @items['borderedColumns']
                colPieces['<!--STYLE-->'] += 'border-right: ' + @items['borderColumnStyle'] + ';'
              end

              if @items['borderedRows']
                colPieces['<!--STYLE-->'] += 'border-top: ' + @items['borderRowStyle'] + ';'
              end

              colPieces['<!--ONCLICK-->'] = onClick

              if !onClick.empty?
                colPieces['<!--SPAN_STYLE-->'] = 'cursor:pointer;' + theStyle
              else
                colPieces['<!--SPAN_STYLE-->'] = '' + theStyle
              end

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

              if( j % 2 ==0)
                rowColor = @items['rowOffsets'][1]
              else
                rowColor = @items['rowOffsets'][0]
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
            pieces['<!--ROWSTYLE-->']    += 'font-size:' + @items['dataFontSize'] + ';'

            if !changedFontColor
              pieces['<!--ROWSTYLE-->']  += 'color:' + @items['rowFontColor'] + ';'
            end

            rows << WidgetList::Utils::fill(pieces, @items['row'])

          end

          @templateFill['<!--DATA-->'] = rows.join('')

        else

          err_message = (get_database.errors) ? @items['noDataMessage'] + ' <span style="color:red">(An error occurred)</span>' : @items['noDataMessage']

          @templateFill['<!--DATA-->'] = '<tr><td colspan="50"><div id="noListResults">' + generate_error_output() + err_message + '</div></td></tr>'

        end

      else

        err_message = (get_database.errors) ? @items['noDataMessage'] + ' <span style="color:red">(An error occurred)</span>' : @items['noDataMessage']

        @templateFill['<!--DATA-->'] = '<tr><td colspan="50"><div id="noListResults">' + generate_error_output() + err_message + '</div></td></tr>'
      end

    end

    def build_summary_row()
      if @totalResultCount > 0 && !@items['totalRow'].empty?

        if @totalRowCount > 0

          columns        = []
          first_col      = true
          @rawTotals     = {}
          row_values     = []


          @items['fields'].each { |column , fieldTitle|
            column = strip_aliases(column)

            colPieces        = {}
            colClasses       = []
            theStyle         = ''
            colData          = ''
            colClass         = ''
            onClick          = ''
            colWidthStyle    = ''
            content          = ''
            contentTitle     = ''

            if first_col
              first_col          = false
              content            = @items['totalRowFirstCol']
              @rawTotals[column] = strip_tags(content)
            else
              if (@items['totalRow'].include?(column) || @items['totalRow'].key?(column) && @results.key?(column.upcase))

                preg_max_precision = Regexp.new('\\' + @items['totalRowSeparator'] + '([0-9]+)')   #/\.([0-9]+)/
                preg_number_value  = Regexp.new('[0-9|\\' + @items['totalRowSeparator'] + '0-9]+') #/[0-9|\.0-9]+/
                preg_strip_commas  = Regexp.new('\\' + @items['totalRowDelimiter'])

                content       = 0
                max_precision = [0]
                raw_value     = 0.0
                prefix        = ''
                suffix        = ''

                @results[column.upcase].each { |val|

                  if val.include?("<script class='val-db'")
                    val = val[0..val.index("<script class='val-db'")-1]
                  end

                  cleanData      = strip_tags(val.to_s)

                  max_precision  << cleanData.match(preg_max_precision)[1].length unless cleanData.match(preg_max_precision).nil?

                  raw_value      = cleanData.gsub(preg_strip_commas,'').match(preg_number_value)[0].to_f  unless cleanData.gsub(preg_strip_commas,'').match(preg_number_value).nil?

                  prefix, suffix = cleanData.gsub(preg_strip_commas,'').split(preg_number_value)
                  prefix = '' if prefix.nil?
                  suffix = '' if suffix.nil?
                  content = content + raw_value
                }


                if @items['totalRowPrefix'].key?(column)
                  prefix = @items['totalRowPrefix'][column]
                end

                if @items['totalRowSuffix'].key?(column)
                  suffix = @items['totalRowSuffix'][column]
                end

                precision = max_precision.max

                if @items['totalRowMethod'].key?(column)

                  case @items['totalRowMethod'][column]
                    when 'average'
                      content =  (content/@totalRowCount).round(precision)
                  end

                end

                @rawTotals[column] = content
                content = number_to_currency(content, :unit => prefix, :precision => precision, :separator => @items['totalRowSeparator'], :delimiter => @items['totalRowDelimiter']) + suffix

              else
                @rawTotals[column] = @items['totalRowDefault']
                content = @items['totalRowDefault']
              end


              row_values << content
            end

            content = get_database._bind(content, @items['bindVarsLegacy'])

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

            #
            # Setup any column classes
            #
            colClasses << @items['colClass']
            colClass = colClasses.join(' ')

            #
            # Set up Column Pieces
            #
            colPieces['<!--CLASS-->']   = colClass
            colPieces['<!--ALIGN-->']   = @items['colAlign']
            colPieces['<!--STYLE-->']   = theStyle  + colWidthStyle

            if @items['borderedColumns']
              colPieces['<!--STYLE-->'] += 'border-right: ' + @items['borderColumnStyle'] + ';'
            end

            if @items['borderedRows']
              colPieces['<!--STYLE-->'] += 'border-top: ' + @items['borderRowStyle'] + ';'
            end

            colPieces['<!--ONCLICK-->']    = onClick
            colPieces['<!--TITLE-->']      = contentTitle #todo htmlentities needed ?
            colPieces['<!--CONTENT-->']    = content
            colPieces['<!--SPAN_STYLE-->'] = ''

            #
            # Assemble the Column
            #
            columns << WidgetList::Utils::fill(colPieces, @items['col'])
          }


          if $_REQUEST.key?('export_widget_list')
            @csv << row_values
          end

          #
          # Draw the row
          #
          pieces = {'<!--CONTENT-->' => columns.join('') }

          pieces['<!--BGCOLOR-->']   = @items['rowOffsets'][@totalRowCount % 2]
          pieces['<!--ROWSTYLE-->']  = ''
          pieces['<!--ROWCLASS-->']  = @items['rowClass']
          pieces['<!--ROWSTYLE-->']    += 'font-size:' + @items['dataFontSize'] + ';'

          @templateFill['<!--DATA-->'] +=  WidgetList::Utils::fill(pieces, @items['row'])

        end

      end

    end

    def generate_error_output(ex='')
      sqlDebug = ""

      if !@items['errors'].empty?
        sqlDebug += "<br/><br/><strong style='color:red'>(" + @items['errors'].join(', ') + ")</strong>"
      end

      if Rails.env == 'development'
        sqlDebug += "<br/><br/><textarea style='width:100%;height:400px;'>" + get_database.last_sql.to_s + "</textarea>"
      end

      if Rails.env == 'development' && get_database.errors
        sqlDebug += "<br/><br/><strong style='color:red'>(" + get_database.last_error.to_s + ")</strong>"
      end

      if Rails.env == 'development' && ex != ''
        sqlDebug += "<br/><br/><strong style='color:red'>(" + ex.to_s + ") <pre>"  + $!.backtrace.join("\n\n") +  "</pre></strong>"
      end

      if Rails.env != 'development'

        if get_database.errors
          Rails.logger.info get_database.last_error.to_s
        end

        if ex != ''
          Rails.logger.info $!.backtrace.join("\n\n")
        end

      end

      Rails.logger.info sqlDebug

      sqlDebug
    end

    def build_statement()

      @mongo_sort = {}
      statement  = ''
      @fieldList      = []
      @fieldListPlain = []
      pieces     =      { '<!--FIELDS_PLAIN-->'  => '',
                          '<!--FIELDS-->'        => '',
                          '<!--SOURCE-->'        => '',
                          '<!--WHERE-->'         => '',
                          '<!--GROUPBY-->'       => '',
                          '<!--ORDERBY-->'       => '',
                          '<!--LIMIT-->'         => ''}

      #Build out a list of columns to select from
      #

      @items['fields'].each { |column, fieldTitle|
        @fieldListPlain << strip_aliases(column)
        if @items['fieldFunction'].key?(column) && !@items['fieldFunction'][column].empty?
          # fieldFunction's should not have an alias, just the database functions
          column = @items['fieldFunction'][column] + " " + column
        end
        @fieldList << column
      }


      if get_database.db_type == 'oracle'
        if !@items['groupBy'].empty?
          @fieldList << 'MAX(rn) as rn'
        else
          @fieldList << 'rn'
        end
        @fieldListPlain << 'rn'
      end

      if @items['fieldsHidden'].class.name == 'Array'
        @items['fieldsHidden'].each { |column|
          if !@items['fields'].key?(column)
            @fieldListPlain << strip_aliases(column)
            if @items['fieldFunction'].key?(column) && !@items['fieldFunction'][column].empty?
              # fieldFunction's should not have an alias, just the database functions
              column = @items['fieldFunction'][column] + " " + column
            end
            @fieldList << column
          end
        }
      elsif @items['fieldsHidden'].class.name == 'Hash'
        @items['fieldsHidden'].each { |column|
          col = column[0]
          if !@items['fields'].key?(col)
            @fieldListPlain << strip_aliases(col)
            if @items['fieldFunction'].key?(column[0]) && !@items['fieldFunction'][column[0]].empty?
              # fieldFunction's should not have an alias, just the database functions
              col = @items['fieldFunction'][column[0]] + " " + column[0]
            end
            @fieldList << col
          end
        }
      end


      viewPieces = {}
      viewPieces['<!--FIELDS_PLAIN-->'] = @fieldListPlain.join(',')
      viewPieces['<!--FIELDS-->'] = @fieldList.join(',')
      viewPieces['<!--SOURCE-->'] = get_view()

      statement = WidgetList::Utils::fill(viewPieces, @items['statement']['select']['view'])

      @sqlHash = Digest::SHA2.hexdigest( WidgetList::Utils::fill(pieces, statement) )

      if @items['searchClear'] || @items['searchClearAll']
        clear_sql_session(@items.key?('searchClearAll'))
      end

      if !$_REQUEST.key?('BUTTON_VALUE') && !$_SESSION['LIST_SEQUENCE'].nil? && $_SESSION.key?('LIST_SEQUENCE') && $_SESSION['LIST_SEQUENCE'].key?(@sqlHash) &&  $_SESSION['LIST_SEQUENCE'][@sqlHash] > 0
        @sequence = $_SESSION['LIST_SEQUENCE'][@sqlHash]
        generate_limits
      end

      if !@filter.empty?
        pieces['<!--WHERE-->'] = ' WHERE ' + @filter
      end

      if !@items['groupBy'].empty?
        pieces['<!--GROUPBY-->'] = ' GROUP BY ' + @items['groupBy']
      else
        pieces['<!--GROUPBY-->'] = ''
      end

      if !@items['LIST_COL_SORT'].empty? || ($_SESSION.key?('LIST_COL_SORT') && $_SESSION['LIST_COL_SORT'].class.name == 'Hash' && $_SESSION['LIST_COL_SORT'].key?(@sqlHash))
        pieces['<!--ORDERBY-->'] += ' ORDER BY '
        foundColumn = false
        if ! @items['LIST_COL_SORT'].empty?
          foundColumn = true
          @mongo_sort[(( @items['LIST_COL_SORT'] != 'cnt') ? '_id.' : '') + @items['LIST_COL_SORT']] = (@items['LIST_COL_SORT_ORDER'] == 'ASC') ? 1 : -1 if $is_mongo
          pieces['<!--ORDERBY-->'] += tick_field() + strip_aliases(@items['LIST_COL_SORT']) + tick_field() + " " + @items['LIST_COL_SORT_ORDER']
        else
          $_SESSION['LIST_COL_SORT'][@sqlHash].each_with_index { |order,void|
            if @items['fields'].key?(order[0])
              foundColumn = true
              @mongo_sort[((order[0] != 'cnt') ? '_id.' : '') + order[0]] = (order[1] == 'ASC') ? 1 : -1 if $is_mongo
              pieces['<!--ORDERBY-->'] += tick_field() + strip_aliases(order[0]) + tick_field() +  " " + order[1]
            end
          } if $_SESSION.key?('LIST_COL_SORT') && $_SESSION['LIST_COL_SORT'].class.name == 'Hash' && $_SESSION['LIST_COL_SORT'].key?(@sqlHash)
        end

        # Add base order by
        if ! @items['orderBy'].empty?
          pieces['<!--ORDERBY-->'] += ',' if foundColumn == true
          pieces['<!--ORDERBY-->'] += @items['orderBy']

          if $is_mongo
            if @items['orderBy'].include?(',')
              criteriaTmp = @items['orderBy'].split_it(',')
            else
              criteriaTmp = [@items['orderBy']]
            end

            criteriaTmp.each { |value|
              @mongo_sort['_id.' + value.gsub(/ASC/,'').gsub(/DESC/,'').strip] = (value.include?('DESC')) ? -1 : 1
            }
          end
        end

      elsif !@items['orderBy'].empty?
        pieces['<!--ORDERBY-->'] += ' ORDER BY ' + @items['orderBy']
      end

      if get_database.db_type == 'oracle' && pieces['<!--ORDERBY-->'].empty?
        #oracle needs a field to perform the rank() over
        #if field is not an "inputs" or a "buttons"
        #if field is all NULL, then you better watch out as paging will NOT work
        tmp  = @items['fields'].dup.reject { |val|
          if (!@items['inputs'].key?(val) && !@items['buttons'].key?(val))
            false
          else
            true
          end
        }

        keys = tmp.keys
        pieces['<!--ORDERBY-->'] += ' ORDER BY ' + strip_aliases(keys[0]) + ' ASC' unless keys[0].nil?
      end

      case get_database.db_type
        when 'postgres'
          pieces['<!--LIMIT-->'] = ' LIMIT :HIGH OFFSET :LOW'
        when 'oracle'

          pieces['<!--LIMIT-->'] =
              '
            WHERE
            (
                 rn >' + (@sequence > 1 ? '' : '=') + ' :LOW
              AND
                 rn <= :HIGH
            )
            '
        else
          pieces['<!--LIMIT-->'] = ' LIMIT :LOW, :HIGH'
      end


      statement = WidgetList::Utils::fill(pieces, statement)

      if @items['rowLimit'].to_i >= @totalRows
        @items['bindVarsLegacy']['LOW'] = 0
        @sequence = 1
      end


      if $is_mongo

        #
        # Ordering in mongo object
        #

        columnordering = pieces['<!--ORDERBY-->'].gsub!(/ORDER BY/,'')
        pieces['<!--ORDERBY-->'] = columnordering.strip unless columnordering.nil?
        @active_record_model = @active_record_model.order_by(pieces['<!--ORDERBY-->'])  unless columnordering.nil?

        #
        # Limits in mongo
        #
        @active_record_model = @active_record_model.skip(@items['bindVarsLegacy']['LOW'].to_i).limit(@items['rowLimit'].to_i)

        @mongo_skip  = @items['bindVarsLegacy']['LOW'].to_i
        @mongo_limit = @items['rowLimit'].to_i

      end
      statement
    end

    def strip_aliases(name='')
      name = (name.include?(' ') ? name.split(' ').last : name)
      ((name.include?('.')) ? name.split('.').last.gsub(/'||"/,'') : name.gsub(/'||"/,''))
    end

    def auto_column_name(name='')
      name.gsub(/\_/,' ').gsub(/\-/,' ').capitalize
    end

    def self.mysql_to_mongo_predicate(predicate='=',value='',build_mongo_expression_hash=false)
      functioncall = ''
      case predicate
        when '>','gt'
          functioncall = 'gt'
        when 'in','in'
          functioncall = 'in'
        when '>=','gte'
          functioncall = 'gte'
        when '<','lt'
          functioncall = 'lt'
        when '<=','lte'
          functioncall = 'lte'
        when '!=','ne'
          functioncall = 'ne'
        else
          functioncall = ''
      end
      if build_mongo_expression_hash
        if functioncall.empty?
          #when using the aggregation framework in mongoid, you do not pass {$eq => 'val'}, you pass just the value associated with the column
          return value
        else
          return {'$' + functioncall => value}
        end
      else
        return functioncall
      end
    end

    def self.where(list_parms,field,value,predicate='=')
      if $is_mongo
        list_parms['predicate'] <<  WidgetList::List.mysql_to_mongo_predicate(predicate,value,false)
      end
      list_parms['filter']    << field
      list_parms['bindVars']  << value
      return list_parms
    end

    def get_total_records()

      filter = ''
      fields = {}
      sql    = ''
      hashed = false

      if !get_view().empty?
        sql = WidgetList::Utils::fill({'<!--VIEW-->' => get_view(),'<!--GROUPBY-->' => !@items['groupBy'].empty? ? ' GROUP BY ' + @items['groupBy'] : '' }, @items['statement']['count']['view'])
      end

      if $is_mongo

        @active_record_model = @active_record_model.skip(0) #turn object into Mongoid::Criteria which has all the column definitions needed in _select

        #
        # List filters
        #
        @mongo_match = []
        @items['filter'].each_with_index { |value, key|
          field = value.to_sym
          predicate = ''
          if @items.key?('predicate') && !@items['predicate'][key].nil? && !@items['predicate'][key].empty? && value.to_sym.respond_to?(@items['predicate'][key])
            field = field.send(@items['predicate'][key])
            predicate = '$' + @items['predicate'][key]
          end

          @active_record_model = @active_record_model.where('$and' => [{
                                                                           field => WidgetList::List.parse_inputs_for_mongo_predicates(@active_record_model, value, predicate, @items['bindVars'][key])
                                                                       }]) if @items['groupBy'].empty?
          @mongo_match << { value =>  WidgetList::List.mysql_to_mongo_predicate(@items['predicate'][key],@items['bindVars'][key],true) } if @items['fields'].key?(value)
        } if @items.key?('filter') && !@items['filter'].empty?

        if !@items['groupBy'].empty?

          if @items['groupBy'].include?(',')
            criteriaTmp = @items['groupBy'].split_it(',')
          else
            criteriaTmp = [@items['groupBy']]
          end

          map_groups = {}
          criteriaTmp.each { |value|
            map_groups[value] =  "$#{value}"
          }
          #
          @group_match =
              {
                  "group" =>  {"$group" => { "_id" => map_groups , "cnt" => { "$sum" => 1 } } },
              }
        end

      else

        if ! @filter.empty?
          filter = ' WHERE ' + @filter
        end
        sql = WidgetList::Utils::fill({'<!--WHERE-->' => filter}, sql)
      end

      if ! sql.empty? || $is_mongo
        if @items['showPagination']

          tmp_match = @group_match

          if $is_mongo
            if !tmp_match.nil?
              tmp_match = @group_match.dup
              tmp_match = tmp_match.merge({"match" =>   @mongo_match })
            end
          end

          cnt = get_database._select( $is_mongo ? 'count' : sql, @items['bindVars'], @items['bindVarsLegacy'], @active_record_model, tmp_match)
          if cnt > 0
            if cnt > get_database.final_results['TOTAL'][0].to_i
              #sometimes databases and queries run do not count(1) and group properly and instead
              rows = cnt
            else
              rows = get_database.final_results['TOTAL'][0].to_i
            end
          else
            rows = 0
          end
          if rows > 0
            @totalRows = rows.to_i
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

    def self.determine_db_type(db_type)
      if db_type.include?('://')
        the_type, void = db_type.split("://")
        if the_type == 'sqlite:/'
          the_type = 'sqlite'
        end
        return the_type.downcase
      else
        begin
          WidgetList::List::load_widget_list_database_yml()

          if $is_mongo
            return 'mongo'
          else
            if $widget_list_db_conf.key?(db_type)
              if $widget_list_db_conf[db_type]['adapter'].include?('mysql')
                return 'mysql'
              elsif $widget_list_db_conf[db_type]['adapter'].include?('postgres')
                return 'postgres'
              elsif $widget_list_db_conf[db_type]['adapter'].include?('oracle')
                return 'oracle'
              elsif $widget_list_db_conf[db_type]['adapter'].include?('sqlite')
                return 'sqlite'
              elsif $widget_list_db_conf[db_type]['adapter'].include?('sqlserver')
                return 'sqlserver'
              elsif $widget_list_db_conf[db_type]['adapter'].include?('ibm')
                return 'db2'
              end
            end
          end
        rescue
          return ''
        end

      end
    end

    def self.load_widget_list_yml
      if $widget_list_conf.nil?
        $widget_list_conf = YAML.load(ERB.new(File.new(Rails.root.join("config", "widget-list.yml")).read).result)[Rails.env]
        if Rails.root.join("app/helpers", "widget_list_helper.rb").file?
          require Rails.root.join("app/helpers", "widget_list_helper.rb")
        end
      end
    end

    def self.load_widget_list_database_yml
      if $widget_list_db_conf.nil?
        if Rails.root.join("config", "mongoid.yml").file?
          $is_mongo            = true
          $widget_list_db_conf = YAML.load(ERB.new(File.new(Rails.root.join("config", "mongoid.yml")).read).result)
        else
          $is_mongo            = false
          $widget_list_db_conf = YAML.load(ERB.new(File.new(Rails.root.join("config", "database.yml")).read).result)
        end
      end
    end

    def self.get_db_type(primary=true)
      WidgetList::List::load_widget_list_yml()
      if primary
        database_conn = $widget_list_conf[:primary]
      else
        database_conn = $widget_list_conf[:secondary]
      end
      WidgetList::List::determine_db_type(database_conn)
    end

    def get_db_type(primary=true)
      WidgetList::List::get_db_type(primary)
    end

    def get_view
      initializing = false
      if @active_record_model.nil?
        initializing = true
        @active_record_model = false
      end
      if (@is_primary_sequel && @items['database'] == 'primary') ||  (@is_secondary_sequel && @items['database'] == 'secondary')
        return @items['view']
      elsif $is_mongo || (@items['view'].respond_to?('scoped') && @items['view'].scoped.respond_to?('to_sql'))
        @active_record_model = @items['view'].name.constantize if initializing
        new_columns = []

        @items['fields'].each { |column, fieldTitle|
          if @items['fieldFunction'].key?(column) && !@items['fieldFunction'][column].empty?
            # fieldFunction's should not have an alias, just the database functions
            column = @items['fieldFunction'][column] + " " + column
          end
          new_columns << column
        }

        if @items['fieldsHidden'].class.name == 'Array' && !@items['fieldsHidden'].empty?
          @items['fieldsHidden'].each { |columnPivot|
            if !@items['fields'].key?(columnPivot)
              if @items['fieldFunction'].key?(columnPivot) && !@items['fieldFunction'][columnPivot].empty?
                # fieldFunction's should not have an alias, just the database functions
                columnPivot = @items['fieldFunction'][columnPivot] + " " + columnPivot
              end
              new_columns << columnPivot
            end
          }
        elsif @items['fieldsHidden'].class.name == 'Hash' && !@items['fieldsHidden'].empty?
          @items['fieldsHidden'].each { |columnPivot|
            if !@items['fields'].key?(columnPivot[0])
              if @items['fieldFunction'].key?(columnPivot[0]) && !@items['fieldFunction'][columnPivot[0]].empty?
                # fieldFunction's should not have an alias, just the database functions
                columnPivot[0] = @items['fieldFunction'][columnPivot[0]] + " " + columnPivot[0]
              end
              new_columns << columnPivot[0]
            end
          }
        end

        if $is_mongo
          return ''
        else
          view     = @items['view'].scoped.to_sql
          sql_from = view[view.index(/FROM/),view.length]
          view     = "SELECT #{new_columns.join(',')} " + sql_from
          where    = ''
          if !@items['groupBy'].empty?
            where    = '<!--WHERE-->'
          end

          return "( #{view} #{where} <!--GROUPBY--> ) a"
        end
      else
        return ""
      end
    end

    def connect

      @has_connected = true
      begin
        if Rails.root.join("config", "widget-list.yml").file?
          WidgetList::List::load_widget_list_yml()
          if $widget_list_conf.nil?
            throw 'Configuration file widget-list.yml has no data.  Check that (' + Rails.env + ') Rails.env matches the pointers in the file'
          end
          @primary_conn   = $widget_list_conf[:primary]
          @secondary_conn = $widget_list_conf[:secondary]
        else
          throw 'widget-list.yml not found'
        end

        @is_primary_sequel                 = true
        @is_secondary_sequel               = true
        if @primary_conn != false && ! @primary_conn.include?(':/')
          @is_primary_sequel               = false
        end

        if @secondary_conn != false && !@secondary_conn.include?(':/')
          @is_secondary_sequel             = false
        end

        if @primary_conn != false
          if @primary_conn.include?(':/')
            @widget_list_sequel_conn         = Sequel.connect(@primary_conn)
            @widget_list_sequel_conn.db_type = WidgetList::List::determine_db_type(@primary_conn)
          else
            @widget_list_ar_conn             = WidgetListActiveRecord.new
            @widget_list_ar_conn.db_type     = WidgetList::List::determine_db_type(@primary_conn)
          end
        end

        if @secondary_conn != false
          if @secondary_conn.include?(':/')
            @widget_list_sequel_conn2         = Sequel.connect(@secondary_conn)
            @widget_list_sequel_conn2.db_type = WidgetList::List::determine_db_type(@secondary_conn)
          else
            @widget_list_ar_conn2             = WidgetListActiveRecord.new
            @widget_list_ar_conn2.db_type     = WidgetList::List::determine_db_type(@secondary_conn)
          end
        end

      rescue Exception => e
        Rails.logger.info "widget-list.yml and connection to @widget_list_sequel_conn or @widget_list_sequel_conn2 failed.  Please fix and try again (" + e.to_s + ")"
      end

    end


    def self.is_sequel(primary)
      WidgetList::List::load_widget_list_yml()
      if primary
        database_conn = $widget_list_conf[:primary]
      else
        database_conn = $widget_list_conf[:secondary]
      end
      is_sequel = true
      if database_conn != false && ! database_conn.include?('://')
        is_sequel = false
      end
      return is_sequel
    end

    def self.get_sequel(primary=true)
      WidgetList::List::load_widget_list_yml()
      if primary
        Sequel.connect($widget_list_conf[:primary])
      else
        Sequel.connect($widget_list_conf[:secondary])
      end
    end

    def get_database

      if @has_connected.nil?
        connect
      end

      if @is_primary_sequel && @widget_list_sequel_conn.class.name.to_s.split('::').first == 'Sequel' && @current_db_selection == 'primary' || @current_db_selection.nil?
        @widget_list_sequel_conn.test_connection
      end

      if @is_secondary_sequel && @widget_list_sequel_conn2.class.name.to_s.split('::').first == 'Sequel' && @current_db_selection == 'secondary'
        @widget_list_sequel_conn2.test_connection
      end

      case @current_db_selection
        when 'primary'
          return (@is_primary_sequel) ? @widget_list_sequel_conn : @widget_list_ar_conn
        when 'secondary'
          return (@is_secondary_sequel) ? @widget_list_sequel_conn2 : @widget_list_ar_conn2
        else
          return (@is_primary_sequel) ? @widget_list_sequel_conn : @widget_list_ar_conn
      end

    end

  end

end