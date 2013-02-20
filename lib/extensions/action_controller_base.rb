require 'action_controller'

ActionController::Base.class_eval {
  private
    def globalize_request
      # Create super global PHP variables
      $_SESSION = self.session
      $_SERVER  = self.env
      $_REQUEST = self.request.filtered_parameters
    end

  private
    def store_session
      # Store pre-defined widget_list session items to the actual session

      %w(pageDisplayLimit DRILL_DOWNS ROW_LIMIT list_checks SEARCH_FILTER LIST_SEQUENCE LIST_COL_SORT list_count DRILL_DOWN_FILTERS).each { |key|
        self.session[key] = $_SESSION[key]
      }

      test= 1
    end
}

ActionController::Base.instance_eval {
  helper_method :globalize_request

  helper_method :store_session

  before_filter :globalize_request

  after_filter :store_session
}

