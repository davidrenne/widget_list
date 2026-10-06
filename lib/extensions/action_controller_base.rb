require 'action_controller'

module WidgetList
  module ControllerContext
    private

    def with_widget_list_request_context
      RequestContext.session = session.to_h.deep_dup
      RequestContext.server = request.env
      RequestContext.request = request.filtered_parameters

      yield
    ensure
      if RequestContext.used && RequestContext.session
        %w[pageDisplayLimit DRILL_DOWNS CURRENT_GROUPING ROW_LIMIT list_checks SEARCH_FILTER LIST_SEQUENCE LIST_COL_SORT list_count DRILL_DOWN_FILTERS].each do |key|
          session[key] = RequestContext.session[key] if RequestContext.session.key?(key)
        end
      end
      RequestContext.reset
    end
  end
end

ActionController::Base.include(WidgetList::ControllerContext)
ActionController::Base.around_action :with_widget_list_request_context
