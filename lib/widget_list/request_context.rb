module WidgetList
  class RequestContext < ActiveSupport::CurrentAttributes
    attribute :request, :server, :session, :used
  end
end
