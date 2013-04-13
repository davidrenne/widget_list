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
      eval(WidgetList::Administration.new.translate_config_to_code(true))
      return @output
    else
      list = WidgetList::List.new()
      return list.render()
    end
  end

  class Administration
    def show_interface()
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
      # BASE
      #
      @fill['<!--POST_URL-->']                  = $_SERVER['PATH_INFO']
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
      @fill['<!--NAME_VALUE-->']                = (!@isEditing) ? config_id : page_config['name']
      @fill['<!--VIEW_OPTIONS-->']              = model_options
      @fill['<!--TITLE_VALUE-->']               = (!@isEditing) ? '' : page_config['title']
      @fill['<!--DESC_VALUE-->']                = (!@isEditing) ? '' : page_config['listDescription']

      #
      # FIELD LEVEL
      #

      @fill['<!--NO_DATA_VALUE-->']             = (!@isEditing) ? ''        : page_config['noDataMessage']
      @fill['<!--SORTING_CHECKED-->']           = (!@isEditing) ? 'checked' : (page_config['useSort'] == "1") ? 'checked' : ''

      @fieldFill = {}
      @fieldFill['<!--REMOVE_FIELD_BUTTON-->']  = remove_field_button()
      @fieldFill['<!--FIELD_VALUE-->']          = ''
      @fieldFill['<!--FIELD_DESC-->']           = ''
      @fieldFill['<!--SUBJECT-->']              = 'fields'
      @fieldFill['<!--FIELD-->']                = 'Field'
      @fieldFill['<!--DESC-->']                 = 'Desc'
      @fieldFill['<!--DISABLED-->']             = ''
      @fill['<!--FIELD_TEMPLATE-->']            = WidgetList::Utils::fill(@fieldFill , ac.render_to_string(:partial => 'widget_list/administration/field_row') )
      @fill['<!--ADD_FIELD_BUTTON-->']          = WidgetList::Widgets::widget_button('Add Field',  {'onclick' => "AddField();", 'innerClass' => "success" } )
      @fill['<!--ALL_FIELDS-->']                = (!@isEditing) ? '' : page_json['fields']


      @fill['<!--SHOW_HIDDEN_CHECKED-->']       = (!@isEditing) ? '' : (page_config['showHidden'] == "1")  ? 'checked' : ''
      @fieldFill = {}
      @fieldFill['<!--REMOVE_FIELD_BUTTON-->']  = remove_field_button()
      @fieldFill['<!--FIELD_VALUE-->']          = ''
      @fieldFill['<!--FIELD_DESC-->']           = ''
      @fieldFill['<!--SUBJECT-->']              = 'fields_hidden'
      @fieldFill['<!--FIELD-->']                = 'Field'
      @fieldFill['<!--DESC-->']                 = 'Desc'
      @fieldFill['<!--DISABLED-->']             = 'disabled'
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
      @fieldFill['<!--BUTTON_URL-->']           = '/'
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
      @fill['<!--USE_RANSACK-->']               = (!@isEditing) ? 'checked' : (page_config['useRansack'] == "1")  ? 'checked' : ''
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
      @fill['<!--DEFAULT_GROUPING-->']          = WidgetList::Utils::fill(@fieldFill , ac.render_to_string(:partial => 'widget_list/administration/field_row') )
      @fill['<!--ADD_GROUP_BY_BUTTON-->']       = WidgetList::Widgets::widget_button('Add New Group By',  {'onclick' => "AddGroupBy();", 'innerClass' => "success" } )
      @fill['<!--GROUPING_ITEMS-->']            = (!@isEditing) ? '' : page_json['group_by']



      #
      # FOOTER
      #

      @fieldFill = {}
      @fieldFill['<!--REMOVE_FIELD_BUTTON-->']  = remove_field_button()
      @fieldFill['<!--BUTTON_TEXT-->']          = 'Button Text'
      @fieldFill['<!--BUTTON_URL-->']           = '/'
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
      @help['<!--ROW_HELP_BUTTON-->']           = "10,20,50,100,500,1000 are supported"
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

    def translate_config_to_code(tmp=false)
      config_id, page_config = get_configuration(tmp)
      fields,fields_hidden,fields_function,buttons,footer_buttons,group_by,drill_downs = normalize_configs(page_config)
      drill_down_code  = ''
      case_statements  = ''
      case_statements2 = ''
      drill_down_links = ''
      view_code        = ''
      export_code      = ''
      visible_field_code       = ''
      hidden_field_code       = ''
      variable_code    = ''
      checkbox_code    = ''
      button_code      = ''
      grouping_code    = ''
      field_function_code      = ''

      #------------ DRILL DOWNS ------------
      if page_config['drillDownsOn'] == "1" && !drill_downs.empty?
        #@todo - (groupByFilter == 'none') ? 'a.name' : 'MAX(a.name)'

        drill_downs.each { |field|
          drill_down_links+= "
        list_parms['fieldFunction']['#{field[1]['column_to_show']}']    = WidgetList::List::build_drill_down(
          :list_id => list_parms['name'],
          :drill_down_name => '#{field[0]}',
          :data_to_pass_from_view => '#{field[1]['column_to_show'].gsub(/_linked/,'')}',
          :column_to_show => '#{field[1]['column_to_show'].gsub(/_linked/,'')}',
          :column_alias => '#{field[1]['column_to_show']}'
        )"
          case_statements += <<-EOD

        when '#{field[0]}'
          list_parms['filter']   << " #{field[1]['column_to_show'].gsub(/_linked/,'')} = ? "
          list_parms['bindVars'] << #{page_config['view']}.sanitize(filterValue)
          list_parms['listDescription']  = ' Filtered by #{field[1]['column_to_show'].gsub(/_linked/,'').camelize} (' + filterValue + ')'
          EOD
        }

        drill_down_code = <<-EOD

      #
      # Handle Dynamic Filters
      #

      drillDown, filterValue  = WidgetList::List::get_filter_and_drilldown(list_parms['name'])

      case drillDown#{case_statements}
        else
          list_parms['listDescription']  = '#{page_config['listDescription']}'
      end
        EOD

      else
        drill_down_code = "
      list_parms['listDescription']  = '#{page_config['listDescription']}'
        "
      end


      if page_config['rowButtonsOn'] == '1'
        variable_code += "
      button_column_name          = '#{page_config['rowButtonsName']}'"
      end

      #------------ VIEW ------------

      if page_config['useRansack'] == '1' && page_config['showSearch'] == '1'
        view_code = "
      list_parms['ransackSearch']  = #{page_config['view']}.search($_REQUEST[:q])
      list_parms['view']           = list_parms['ransackSearch'].result
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
      list_parms['view']           = #{page_config['view']}
        "
      end

      #------------ EXPORT ------------

      if page_config['showExport'] == '1' && page_config['showSearch'] == '1'
        export_code += "list_parms['showExport']        = #{page_config['showExport'] == '1' ? 'true' : 'false'}
      list_parms['exportButtonTitle'] = '#{page_config['exportButtonTitle']}'"
      end

      if page_config['showSearch'] == '1'
        export_code += "
      list_parms['searchTitle']        = '#{page_config['searchTitle']}'"
      end


      #------------ VISIBLE FIELDS ------------
      if page_config['checkboxEnabled'] == '1'
        checkbox_code += "
      list_parms = WidgetList::List.checkbox_helper(list_parms,'#{page_config['checkboxField']}')
        "
        visible_field_code += "
      list_parms['fields']['checkbox']           = 'checkbox_header'"
      end

      fields.each { |field,description|
        visible_field_code += "
      list_parms['fields']['#{field}']           = '#{description}'"
      }

      #------------ BUTTONS ------------

      if page_config['rowButtonsOn'] == '1'
        visible_field_code += "
      list_parms['fields'][button_column_name.downcase] = button_column_name.capitalize"
      end

      button_code += "
      mini_buttons = {}
      "

      buttons.each { |field|
        button_code += "
      mini_buttons['button_#{field[0].downcase}'] = {'page'       => '#{field[1]['url']}',
                                                     'text'       => '#{field[0]}',
                                                     'function'   => 'Redirect',
                                                     'innerClass' => '#{field[1]['class']}',
                                                     'tags'       => {'all'=>'all'}
                                                    }
      "
      }

      button_code += "
      list_parms['buttons']       = {button_column_name.downcase => mini_buttons}
      "



      #------------ FOOTER ------------
      if page_config['footerOn'] == '1' && !footer_buttons.empty?
        btns = []
        footer_buttons.each {|field|
          btns << " WidgetList::Widgets::widget_button('#{field[0]}', {'page'       => '#{field[1]['url']}','innerClass' => '#{field[1]['class']}'})"
        }

        button_code += "
      list_parms['customFooter'] = " + btns.join(' + ')
      end




      #------------ GROUPING ------------

      if page_config['useGrouping'] == '1' && page_config['showSearch'] == '1' && !group_by.empty?
        variable_code += "
      groupByDesc          = ''     # Initialize a variable you can use in listDescription to show what the current grouping selection is
      groupByFilter        = 'none' # This variable should be used to control business logic based on the grouping and is a short hand key rather than using what is returned from get_group_by_selection
        "
        descriptions = []
        group_by.each { |field,description|
          descriptions << "'" + description + "'"
          desc = ''
          filter = ''
          unless field.empty?
            desc = " (Grouped By #{field.camelize})"
            filter = "group_#{description.gsub(/ /,'_').downcase}"
          else
            filter = 'none'
          end
          case_statements2 += <<-EOD

        when '#{description}'
          list_parms['groupBy']  = '#{field}'
          groupByFilter          = '#{filter}'
          groupByDesc            = '#{desc}'
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
        list_parms['groupByItems'] = " + '[' + descriptions.join(', ') + ']' + ""
      end



      #------------ FIELD FUNCTIONS ------------

      if page_config['fieldFunctionOn'] == '1' && !fields_function.empty?
        fields_function.each { |field,command|
          field_function_code += "
      list_parms['fieldFunction']['#{field}']           = '#{command}'"
        }
      end

      if page_config['showHidden'] == '1'
        fields_hidden.each { |field|
          hidden_field_code += "
      list_parms['fieldsHidden'] << '#{field[1]}'"
        }
      end

      if page_config['rowButtonsOn'] == '1'
        field_function_code += "
      list_parms['fieldFunction'][button_column_name.downcase] = \"''\""
      end


      if page_config['checkboxEnabled'] == '1'
        field_function_code += "
      list_parms['fieldFunction']['checkbox'] = \"''\""
      end

      <<-EOD
    begin

      #{variable_code}
      list_parms                    = WidgetList::List::init_config()
      list_parms['name']            = '#{page_config['name']}'
      list_parms['noDataMessage']   = '#{page_config['noDataMessage']}'
      list_parms['rowLimit']        = '#{page_config['rowLimit']}'
      list_parms['title']           = '#{page_config['title']}'
      list_parms['listDescription'] = '#{page_config['listDescription']}'
      list_parms['useSort']         =  #{page_config['useSort'] == '1' ? 'true' : 'false'}
      #{export_code}

      #{drill_down_code}
      #{drill_down_links}
      #{grouping_code}

      #{visible_field_code}
      #{hidden_field_code}
      #{field_function_code}

      #{view_code}

      #{checkbox_code}
      #{button_code}


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

    def get_configuration(tmp=false)
      temp = (tmp) ? '-tmp': ''

      request = $_REQUEST.dup
      config_id =  ''
      config_id += request['controller'] if request.key?('controller')
      config_id += request['action'] if request.key?('action')
      config_file = Rails.root.join("config", "widget-list-administration#{temp}.json")

      if config_file.file?
        configuration = JSON.parse(File.new(Rails.root.join("config", "widget-list-administration#{temp}.json")).read)
      else
        configuration = {}
      end

      if configuration.key?(config_id)
        @isEditing  = true
        page_config = configuration[config_id]

        ['useSort','showHidden','fieldFunctionOn','rowButtonsOn','drillDownsOn','showSearch','showExport','useRansack','ransackAdvancedForm','useGrouping','footerOn','checkboxEnabled'].each { |item|
          unless page_config.key?(item)
            page_config[item] = "0"
          end
        }
      else
        @isEditing  = false
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
      fields_hidden      = {}
      fields_function    = {}
      buttons            = {}
      footer_buttons     = {}
      group_by           = {}
      drill_downs        = {}

      if page_config.key?('fields')
        page_config['fields']['key'].each_with_index { |v,k|
          fields[v] = page_config['fields']['description'][k.to_i]
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

      return [fields,fields_hidden,fields_function,buttons,footer_buttons,group_by,drill_downs]
    end

    def ajax_get_field_json(model_name)
      config_id, page_config = get_configuration()
      ac = ActionController::Base.new()
      @response          = {}
      fields             = {}
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

        fields,fields_hidden,fields_function,buttons,footer_buttons,group_by,drill_downs = normalize_configs(page_config)
      else
        if $_REQUEST.key?('ajax')
          model         = model_name.constantize.new
          model.attributes.keys.each { |field|
            fields[field] = field.gsub(/_/,' _').camelize
            all_fields[field] = field.gsub(/_/,' _').camelize
            fields_function[field] = 'CNT(' + field + ') or NVL(' + field + ') or TO_DATE(' + field + ') etc...'
          }
          footer_buttons['Add New ' + model_name]            = {}
          footer_buttons['Add New ' + model_name]['url']     = '/' + $_REQUEST['controller'] + '/add/'
          footer_buttons['Add New ' + model_name]['class']   = 'info'
        end
        buttons['Edit']              = {}
        buttons['Delete']            = {}

        buttons['Delete']['class']   = 'danger'
        buttons['Delete']['url']     = '/' + $_REQUEST['controller'] + '/delete/id/'
        buttons['Edit']['url']       = '/' + $_REQUEST['controller'] + '/edit/id/'
        buttons['Edit']['class']     = 'info'
        if $_REQUEST.key?('ajax')
          group_by['']               = 'All ' + model_name + 's'
          group_by['field_name']     = 'This will group by field_name and show Count'
          buttons['Delete']['url']   = '/' + $_REQUEST['controller'] + '/delete/' + fields.keys.first + '/'
          buttons['Edit']['url']     = '/' + $_REQUEST['controller'] + '/edit/' + fields.keys.first + '/'
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
        @fieldFill['<!--REMOVE_FIELD_BUTTON-->'] = remove_field_button()
        @fieldFill['<!--FIELD-->']               = 'Field'
        @fieldFill['<!--DESC-->']                = 'Desc'
        @fieldFill['<!--DISABLED-->']            = ''
        @response['fields'] += WidgetList::Utils::fill(@fieldFill , ac.render_to_string(:partial => 'widget_list/administration/field_row') )
      }

      fields_hidden.each { |field|
        @fieldFill = {}
        @fieldFill['<!--SUBJECT-->']             = 'fields_hidden'
        @fieldFill['<!--FIELD_VALUE-->']         = field[1]
        @fieldFill['<!--FIELD_DESC-->']          = ''
        @fieldFill['<!--REMOVE_FIELD_BUTTON-->'] = remove_field_button()
        @fieldFill['<!--DESC-->']                = 'Desc'
        @fieldFill['<!--FIELD-->']               = 'Field'
        @fieldFill['<!--DISABLED-->']            = 'disabled'
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
        @fieldFill['<!--DISABLED-->']             = ''
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

    def save_and_show_code()
      ac = ActionController::Base.new()
      request = $_REQUEST.dup
      config_id =  ''
      config_id += request['controller'] if request.key?('controller')
      config_id += request['action'] if request.key?('action')

      tmp = (request.key?('ajax')) ? '-tmp': ''

      config_file = Rails.root.join("config", "widget-list-administration#{tmp}.json")
      if config_file.file?
        configuration = JSON.parse(File.new(Rails.root.join("config", "widget-list-administration#{tmp}.json")).read)
      else
        configuration = {}
      end
      configuration[config_id] = request

      File.open(Rails.root.join("config", "widget-list-administration#{tmp}.json"), "w") do |file|
        file.puts configuration.to_json
      end


      @fill = {}
      unless request.key?('ajax')
        @fill['<!--CODE-->'] = translate_config_to_code()
      end
      return WidgetList::Utils::fill(@fill , ac.render_to_string(:partial => 'widget_list/administration/output_save') )  unless request.key?('ajax')
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


      @items.deep_merge!({ 'statement' =>
                               {'select'=>
                                    {'view' =>
                                         '
                                   SELECT <!--FIELDS--> FROM <!--SOURCE--> <!--WHERE--> <!--GROUPBY--> <!--ORDERBY--> <!--LIMIT-->
                                  '
                                    }
                               }
                         })

      @items.deep_merge!({ 'statement' =>
                               {'count'=>
                                    {'view' =>
                                         '
                                   SELECT count(1) total FROM <!--VIEW--> <!--WHERE--> <!--GROUPBY-->
                                  '
                                    }
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

        if @items['searchClear'] || @items['searchClearAll']
          clear_search_session(@items.key?('searchClearAll'))
        end

        matchesCurrentList   = $_REQUEST.key?('BUTTON_VALUE') && $_REQUEST['BUTTON_VALUE'] == @items['buttonVal']
        isSearchRequest      = $_REQUEST.key?('search_filter') && $_REQUEST['search_filter'] != 'undefined'
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
          'pageId'              => $_SERVER['PATH_INFO'],
          'view'                => '',
          'data'                => {},
          'collClass'           => '',
          'collAlign'           => '',
          'fields'              => {},
          'fieldsHidden'        => [],
          'bindVars'            => [],
          'bindVarsLegacy'      => {},
          'links'               => {},
          'buttons'             => {},
          'inputs'              => {},
          'filter'              => [],
          'groupBy'             => '',
          'rowStart'            => 0,
          'rowLimit'            => 10,
          'orderBy'             => '',
          'allowHTML'           => true,
          'searchClear'         => false,
          'searchClearAll'      => false,
          'showPagination'      => true,
          'searchSession'       => true,

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
          'searchIdCol'         => 'id',
          'searchTitle'         => 'Search by Id or CSV of Ids and more',
          'searchFieldsIn'      => {},
          'searchFieldsOut'     => {'id'=>true},
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
          'fontFamily'           => '"Times New Roman", Times, serif',
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
        when 'postgres','oracle'
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
      elsif $_SESSION.key?('CURRENT_GROUPING') && $_SESSION['CURRENT_GROUPING'].key?(list_parms['name'])
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
        @templateFill['<!--FONT-->']                 = @items['fontFamily']
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
              list_search['title']       = @items['searchTitle']
              list_search['id']          = 'list_search_id_' + @items['name']
              list_search['name']        = 'list_search_name_' + @items['name']
              list_search['class']       = 'inputOuter widget-search-outer ' + @items['name'].downcase + '-search'
              list_search['search_ahead']       = {
                  'url'          => searchUrl,
                  'skip_queue'   => false,
                  'target'       => @items['name'],
                  'search_form'  => @items['listSearchForm'],
                  'onkeyup'      => (! @items['searchOnkeyup'].empty?) ? WidgetList::Utils::fill({'<!--URL-->'=>searchUrl, '<!--TARGET-->' => @items['name'], '<!--FUNCTION_ALL-->' => @items['ajaxFunctionAll']}, @items['searchOnkeyup'] + '<!--FUNCTION_ALL-->') : ''
              }

              @headerPieces['searchBar']            = WidgetList::Widgets::widget_input(list_search)
              @templateFill['<!--FILTER_HEADER-->'] = @headerPieces['searchBar']

              if @items['ransackSearch'] != false
                @templateFill['<!--RANSACK-->'] = ActionController::Base.new.render_to_string(:partial => 'widget_list/ransack_fields', :locals => { 'search_object' => @items['ransackSearch'], 'url' => '--JUMP_URL--'})
              end

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
        if ii == @items['fields'].length - 1
          colWidthStyle += '-moz-border-radius-topright:' + get_radius_value() + ';-webkit-border-top-right-radius:' + get_radius_value() + ';border-top-right-radius:' + get_radius_value() + ';'

        end

        if ii == 0
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

          colSort['SQL_HASH'] = @sqlHash

          pieces = {      '<!--COLSORTURL-->'       => WidgetList::Utils::build_url(@items['pageId'],colSort,(!$_REQUEST.key?('BUTTON_VALUE'))),
                          '<!--NAME-->'             => @items['name'],
                          '<!--COLSORTICON->'       => icon,
                          '<!--COL_HEADER_ID-->'    => strip_tags(field).gsub(/\s/,'_'),
                          '<!--INLINE_STYLE-->'     => colWidthStyle,
                          '<!--TITLE_POPUP-->'      => popupTitle,
                          '<!--COL_HEADER_CLASS-->' => colClass,
                          '<!--TITLE-->'            => fieldTitle,
                          '<!--FUNCTION-->'         => @items['ajaxFunction'],
                          '<!--FUNCTION_ALL-->'     => @items['ajaxFunctionAll'],
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
          if ! @items['checkedFlag'].empty?
            if @items['checkedFlag'].key?(column)
              input['checked'] =  !!@results[ @items['checkedFlag'][column].upcase ][row]
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
          return ['html', list.render() ]
        end
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
      columnValue = @results[column.upcase][j]
      btnOut      = []
      strCnt      = 0
      nameId      = ''

      buttons.each { |buttonId,buttonAttribs|
        function     = @items['linkFunction']
        parameters   = ''
        renderButton = true

        page = buttonAttribs['page'].dup
        if buttonAttribs.key?('tags')
          if buttonAttribs['tags'].first[0] == 'all'
            buttonAttribs['tags'] = {}
            @results.keys.each { |tags|
              buttonAttribs['tags'][tags.downcase] = tags.downcase
            }
          end

          buttonAttribs['tags'].each { | tagName , tag |
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
                buttonAttribs.deep_merge!({ 'args' => { tagName => @results[tag.upcase][j] } })
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

      return '<div style="border:0px solid black;text-align:center;white-space:nowrap;margin:auto;width:' + colWidth.to_s + 'px"><div style="margin:auto;display:inline-block">' + btnOut.join('') + '</div></div>'
    end

    # @param [String] column
    def build_column_link(column,j)

      links      = @items['links'][column]
      url        = {'PAGE_ID' => @items['pageId']}
      function   = @items['linkFunction']
      parameters = ''

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
          @totalRowCount = get_database._select(sql , @items['bindVars'], @items['bindVarsLegacy'], @active_record_model)
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
              colPieces['<!--ALIGN-->']   = @items['collAlign']
              colPieces['<!--STYLE-->']   = theStyle  + colWidthStyle

              if @items['borderedColumns']
                colPieces['<!--STYLE-->'] += 'border-right: ' + @items['borderColumnStyle'] + ';'
              end

              if @items['borderedRows']
                colPieces['<!--STYLE-->'] += 'border-top: ' + @items['borderRowStyle'] + ';'
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

      if !$_REQUEST.key?('BUTTON_VALUE') && $_SESSION.key?('LIST_SEQUENCE') && $_SESSION['LIST_SEQUENCE'].key?(@sqlHash) &&  $_SESSION['LIST_SEQUENCE'][@sqlHash] > 0
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
          pieces['<!--ORDERBY-->'] += tick_field() + strip_aliases(@items['LIST_COL_SORT']) + tick_field() + " " + @items['LIST_COL_SORT_ORDER']
        else
          $_SESSION['LIST_COL_SORT'][@sqlHash].each_with_index { |order,void|
            if @items['fields'].key?(order[0])
              foundColumn = true
              pieces['<!--ORDERBY-->'] += tick_field() + strip_aliases(order[0]) + tick_field() +  " " + order[1]
            end
          } if $_SESSION.key?('LIST_COL_SORT') && $_SESSION['LIST_COL_SORT'].class.name == 'Hash' && $_SESSION['LIST_COL_SORT'].key?(@sqlHash)
        end

        # Add base order by
        if ! @items['orderBy'].empty?
          pieces['<!--ORDERBY-->'] += ',' if foundColumn == true
          pieces['<!--ORDERBY-->'] += @items['orderBy']
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

      statement
    end

    def strip_aliases(name='')
      name = (name.include?(' ') ? name.split(' ').last : name)
      ((name.include?('.')) ? name.split('.').last.gsub(/'||"/,'') : name.gsub(/'||"/,''))
    end

    def auto_column_name(name='')
      name.gsub(/\_/,' ').gsub(/\-/,' ').capitalize
    end

    def get_total_records()

      filter = ''
      fields = {}
      sql    = ''
      hashed = false

      if !get_view().empty?
        sql = WidgetList::Utils::fill({'<!--VIEW-->' => get_view(),'<!--GROUPBY-->' => !@items['groupBy'].empty? ? ' GROUP BY ' + @items['groupBy'] : '' }, @items['statement']['count']['view'])
      end

      if ! @filter.empty?
        filter = ' WHERE ' + @filter
      end

      sql = WidgetList::Utils::fill({'<!--WHERE-->' => filter}, sql)

      if ! sql.empty?
        if @items['showPagination']
          if get_database._select(sql, @items['bindVars'], @items['bindVarsLegacy'], @active_record_model) > 0
            rows = get_database.final_results['TOTAL'][0].to_i
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
        rescue
          return ''
        end

      end
    end

    def self.load_widget_list_yml
      if $widget_list_conf.nil?
        $widget_list_conf = YAML.load(ERB.new(File.new(Rails.root.join("config", "widget-list.yml")).read).result)[Rails.env]
      end
    end

    def self.load_widget_list_database_yml
      if $widget_list_db_conf.nil?
        $widget_list_db_conf = YAML.load(ERB.new(File.new(Rails.root.join("config", "database.yml")).read).result)
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
      @active_record_model = false
      if (@is_primary_sequel && @items['database'] == 'primary') ||  (@is_secondary_sequel && @items['database'] == 'secondary')
        return @items['view']
      elsif @items['view'].respond_to?('scoped') && @items['view'].scoped.respond_to?('to_sql')
        @active_record_model = @items['view'].name.constantize

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

        view     = @items['view'].scoped.to_sql
        sql_from = view[view.index(/FROM/),view.length]
        view     = "SELECT #{new_columns.join(',')} " + sql_from
        where    = ''
        if !@items['groupBy'].empty?
          where    = '<!--WHERE-->'
        end

        return "( #{view} #{where} <!--GROUPBY--> ) a"
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