module WidgetList
  class RequestContext < ActiveSupport::CurrentAttributes
    attribute :request, :server, :session, :used, :csrf_token
  end
end
