
var debugFlag = 0;
var debugContainer = '';


/**
* ListSearchAheadResponse()
*/
var ListSearchAheadGlobalElement = '';
var ListSearchAheadQueueElement = '';
var ListSearchAheadInProgress = false;
var ListSearchAheadInProgressUrl;
var ListSearchAheadInProgressTarget;
var ListSearchAheadInProgressObj;



var AjaxMaintainChecksRunning = false;


function SearchWidgetList(url, listId, element)
{
   var inputField = jQuery(element).closest('div.inputOuter').find('input.search-ahead');

   if(inputField.length)
   {
      ListSearchAheadQueue(url, listId, inputField);
   }
}

//simple version
function RefreshList(list_id, callback)
{
   ListJumpMin(jQuery('#' + list_id + '_jump_url').val(), list_id, callback);
}

/**
 * Debug()
 *
 * @param string what
 * @return void
 */
function Debug(what)
{
   if(debugFlag >= 1)
   {
      if(window.document.getElementById(debugContainer))
      {
         var time = new Date();

         element = window.document.getElementById(debugContainer);

         element.innerHTML += '<br/><span>' + time.getHours() + ':' + time.getMinutes() + ':' + time.getSeconds() + '</span>  ' + what;
         element.scrollTop  = element.scrollHeight;
      }
   }
}

/**
 * Redirect()
 *
 * @param string inUrl
 * @return void
 */
function Redirect(inUrl)
{
   if(typeof(inUrl) == 'string')
   {
      if(inUrl.length > 0)
      {
         window.location = inUrl;
      }
      else
      {
         throw('Missing URL input for Redirect()');
      }
   }
   else
   {
      throw('Invalid URL type input for Redirect()');
   }
}

function ButtonFormPost(theForm)
{
   try
   {
      if (typeof(theForm) == "object")
      {
         theForm.submit();
      }
      else
      {
         if (document.getElementById(theForm) && typeof(theForm) !="undefined" && typeof(theForm) != 'null') {
            document.getElementById(theForm).submit();
         } else {
            throw new Exception();
         }
      }
   }
   catch(e)
   {
      // -- id might not be there, so try the form by name
      try
      {
         eval('document.' + theForm + '.submit()');
      }
      catch(e)
      {
         if (document.forms.length == 1)
         {
            document.forms[0].submit();
         }
         else
         {
            return false;
         }
      }
   }
}


function ButtonLinkPost(inUrl)
{
   try
   {
      Redirect(inUrl);
   }
   catch(e)
   {
      if(debugFlag)
      {
         Debug(e);
      }
   }
}

function ajaxStatus(eToHide, fadeInOut)
{

   if(document.getElementById(eToHide))
   {
      elmToHide  = document.getElementById(eToHide);

      eHider = "loading" + eToHide;

      if(document.getElementById(eHider))
      {
         elmHider = document.getElementById(eHider);
      }
      else
      {
         var overLay = '<div style="position:relative;top:0px;"><div class="ajaxLoad" id="' + eHider + '" style="height:' + jQuery(elmToHide).height() + 'px;width:' + jQuery(elmToHide).width() + 'px;top:-' + jQuery(elmToHide).height() + 'px;"></div></div>';

         jQuery(elmToHide).append(overLay);

         elmHider = document.getElementById(eHider);
      }

      if(typeof(fadeInOut) == 'number')
      {
         if(fadeInOut > 0)
         {
            fadeInOut = 1;
            jQuery(elmHider).fadeTo("fast", .20);
         }
         else
         {
            fadeInOut = 0;
            jQuery(elmHider).remove();
         }
      }
   }
}


function ListChangeGrouping(listId, obj, extra)
{
   if (typeof(extra) == 'undefined')
   {
      var extra = '';
   }
   ajaxStatus(listId, 1);
   HideAdvancedSearch(jQuery('#' + listId + '-group'));
   jQuery('#list_search_id_' + listId ).val('');
   InitInfoFields(jQuery('#list_search_id_' + listId));
   ListJumpMin(jQuery('#' + listId + '_jump_url').val() + '&searchClear=1&switch_grouping=' + jQuery('#list_group_id_' + listId ).val() + '&group_row_id=' + jQuery(obj).attr('id') + extra , listId);
}

function ListHome(listId)
{
   ListJumpMin(jQuery('#' + listId + '_jump_url_original').val() + '&searchClear=1', listId, function(){
       InitInfoFields(jQuery('#list_search_id_' + listId));
   });
}

function ListDrillDown(mode, data, listId, extra)
{
   jQuery('#list_search_id_' + listId).val('');
   var grouping = '';
   if (jQuery('#list_group_id_' + listId))
   {
      grouping = '&switch_grouping=' + jQuery('#list_group_id_' + listId).val();
   }
   ListJumpMin(jQuery('#' + listId + '_jump_url').val() + '&drill_down=' + mode + '&filter=' + data + grouping + '&search_filter=' + extra, listId, function(){
      InitInfoFields(jQuery('#list_search_id_' + listId));
   });
}

function ListDrillDownGetRowValue(obj)
{
   return (typeof(jQuery(obj).next(".val-db").html()) != 'undefined') ? jQuery(obj).next(".val-db").html() : '';
}

function ListExport(listId)
{
   document.location = jQuery('#' + listId + '_jump_url').val() + '&export_widget_list=1';
}


/**
* ListJumpResponse()
*/
function ListJumpResponse(response)
{
   //ajaxStatus("loading" + response['list_id'], 0);
   jQuery(document.getElementById(response['list_id'])).after(response['list']).remove();

   if(typeof response['callback'] === 'string')
   {
      eval(response['callback'] + '()');
   }

   if(typeof response['search_bar'] === 'string')
   {
      jQuery('.' + response['list_id'] + '-search').replaceWith(response['search_bar']);
      InitInfoFields(jQuery('#list_search_id_' + response['list_id']));
   }

   if(typeof response['export_button'] === 'string')
   {
      jQuery('.' + response['list_id'] + '-export').replaceWith(response['export_button']);
   }

   if(typeof response['group_by_items'] === 'string')
   {
      jQuery('.' + response['list_id'] + '-group-by').replaceWith(response['group_by_items']);
   }
}

/**
 * ListMessagePopup()
 */
function ListMessagePopup(id, html, hieght, width)
{
    jQuery('.ajaxLoad,.ajaxLoad2').remove();
    if (typeof(hieght) =="undefined")
    {
        var hieght = '200'
    }
    if (typeof(width) =="undefined")
    {
        var width = '400'
    }

    if(document.getElementById(id))
    {
        elmToHide  = document.getElementById(id);
        var overLay = '<div style="position:relative;top:0px;"><div id="loading' + id + '" class="ajaxLoad" style="height:' + jQuery(elmToHide).height() + 'px;width:' + jQuery(elmToHide).width() + 'px;top:-' + jQuery(elmToHide).height() + 'px;"></div></div><div class="ajaxLoad2" id="message' + id + '" style="height:' + hieght + 'px;width:' + width + 'px;left:100px;top:200px;left:250px;z-index: 1000;background-position: 50% 50%;position: absolute;display: block;border:2px solid #dadada;box-shadow:0 2px 4px #c0c0c0;text-align:center;background-color:#FFFFFF;padding:15px;">' + html + '</div>';

        jQuery(elmToHide).append(overLay);

        jQuery('#message' + id).children( ).each( function( index )
        {
            jQuery( this ).addClass( 'tmp-popup-class' );
        });

        jQuery('#loading' + id).fadeTo("fast", .20);

        jQuery('html,body').animate({scrollTop: jQuery('#message' + id).offset().top - 100 }, 400);
    }

    jQuery("body").unbind('click');

    setTimeout(function() {
        jQuery("body").click
            (
                function(e)
                {
                    if(e.target.id == 'message' + id || e.target.className == 'tmp-popup-class')
                    {
                        return false;
                    }
                    if (jQuery('#' + e.target.id).parents('#message' + id).length == 0 || (e.target.id != 'message' + id && jQuery('#' + e.target.id).parents('#message' + id).length != 1))
                    {
                        jQuery('#message' + id + ', #loading'+ id).remove();
                    }
                }
            );
    }, 1000);
}

/**
 * ListMessageClose()
 */
function ListMessageClose()
{
    jQuery('.ajaxLoad,.ajaxLoad2').remove();
}


/**
* ListJumpMin()
*/
function ListJumpMin(url, id, callback, post)
{
   if(document.getElementById(id))
   {
      ajaxStatus(id, 1);
   }

   if(document.getElementById(id))
   {
      try
      {
         jQuery.post(url, post, function(response)
         {
           ListJumpResponse(response);
           if (typeof(callback) == 'string')
           {
              eval(callback);
           }
           else if (typeof(callback) == 'function')
           {
              (callback)();
           }
         }, "json");
      }
      catch(e)
      {
         console.log(e);
      }
   }
}

function ListSearchAheadResponse()
{
   if(ListSearchAheadInProgress)
   {
      ListSearchAheadInProgress = false;

      if(ListSearchAheadQueueElement != '')
      {
         (ListSearchAheadQueueElement)(ListSearchAheadInProgressUrl,ListSearchAheadInProgressTarget,ListSearchAheadInProgressObj);

         ListSearchAheadQueueElement = '';
      }
   }
}

/**
* ListSearchAhead()
*/
function ListSearchAhead(url, id, element)
{
   if(! ListSearchAheadInProgress && jQuery(element).length && typeof(jQuery(element).val()) != 'undefined' && jQuery(element).val() != jQuery(element).attr('title'))
   {
      ListSearchAheadInProgress = true;
      ListJumpMin(url+ '&search_filter=' + jQuery(element).val(), id);
   }
}

/**
* ListSearchAheadQueue()
*/
function ListSearchAheadQueue(url, id, element)
{
   if(! ListSearchAheadInProgress)
   {
      ListSearchAheadGlobalElement = element;

      setTimeout("ListSearchAhead('"+url+"', '"+id+"', ListSearchAheadGlobalElement)", 500);
   }
   else
   {
      ListSearchAheadInProgressUrl = url;
      ListSearchAheadInProgressTarget = id;
      ListSearchAheadInProgressObj = element;

      ListSearchAheadQueueElement = ListSearchAhead;
   }
}

var WidgetSearchAheadQueuedRawDog = '';
var WidgetSearchAheadInProgress = false;
var WidgetSearchAheadInProgressUrl;
var WidgetSearchAheadInProgressTarget;
var WidgetSearchAheadInProgressObj;

/**
* WidgetSearchAheadResponse()
*
* @note searchTarget is the
*
* @todo session/token based WidgetSearchAheadQueuedRawDog?
*/
function WidgetSearchAheadResponse(response)
{
   if(WidgetSearchAheadInProgress)
   {
      WidgetSearchAheadInProgress = false;

      if(WidgetSearchAheadQueuedRawDog != '')
      {
         (WidgetSearchAheadQueuedRawDog)(WidgetSearchAheadInProgressUrl,WidgetSearchAheadInProgressTarget,WidgetSearchAheadInProgressObj);

         WidgetSearchAheadQueuedRawDog = '';
      }
   }

   var searchResults = '';
   var searchTarget = '';

   //Capture the results
   //
   if(response && typeof(response['content']) != 'undefined' && response['content'] != '')
   {
      searchResults = response['content'];
   }

   if(response && typeof(response['target']) != 'undefined' && response['target'] != '')
   {
      var result = response['target'] + '_results';
      var searchTarget = document.getElementById(result);
   }

   jQuery('.widget-search-content', searchTarget).html(searchResults);

   if(searchResults != '')
   {
      if(! jQuery(searchTarget).is(':visible'));
      {
         jQuery(searchTarget).slideDown();
      }
   }
   else
   {
      if(jQuery(searchTarget).is(':visible'));
      {
         jQuery(searchTarget).slideUp();
      }
   }
}

/**
 * ListSearchAhead()
 */
function WidgetInputSearchAhead(url, target, obj)
{
   if(! WidgetSearchAheadInProgress)
   {
      WidgetSearchAheadInProgress = true;

      if(document.getElementById(target) && document.getElementById(target).value != document.getElementById(target).title)
      {
         var targetElement = document.getElementById(target + '_results');

         if(! jQuery('.widget-search-content', targetElement).html())
         {
   /*         jQuery('.widget-search-content', targetElement).html(limeload);

            if(! jQuery(targetElement).is(':visible'));
            {
               jQuery(targetElement).slideDown();
            }*/
         }

         jQuery.post(url, {target:target,value:document.getElementById(target).value}, WidgetSearchAheadResponse, 'json');
      }
   }
   else
   {
      WidgetSearchAheadInProgressUrl = url;
      WidgetSearchAheadInProgressTarget = target;
      WidgetSearchAheadInProgressObj = obj;

      WidgetSearchAheadQueuedRawDog = WidgetInputSearchAhead;
   }
}

/**
* WidgetInputSearchAhead()
*
* @todo Log last keyup and launch it if it exceeds the wait time of the pending request
* @todo multiple search aheads on one page
* @todo baseurl
* @todo duration parameter
*/
function WidgetInputSearchAheadQueue(url, id, obj)
{
   setTimeout("WidgetInputSearchAhead('"+url+"', '"+id+"', '"+obj+"')", 500);
}


function WidgetAdvancedSearchReset(form_id, list_id, url)
{
   var frm_elements = document.getElementById(form_id);

   for (i = 0; i < frm_elements.length; i++)
   {
       field_type = frm_elements[i].type.toLowerCase();
       switch (field_type)
       {
       case "text":
       case "password":
       case "textarea":
           frm_elements[i].value = "";
           break;
       case "radio":
       case "checkbox":
           if (frm_elements[i].checked)
           {
               frm_elements[i].checked = false;
           }
           break;
       case "select-one":
       case "select-multi":
           frm_elements[i].selectedIndex = 0;
           break;
       default:
           break;
       }
   }

   InitInfoFields();
   ListJumpMin(url, list_id);
}


function BuildUrl(getVars)
{
   var url = '';
   jQuery.each(getVars, function(field, value)
   {
      url += '&' + field + '=' + escape(value);
   });
   return url;
}

(function(ll)
{
   jQuery(document).ready(
   function()
   {
      InitInfoFields();
   });
})(jQuery);


function InjectInfoField(inField,message)
{
   if(typeof(message) == 'undefined' || message == '')
   {
      var message = '';
      var color   = 'black';
   }
   else
   {
      var color   = 'red';
   }
   jQuery(inField).attr('title',message);
   InitInfoFields(inField);
   jQuery(inField).css('color',color);
}

/**
* InitInfoFields()
*
* @todo assign the info-input class if an object is passed in to preserve the functionality
*/
function InitInfoFields(inField)
{
   var theField = jQuery('.info-input');

   if(typeof(inField) != 'undefined')
   {
      theField = inField;
   }

   if(jQuery(theField).length)
   {
      //Assign an inputs title to its values initially
      //
      jQuery(theField).each(
      function()
      {
         if(jQuery(this).val() == '')
         {
            jQuery(this).val(jQuery(this).attr('title'));

            //Adjust its class to appear passive
            //
            jQuery(this).addClass('info-input-field-inactive');
         }
      });

      jQuery(theField).blur(
      function()
      {
         if(jQuery(this).val() != jQuery(this).attr('title'))
         {
            jQuery(this).css('color','black');
            if(jQuery(this).val() == '')
            {
               jQuery(this).css('color','#b4b3b3');
               jQuery(this).removeClass('info-input-field-active');
               jQuery(this).val(jQuery(this).attr('title'));
               jQuery(this).addClass('info-input-field-inactive');
            }
         }
         else
         {
            jQuery(this).css('color','#b4b3b3');
         }
      });

      jQuery(theField).focus(
      function()
      {
         if(jQuery(this).val() == jQuery(this).attr('title'))
         {
            jQuery(this).removeClass('info-input-field-inactive');
            jQuery(this).addClass('info-input-field-active');

            //Clear the field of the initial title if its the first onfocus
            //
            if(jQuery(this).val() != '' && jQuery(this).val() == jQuery(this).attr('title'))
            {
               jQuery(this).val('');
            }
         }
         else
         {
            jQuery(this).css('color','black');
            jQuery(this).addClass('info-input-field-active');
         }
      });
   }
}

/**
* AjaxMaintainChecks()
*
* @param obj
* @param checkbox_class
* @param list_id
* @param url
* @param check_all_id
*/
function AjaxMaintainChecks(obj, checkbox_class, list_id, url, check_all_id)
{
   AjaxMaintainChecksRunning = true;
   var serializedChecks = '';
   var checkedAllBool = true;
   var checkedAllString = '1';
   var checkAllId = checkbox_class + '_all';

   /**
   * Checking All
   */
   if(check_all_id && check_all_id != '' && jQuery('#' + check_all_id).length > 0)
   {
      //Overwrite assumed check-all checkbox id
      //
      checkAllId = check_all_id;

      //Check or uncheck check-all checkbox
      //
      jQuery('.' + checkbox_class).not(':disabled').attr('checked', jQuery('#' + checkAllId).is(':checked'));
   }

   /**
   * Serialize all checkboxes both checked and unchecked
   */
   jQuery('.' + checkbox_class).not(':disabled').each(
      function(key, value)
      {
         var checked = '0';
             if(this.checked)
         {
            checked = '1';
          }
         else
         {
            checkedAllBool = false;
            checkedAllString = '0';
         }
             serializedChecks += escape(this.value) + '=' + checked + '&';
      }
   );

   /**
   * Check All Checkbox Status. On/Off
   */
   jQuery('#' + checkAllId).attr('checked', checkedAllBool);

   /**
   * Check All for this view (page/sequence
   */
   serializedChecks += 'checked_all=' + checkedAllString;

   /**
   * Record everything
   */
   jQuery.post(url, serializedChecks, function()
   {
      AjaxMaintainChecksRunning = false;
   }, "json");



}

function ToggleAdvancedSearch(searchElement)
{
   var contentArea = jQuery(searchElement).closest('div.inputOuter').find('.widget-search-drilldown');
   var inputArrow  = jQuery(searchElement).closest('div.inputOuter').find('.widget-search-arrow-advanced');
   var searchField = jQuery(searchElement).closest('div.inputOuter').find('.search-ahead');

   jQuery(contentArea).toggle();

   if(jQuery(contentArea).is(':visible'))
   {
      jQuery(inputArrow).css('visibility', 'hidden');
   }
   else
   {
      jQuery(inputArrow).css('visibility', 'visible');
   }
}

function SelectBoxResetSelectedRow(listId)
{
   var currentSelection = jQuery('#list_group_id_' + listId).val();
   jQuery('.widget-search-results-row[title="' + currentSelection + '"]').addClass('widget-search-results-row-selected');
}


function SelectBoxSetValue(value, listId)
{
   jQuery('#list_group_id_' + listId).val(value);
   SelectBoxResetSelectedRow(listId);
}



function HideAdvancedSearch(searchElement)
{
   var contentArea = jQuery(searchElement).closest('div.inputOuter').find('.widget-search-drilldown');
   var inputArrow  = jQuery(searchElement).closest('div.inputOuter').find('.widget-search-arrow-advanced');

   jQuery(contentArea).hide();

   jQuery(inputArrow).css('visibility', 'visible');
}

jQuery(document).ready(function($) {
    jQuery(document).ajaxSend(function(e, xhr, options) {
        var sid = jQuery("meta[name='csrf-token']").attr("content");
        xhr.setRequestHeader("X-CSRF-Token", sid);
    });
});

