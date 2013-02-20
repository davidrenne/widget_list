
$G_TEMPLATE = {'widget' =>
                 {'required'=> '<div class="required">*</div>'
                 }
}

$G_TEMPLATE.deep_merge!({'widget' =>
                           {'input'=>
                              {'default' =>
                                 '
<div class="<!--OUTER_CLASS-->" style="<!--OUTER_STYLE-->" id="<!--OUTER_ID-->">
   <div class="<!--INNER_CLASS-->" style="<!--INNER_STYLE-->">
      <input <!--EVENT_ATTRIBUTES--> <!--READONLY--> type="<!--INPUT_TYPE-->" class="<!--INPUT_CLASS-->" style="<!--INPUT_STYLE-->" id="<!--ID-->" name="<!--NAME-->" title="<!--TITLE-->" value="<!--VALUE-->" maxlength="<!--MAX_LENGTH-->">
   </div>
</div>
<!--REQUIRED-->'
                              }
                           }
                        })
$G_TEMPLATE.deep_merge!({'widget' =>
                           {'input'=>
                              {'search' =>
                                 '
<div class="<!--OUTER_CLASS-->" style="<!--OUTER_STYLE-->" onclick="<!--OUTER_ACTION-->">
   <div class="<!--INNER_CLASS-->" style="<!--INNER_STYLE-->">
      <input <!--READONLY--> <!--EVENT_ATTRIBUTES--> type="text" class="<!--INPUT_CLASS-->" style="<!--INPUT_STYLE-->" id="<!--ID-->" name="<!--NAME-->" title="<!--TITLE-->" value="<!--VALUE-->" maxlength="<!--MAX_LENGTH-->">
   </div>
   <div class="widget-search-arrow <!--ARROW_EXTRA_CLASS-->"  onclick="<!--ARROW_ACTION-->"></div>
   <!--MAGNIFIER-->
   <div id="<!--ID-->_results" class="widget-search-drilldown" style="">
      <div class="widget-search-content"><!--SEARCH_FORM--></div>
   </div>
</div>'
                              }
                           }
                        })
$G_TEMPLATE.deep_merge!({'widget' =>
                           {'radio'=>
                              {'default' =>
                                 '
<input type="radio" class="<!--INPUT_CLASS-->" style="<!--INPUT_STYLE-->" id="<!--ID-->" name="<!--NAME-->" title="<!--TITLE-->" value="<!--VALUE-->" onclick="<!--ONCLICK-->" <!--CHECKED-->>
<!--REQUIRED-->'
                              }
                           }
                        })
$G_TEMPLATE.deep_merge!({'widget' =>
                           {'checkbox'=>
                              {'default' =>
                                 '
<input type="checkbox" class="<!--INPUT_CLASS-->" style="<!--INPUT_STYLE-->" id="<!--ID-->" name="<!--NAME-->" value="<!--VALUE-->" onclick="<!--ONCLICK-->" <!--CHECKED-->>
<!--REQUIRED-->'
                              }
                           }
                        })
$G_TEMPLATE.deep_merge!({'widget' =>
                           {'selectbox_nostyle'=>
                              {'wrapper' =>
                                 '
<select <!--DISABLED_FLG--> class="<!--CLASS-->" id="<!--ID-->" style="<!--STYLE-->" name="<!--NAME-->" <!--MULTIPLE--> size="<!--SIZE-->" onchange="<!--ONCHANGE-->" <!--ATTRIBUTES-->><!--OPTIONS--></select> <!--REQUIRED-->'
                              }
                           }
                        })
$G_TEMPLATE.deep_merge!({'widget' =>
                           {'selectbox'=>
                              {'wrapper' =>
                                 '
<div class="<!--OUTER_CLASS-->" style="<!--OUTER_STYLE-->" onclick="<!--OUTER_ACTION-->">
   <div class="<!--INNER_CLASS-->" style="<!--INNER_STYLE-->">
      <select border="0" <!--DISABLED_FLG--> class="<!--CLASS-->" id="<!--ID-->" style="<!--STYLE-->" name="<!--NAME-->" <!--MULTIPLE--> size="<!--SIZE-->" onchange="<!--ONCHANGE-->" <!--ATTRIBUTES-->><!--OPTIONS--></select>
   </div>
</div>
<!--REQUIRED-->'
                              }
                           }
                        })
$G_TEMPLATE.deep_merge!({'widget' =>
                           {'selectbox'=>
                              {'option' =>
                                 '
<option value="<!--VALUE-->" onclick="<!--ONCLICK-->" <!--SELECTED-->><!--CONTENT--></option>'
                              }
                           }
                        })
$G_TEMPLATE.deep_merge!({'widget' =>
                           {'selectbox'=>
                              {'option_showid' =>
                                 '<option value="<!--VALUE-->" onclick="<!--ONCLICK-->" <!--SELECTED-->><!--CONTENT--> (<!--VALUE-->)</option>'
                              }
                           }
                        })
$G_TEMPLATE.deep_merge!({'widget' =>
                           {'selectbox'=>
                              {'option_showid_left' =>
                                 '<option value="<!--VALUE-->" onclick="<!--ONCLICK-->" <!--SELECTED-->>(<!--VALUE-->) <!--CONTENT--></option>'
                              }
                           }
                        })
$G_TEMPLATE.deep_merge!({'widget' =>
                           {'selectbox'=>
                              {'initial' =>
                                 '
<option value="<!--VALUE-->" onclick="<!--ONCLICK-->" <!--SELECTED-->><!--CONTENT--></option>'
                              }
                           }
                        })
$G_TEMPLATE.deep_merge!({'widget' =>
                           {'selectbox'=>
                              {'passive' =>
                                 '
<span class="<!--CLASS-->" id="<!--ID-->" name="<!--NAME-->" size="<!--SIZE-->" <!--ATTRIBUTES-->><!--OPTIONS--></span>'
                              }
                           }
                        })
$G_TEMPLATE.deep_merge!({'widget' =>
                           {'selectfreeflow'=>
                              {'wrapper' =>
                                 '
<div class="<!--OUTER_CLASS-->" style="<!--OUTER_STYLE-->" onclick="<!--OUTER_ACTION-->">
   <div class="<!--INNER_CLASS-->" style="<!--INNER_STYLE-->">
      <!--SELECT_ONE_TEXT-->
   </div>
   <div class="widget-select-freeflow-arrow <!--ARROW_EXTRA_CLASS-->" style="" onclick="<!--ARROW_ACTION-->"></div>

   <div id="select_freeflow_<!--ID-->" class="widget-select-freeflow-drilldown">
      <ul class="widget-select-freeflow-content">
         <!--OPTIONS-->
      </ul>
   </div>
</div>'
                              }
                           }
                        })
$G_TEMPLATE.deep_merge!({'widget' =>
                           {'selectfreeflow'=>
                              {'option' =>
                                 '
<li onclick="<!--ONCLICK-->" class="<!--SELECTED-->">
   <input type="hidden" name="select_free_option_name<!--NAME-->[]" name="select_option_<!--NAME-->_id_<!--COUNTER-->" value="<!--VALUE-->">
   <!--CONTENT-->
</li>'
                              }
                           }
                        })
$G_TEMPLATE.deep_merge!({'widget' =>
                           {'button'=>
                              {'default' =>
                                 '
<!--FRM_SUBMIT-->
<a class="<!--BUTTON_CLASS-->" style="<!--BUTTON_STYLE-->" onclick="<!--BUTTON_ONCLICK-->" name="<!--NAME-->" id="<!--ID-->">
   <!--BUTTON_LABEL-->
</a>'
                              }
                           }
                        })
$G_TEMPLATE.deep_merge!({'widget' =>
                           {'container'=>
                              {'row' =>
                                 '<tr><!--CONTENT--></tr>'
                              }
                           }
                        })
$G_TEMPLATE.deep_merge!({'widget' =>
                           {'container'=>
                              {'col' =>
                                 {'pre_text' =>
                                    '<td colspan="<!--COL_SPAN-->" id="<!--ID-->" class="<!--CLASS-->"><div class="container-label"><!--PRE_TEXT--></div> <!--CONTENT--></td>'
                                 }
                              }
                           }
                        })
$G_TEMPLATE.deep_merge!({'widget' =>
                           {'container'=>
                              {'col' =>
                                 {'standard' =>
                                    '<td colspan="<!--COL_SPAN-->" id="<!--ID-->" class="<!--CLASS-->"><!--CONTENT--></td>'
                                 }
                              }
                           }
                        })
$G_TEMPLATE.deep_merge!({'widget' =>
                           {'container'=>
                              {'wrapper' =>
                                 '<form method="post" id="<!--FORM_ID-->"><table class="<!--OUTER_CLASS-->" id="<!--OUTER_ID-->"><!--CONTENT--></table>'
                              }
                           }
                        })