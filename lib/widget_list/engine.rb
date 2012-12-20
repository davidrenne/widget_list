module WidgetList
  class Engine < Rails::Engine
    # auto wire
    initializer 'static_assets.load_static_assets' do |app|
      app.middleware.use ::ActionDispatch::Static, "#{root}/vendor"
    end
  end
end
