module WidgetList
  class Railtie < Rails::Railtie
    initializer 'widget_list.database_adapters' do
      ActiveSupport.on_load(:action_controller) do
        require 'sequel'
        require 'widget_list/sequel'
      end
    end

    initializer 'widget_list.assets' do |app|
      if defined?(Sprockets::Railtie) && app.config.respond_to?(:assets)
        image_root = Pathname.new(__dir__).join('../..', 'vendor/assets/images').expand_path
        images = Dir[image_root.join('**/*')].select { |path| File.file?(path) && %w[.gif .jpg .jpeg .png].include?(File.extname(path).downcase) }
        app.config.assets.precompile += images.map { |path| Pathname.new(path).relative_path_from(image_root).to_s }
        app.config.assets.precompile += %w[widget_list.css widgets.css widget_list.js]
      end
    end
  end
end
