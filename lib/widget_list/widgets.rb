module WidgetList
  class Widgets

    #todo - WidgetRadio, WidgetData?

    # WidgetCheck
    def self.widget_check(list={})

      items = {      'name'         => '',
                     'id'           => '',
                     'value'        => '',
                     'width'        => '',
                     'disabled'     => false,
                     'hidden'       => false,
                     'required'     => false,
                     'checked'      => false,
                     'max_length'   => '',
                     'title'        => '',
                     'class'        => '',
                     'style'        => '',
                     'onclick'      => '',
                     'input_style'  => '',
                     'input_class'  => '',
                     'template'     => '',
      }

      items['template_required'] = $G_TEMPLATE['widget']['required']

      items['template']          = $G_TEMPLATE['widget']['checkbox']['default']

      items = populate_items(list,items)

      if !items['required']
        items['template_required'] = ''
      end

      if items['checked'] == true
        items['checked'] = 'checked'
      end

      if !items['class'].empty?
        items['input_class'] = items['class']
      end

      if items['disabled']
        items['disabled']     = 'disabled'
      else        
        items['disabled']     = ''
      end

      if items['hidden'] == true
        items['style'] += ' display:none'
      end

      pieces = {
        '<!--INPUT_CLASS-->' => items['input_class'],
        '<!--INPUT_STYLE-->' => items['input_style'],
        '<!--ID-->'          => items['id'],
        '<!--NAME-->'        => items['name'],
        '<!--TITLE-->'       => items['title'],
        '<!--ONCLICK-->'     => items['onclick'],
        '<!--VALUE-->'       => items['value'],
        '<!--REQUIRED-->'    => items['template_required'],
        '<!--CHECKED-->'     => items['checked'],
        '<!--VALUE-->'       => items['value'],
        '<!--DISABLED-->'    => items['disabled']
      }

      return WidgetList::Utils::fill(pieces, items['template'])
    end

    # WidgetSelect - todo - never tested one line of code in here!!!
    def self.widget_select(sql = '', list={})
      valid = true
      selectOutput = []

      #Parameter evaluation identification
      #
      if list.empty? && sql.class.name == 'Hash'
        list = sql
      end

      if ! sql.empty? && ! list.key?('sql') && ! list.key?('view')
        list['sql'] = sql
      end

      #
      # Default configurations
      #
      items = {}

      items['name']              = ''
      items['id']                = ''
      items['multiple']          = false
      items['insertUnknown']     = false
      items['required']          = ''
      items['strLenBrk']         = 50
      items['optGroupIndicator'] = ''
      items['label']             = ''
      items['selectTxt']         = 'Select One'
      items['showId']            = false
      items['showIdLeft']        = false
      items['passive']           = false
      items['freeflow']          = false
      items['no_style']          = false

      #
      # Select box attributes
      #
      items['attribs']   = {}
      items['size']      = 1
      items['disabled']  = false
      items['noDataMsg'] = 'No Data'
      items['selectOne'] = 0
      items['selected']  = {}

      #
      # SQL
      #
      items['bindVars'] = {}
      items['view']     = ''
      items['sql']      = ''
      items['orderBy']  = ''
      items['filter']   = ''

      #
      # Actions
      #
      items['onchange'] = ''
      items['onclick']  = ''

      #
      # Style
      #
      items['style']       = ''             #meant for internal use as nothing is appended only replaced.
      items['inner_class'] = 'select-inner' #Left long piece of image
      items['outer_class'] = 'select-outer' #Right corner of image
      items['outer_style'] = ''             #Basically the width of the select box ends up here
      items['extra_class'] = ''             #Not used currently
      items['width']       = 184            #width of the select-outer element

      #
      # @deprecated
      #
      items['class'] = ''


      #
      # Setup templates
      #
      if items['freeflow']
        #
        # Freeflow
        #
        items['template']['wrapper'] = $G_TEMPLATE['widget']['selectfree']['wrapper']
        items['template']['option']  = $G_TEMPLATE['widget']['selectfree']['option']
        items['template']['initial'] = ''
        items['template']['passive'] = ''
      else
        #
        # Standard
        #
        items['template']['wrapper'] = $G_TEMPLATE['widget']['selectbox']['wrapper']
        items['template']['option']  = $G_TEMPLATE['widget']['selectbox']['option']
        items['template']['initial'] = $G_TEMPLATE['widget']['selectbox']['initial']
        items['template']['passive'] = $G_TEMPLATE['widget']['selectbox']['passive']
      end

      # if numeric or string passed, convert to array
      if list.key?('selected') && list['selected'].class.name != 'Array'
        list['selected'] = [ list['selected'] ]
      end

      #
      # Merge settings
      #
      items = populate_items(list,items)

      if items['no_style']
        items['template']['wrapper'] = $G_TEMPLATE['widget']['selectbox_nostyle']['wrapper']
      end


      #
      # If multiple then override above settings and classes
      #
      if items['multiple']
        items['outer_style'] = ';width:280px;'
        items['width'] = 280

        items['inner_class'] = 'select-inner-multiple'
        items['outer_class'] = 'select-outer-multiple'
      end

      if items['showId']
        items['template']['option'] = $G_TEMPLATE['widget']['selectbox']['option_showid']
      end

      if items['showIdLeft']
        items['template']['option'] = $G_TEMPLATE['widget']['selectbox']['option_showid_left']
      end

      if items['disabled']
        items['disabled']  = 'disabled="disabled"'
        items['class']    += ' disabled'
      end

      if items['multiple']
        items['multiple'] = 'multiple="multiple"'
      end

      if items['required']
        items['required'] = $G_TEMPLATE['widget']['required']
      end

      if ! items['sql'].empty?
        sql   = items['sql']
      elsif !items['view'].empty?
        sql   = "SELECT id, value FROM " + items['view']
      else
        valid = false
      end

      if ! items['filter'].empty?
        sql += ' WHERE ' + items['filter'].join(' AND ')
      end

      if ! items['orderBy'].empty?
        sql += ' ORDER BY ' + items['orderBy']
      end

      rows = WidgetList::List.get_database._select(sql, [],  items['bindVars'])
      selectRows = WidgetList::List.get_database.final_results


      if rows > 0 && valid
        if ! items['passive']
          addedGroup   = false
          groupByRow   = false
          groupByValue = -1
          if selectRows.key?('GROUPING_VAL')
            groupByRow = true
          end

          max      = rows-1

          selected = ''

          if (items['selectOne'] > 0 || (items['selectOne'].class.name == 'Array' && ! items['selectOne'].empty?) && ! items['freeflow'])
            theVal = ''
            theClk = ''
            theSel = ''
            theTxt = items['selectTxt']

            if items['selectOne'].class.name == 'Array'
              if(items['selectOne'].key?('text'))
                theTxt = items['selectOne']['text']
              end

              if(items['selectOne'].key?('value'))
                theVal = items['selectOne']['value']
              end
            end

            pieces = { '<!--VALUE-->' => theVal,
                       '<!--ONCLICK-->' => theClk,
                       '<!--SELECTED-->' => theSel,
                       '<!--CONTENT-->' => theTxt
            }


            selectOutput << WidgetList::Utils::fill(pieces, items['template']['initial'])
          end

          hasASelectedMatch = false
          startedGrouping   = false
          i    = 0
          for i in j..max
            if items['selected'].class.name == 'Array' && items['selected'].count > 0
              if items['selected'].include?(selectRows['ID'][i]) || items['selected'].include?(selectRows['VALUE'][i])
                hasASelectedMatch = true
                selected = ' selected'
              end
            end

            if selectRows['VALUE'][i].length > items['strLenBrk']
              first = CGI.escapeHTML(selectRows['VALUE'][i].to_s[0,10])
              last  = CGI.escapeHTML(selectRows['VALUE'][i].to_s[-40])
              content = first + '...' + last
            else
              content = CGI.escapeHTML(selectRows['VALUE'][i])
            end

            pieces = {
              '<!--VALUE-->'    => selectRows['ID'][i],
              '<!--ONCLICK-->'  => items['onclick'],
              '<!--SELECTED-->' => selected,
              '<!--CONTENT-->'  => content,
              '<!--COUNTER-->'  => i,
              '<!--NAME-->'     => items['name'],
            }


            if groupByRow
              if  selectRows['GROUPING_VAL'][i] != groupByValue
                if (addedGroup)
                  selectOutput << '</optgroup>'
                end

                addedGroup = true
                # Start new optgroup
                groupByValue = selectRows['GROUPING_VAL'][i]

                selectOutput << '<optgroup label="' + groupByValue + '">'
                selectOutput << WidgetList::Utils::fill(pieces, items['template']['option'])
              else
                selectOutput << WidgetList::Utils::fill(pieces, items['template']['option'])
              end
            else
              if selectRows['ID'][i] === 'GROUPING'
                # Output OPTGROUP tags and labels no one can select this
                if startedGrouping
                  selectOutput << '</optgroup>'
                end
                selectOutput   << '<optgroup label="' + selectRows['VALUE'][i] + '">'
                startedGrouping = true
              else
                # Output regular option tag
                selectOutput << WidgetList::Utils::fill(pieces, items['template']['option'])
              end
            end

            selected = ''
          end

          if (groupByRow && addedGroup)
            selectOutput << '</optgroup>'
          end

          if hasASelectedMatch === false && items['insertUnknown'] === true
            # in this mode, you wish to inject an option into the select box even though the results didnt find the match


            items['selected'].each{ |vals|
              pieces = {
                '<!--VALUE-->'    => vals,
                '<!--ONCLICK-->'  => items['onclick'],
                '<!--SELECTED-->' => ' selected ',
                '<!--CONTENT-->'  => vals
              }
              selectOutput << WidgetList::Utils::fill(pieces, items['template']['option'])
            }
          end
        end
      else
        pieces = {
          '<!--VALUE-->'    => '',
          '<!--ONCLICK-->'  => items['onclick'],
          '<!--SELECTED-->' => '',
          '<!--CONTENT-->'  => items['noDataMsg']
        }

        selectOutput << WidgetList::Utils::fill(pieces, items['template']['initial'])
      end

      if items['id'].empty? && ! items['name'].empty?
        items['id'] = items['name']
      end


      pieces =     { '<!--SIZE-->'         => items['size'],
                     '<!--ID-->'           => items['id'],
                     '<!--NAME-->'         => items['name'],
                     '<!--MULTIPLE-->'     => items['multiple'],
                     '<!--OPTIONS-->'      => selectOutput.join(''),
                     '<!--ONCHANGE-->'     => items['onchange'],
                     '<!--REQUIRED-->'     => items['required'],
                     '<!--CLASS-->'        => items['class'],
                     '<!--DISABLED_FLG-->' => items['disabled'],
                     '<!--STYLE-->'        => items['style'],
                     '<!--ATTRIBUTES-->'   => items['attribs'].join(' '),
                     '<!--INNER_CLASS-->'  => items['inner_class'],
                     '<!--OUTER_CLASS-->'  => items['outer_class'],
                     '<!--OUTER_STYLE-->'  => items['outer_style'],
                     '<!--INNER_STYLE-->'  => '',
                     '<!--OUTER_ACTION-->' => ''
      }

      finalTemplate = items['template']['wrapper']

      if items['passive'] && items['selected'].class.name == 'Array' && items['selected'].count > 0
        #passKeys                    = array_keys(selectRows['ID'], items['selected'][0])
        #pieces['<!--OPTIONS-->']    = selectRows['VALUE'][passKeys[0]]
        finalTemplate               = items['template']['passive']
      end

      WidgetList::Utils::fill(pieces, finalTemplate)
    end

    # WidgetInput
    def self.widget_input(list={})
      items = {
        'name'         => '',
        'id'           => '',
        'outer_id'     => '',
        'value'        => '',
        'input_type'   => 'text', #hidden
        'width'        => '150',
        'readonly'     => false,
        'disabled'     => false,
        'hidden'       => false,
        'required'     => false,
        'list-search'  => false,
        'max_length'   => '',
        'events'       => {},
        'title'        => '',
        'add_class'    => '',
        'class'        => 'inputOuter',
        'inner_class'  => 'inputInner',
        'outer_onclick'=> '',
        'style'        => '',
        'inner_style'  => '',
        'input_style'  => '',
        'input_class'  => '',
        'template'     => '',
        'search_ahead' => {},
        'search_form'  => '',
        'search_handle'=> '',
        'arrow_extra_class'=> '',
        'icon_extra_class'=> '',
        'arrow_action' => ''
      }

      items['template_required'] = $G_TEMPLATE['widget']['required']

      items['template'] = $G_TEMPLATE['widget']['input']['default']

      items = populate_items(list,items)

      iconAction   = ''
      outerAction  = ''
      onkeyup      = ''

      if ! items['outer_onclick'].empty?
        outerAction = items['outer_onclick']
      end

      if ! items['search_ahead'].empty?
        # Search Ahead Input
        #
        items['template'] = $G_TEMPLATE['widget']['input']['search']

        fill = {}
        if items['list-search']
          fill['<!--MAGNIFIER-->'] = '<div class="widget-search-magnifier <!--ICON_EXTRA_CLASS-->" style="" onclick="<!--ICON_ACTION-->"></div>'
        end

        items['template'] = WidgetList::Utils::fill(fill,items['template'])

        if ! items['search_ahead']['search_form'].empty?
          if(items['arrow_action'].empty?)
            items['arrow_action'] = "ToggleAdvancedSearch(this)"
          end
        end

        #####

        if items['search_ahead'].key?('icon_action')
          iconAction = items['search_ahead']['icon_action']
        end

        if items.key?('events') && items['events'].key?('onkeyup')
          keyUp = items['events']['onkeyup'] + ';'
        else
          keyUp = ''
        end

        if items['search_ahead'].key?('onkeyup') && !items['search_ahead']['onkeyup'].empty?
          items['events']['onkeyup']   = keyUp + items['search_ahead']['onkeyup']
        else
          if items['list-search']
            items['events']['onkeyup'] = keyUp + "SearchWidgetList('#{items['search_ahead']['url']}', '#{items['search_ahead']['target']}', this);"
          elsif items['search_ahead'].key?('skip_queue') && items['search_ahead']['skip_queue']
            items['events']['onkeyup'] = keyUp +  "WidgetInputSearchAhead('#{items['search_ahead']['url']}', '#{items['search_ahead']['target']}', this);"
          else
            items['events']['onkeyup'] = keyUp + "WidgetInputSearchAheadQueue('#{items['search_ahead']['url']}', '#{items['search_ahead']['target']}', this);"
          end
        end

        if !items['events']['onkeyup'].empty?
          iconAction = items['events']['onkeyup']
        end

        if items['search_ahead'].key?('onclick')
          items['events']['onclick'] = items['search_ahead']['onclick']
        end

        items['input_class'] += ' search-ahead'

        # Modify the width a bit to compensate for the search icon
        #
        items['width'] = items['width'].to_i - 30

        # Build advanced searching
        #
        if ! items['search_ahead']['search_form'].empty?
          if items['list-search']
            items['arrow_extra_class'] += ' widget-search-arrow-advanced'
          else
            items['arrow_extra_class'] += ' widget-search-arrow-advanced-no-search'
          end

          items['icon_extra_class']   += ' widget-search-magnifier-advanced'
          items['input_class']        += ' search-ahead-advanced'
        end

      end

      #
      #  Mandatory For outer boundary and IE7
      #
      #  @todo should be css MW 5/2012
      #
      items['style'] += "width:#{items['width']}px"

      if !items['required']
        items['template_required'] = ''
      end

      if items['disabled']
        items['input_class'] += ' disabled'
      end

      if !items['add_class'].empty?
        items['class'] += ' ' + items['add_class']
      end

      if items['hidden']
        items['style'] += ' display:none'
      end

      if !items['events'].empty? && items['events'].is_a?(Hash)
        items['event_attributes'] = ''
        items['events'].each { |event,action|
          items['event_attributes'] += ' ' + event + '="' + action + '"' + ' '
        }
      end

      if ! items['search_ahead'].key?('search_form')
        items['search_ahead']['search_form'] = ''
      end

      WidgetList::Utils::fill({
                                '<!--READONLY-->'           => (items['readonly']) ? 'readonly' : '',
                                '<!--OUTER_ID-->'           => items['outer_id'],
                                '<!--OUTER_CLASS-->'        => items['class'],
                                '<!--OUTER_STYLE-->'        => items['style'],
                                '<!--INNER_CLASS-->'        => items['inner_class'],
                                '<!--INNER_STYLE-->'        => items['inner_style'],
                                '<!--INPUT_CLASS-->'        => items['input_class'],
                                '<!--INPUT_STYLE-->'        => items['input_style'],
                                '<!--ID-->'                 => items['id'],
                                '<!--NAME-->'               => items['name'],
                                '<!--TITLE-->'              => items['title'],
                                '<!--MAX_LENGTH-->'         => items['max_length'],
                                '<!--ONKEYUP-->'            => onkeyup,
                                '<!--SEARCH_FORM-->'        => items['search_ahead']['search_form'],
                                '<!--VALUE-->'              => items['value'],
                                '<!--REQUIRED-->'           => items['template_required'],
                                '<!--ICON_ACTION-->'        => iconAction,
                                '<!--OUTER_ACTION-->'       => outerAction,
                                '<!--EVENT_ATTRIBUTES-->'   => items['event_attributes'],
                                '<!--INPUT_TYPE-->'         => items['input_type'],
                                '<!--ARROW_EXTRA_CLASS-->'  => items['arrow_extra_class'],
                                '<!--ARROW_ACTION-->'       => items['arrow_action'],
                                '<!--ICON_EXTRA_CLASS-->'   => items['icon_extra_class']
                              } ,
                              items['template']
      )

    end

    def self.populate_items(list,items)
      unless list.nil?
        list.each { |k,v|
          if list.key?(k)
            items[k] = v
          end
        }
      end
      items
    end

    def self.validate_items(list,items)
      valid = true
      unless items.empty?
        items.each { |k,v|
          if !list.to_s.empty? && !list.key?(k)
            valid = false
            throw "Required item '#{k.to_s}' only passed in #{items.inspect}"
          end
        }
      end

      if list.to_s.empty? && !items.empty?
        valid = false
        throw "Required items are needing to be passed #{items.inspect} are all required for this function"
      end
      return valid
    end

    # WidgetButton
    def self.widget_button(text='', list={}, small=false)
      items = {
        'label'      => text,
        'name'       => '',
        'id'         => '',
        'url'        => '',
        'link'       => '',        #alias of url
        'href'       => '',        #alias of url
        'page'       => '',
        'parameters' => false,
        'style'      => 'display:inline-block',
        'frmSubmit'  => '',        #this option adds hidden frmbutton
        'submit'     => '',
        'args'       => {},
        'class'      => 'btn',     #Always stays the same
        'innerClass' => 'info',    #.primary(blue) .info(light-blue) .success(green) .danger(red) .disabled(light grey) .default(grey)
        'passive'    => false,
        'function'   => 'ButtonLinkPost',
        'onclick'    => '',
        'template'   => ''
      }

      items = populate_items(list,items)

      if items.key?('submit') && !items['submit'].empty?
        items['onclick'] = "ButtonFormPost('#{list['submit']}');"
      end

      if items['template'].empty?
        theClass = ''
        if small
          theClass = items['class'] + " small " + items['innerClass']
        elsif ! items['class'].empty?
          theClass = items['class'] + " " + items['innerClass']
        end
        items['template'] = $G_TEMPLATE['widget']['button']['default']
      else
        theClass = items['class']
      end

      if items['url'].empty? && !items['page'].empty?
        items['url'] = WidgetList::Utils::build_url(items['page'], items['args'])
      end

      if !items['href'].empty? && items['onclick'].empty?
        items['onclick'] = items['function'] + "('#{items['href']}')"
      end

      if !items['url'].empty? && items['onclick'].empty?
        items['onclick'] = items['function'] + "('#{items['url']}')"
      end

      if !items['link'].empty? && items['onclick'].empty?
        items['onclick'] = items['function'] + "('#{items['link']}')"
      end

      if items['parameters'] && !items['args'].empty? && items['args'].is_a?(Hash)
        parameters = []
        items['args'].each {|k,parameter|
          if (parameter == 'this' || (parameter =~ /function/) && parameter =~ /\{/ &&  parameter =~ /\}/)
            parameters << parameter.to_s
          else
            tmp = "'" + parameter.to_s + "'"
            parameters << tmp
          end
        }
        items['onclick'] = items['function']  +  "(" +  parameters.join(',') + ")"
      end

      if !items['frmSubmit'].empty?
        items['frmSubmit'] = "<input type=\"submit\" value=\"\" style=\"position: absolute; float: left; z-index: -1;\"/> "
      end

      WidgetList::Utils::fill({
                                '<!--BUTTON_CLASS-->'       => theClass,
                                '<!--BUTTON_ONCLICK-->'     => items['onclick'].gsub(/\"/,"'"),
                                '<!--BUTTON_LABEL-->'       => items['label'],
                                '<!--NAME-->'               => items['name'],
                                '<!--ID-->'                 => items['id'],
                                '<!--BUTTON_STYLE-->'       => items['style'],
                                '<!--BUTTON_CLASS_INNER-->' => items['innerClass'],
                                '<!--FRM_SUBMIT-->'         => items['frmSubmit'],
                              },
                              items['template']
      )
    end

    def self.test_all
      output_final  = ''
      output_final += "error1"  if $G_TEMPLATE['widget']['input']['search'].nil?
      output_final += "error2"  if $G_TEMPLATE['widget']['input']['default'].nil?
      output_final += "error3"  if $G_TEMPLATE['widget']['radio']['default'].nil?
      output_final += "error4"  if $G_TEMPLATE['widget']['checkbox']['default'].nil?
      output_final += "error5"  if $G_TEMPLATE['widget']['selectbox_nostyle']['wrapper'].nil?
      output_final += "error6"  if $G_TEMPLATE['widget']['selectbox']['wrapper'].nil?
      output_final += "error7"  if $G_TEMPLATE['widget']['selectbox']['option'].nil?
      output_final += "error8"  if $G_TEMPLATE['widget']['selectbox']['option'].nil?
      output_final += "error9"  if $G_TEMPLATE['widget']['selectbox']['option_showid'].nil?
      output_final += "error10"  if $G_TEMPLATE['widget']['selectbox']['option_showid_left'].nil?
      output_final += "error11"  if $G_TEMPLATE['widget']['selectbox']['initial'].nil?
      output_final += "error12"  if $G_TEMPLATE['widget']['selectbox']['passive'].nil?
      output_final += "error13"  if $G_TEMPLATE['widget']['selectfreeflow']['wrapper'].nil?
      output_final += "error14"  if $G_TEMPLATE['widget']['button']['default'].nil?
      output_final += "error15"  if $G_TEMPLATE['widget']['container']['row'].nil?
      output_final += "error16"  if $G_TEMPLATE['widget']['container']['col']['pre_text'].nil?
      output_final += "error17"  if $G_TEMPLATE['widget']['container']['col']['standard'].nil?
      output_final += "error18"  if $G_TEMPLATE['widget']['container']['wrapper'].nil?

      #test submit
      output_final += WidgetList::Widgets::widget_button('asfdsaf', {'id'=>'asdfasdf','submit'=>'213131'}) + "<br/><br/>"

      #test arguments
      output_final += WidgetList::Widgets::widget_button('asfdsaf', {'parameters'=>true,'args'=>{'dave'=>'123','dan'=>'1234'}}) + "<br/><br/>"

      #test arguments with JS func
      output_final += WidgetList::Widgets::widget_button('asfdsaf', {'parameters'=>true,'args'=> {'dave'=>'function() {  alert(0); } '} } ) + "<br/><br/>"

      output_final += WidgetList::Widgets::widget_button('asfdsaf', {'name'=>'asdfasf', 'id'=>'asfdasdf', 'parameters'=>true,'args'=> {'dave'=>'function() {  alert(0); } '} }, true) + "<br/><br/>"

      input = {}
      input['list-search'] = true
      input['width']       = '300'
      input['input_class'] = 'info-input'
      input['title']       = 'test search'
      input['id']          = 'list_search_id_'
      input['name']        = 'list_search_name_'
      input['value']        = 'asfdasd'
      input['class']       = 'inputOuter widget-search-outer -search'
      input['search_ahead']       = {
        'url'          => 'http://google.com',
        'skip_queue'   => false,
        'target'       => 'test',
        'search_form'  => '',
        'onclick'      => ''
      }
      output_final += WidgetList::Widgets::widget_input(input) + "<br/><br/>"

      output_final
    end
  end
end