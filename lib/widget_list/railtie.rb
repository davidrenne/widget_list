module WidgetList
  class Railtie < Rails::Railtie

    config.before_configuration do
      config_file = Rails.root.join("config", "widget-list.yml")
      if config_file.file?
        # WidgetList::List::connect
      else
        puts "\nWidget List config not found.  Creating config/widget-list.yml.  \n\nPlease configure it with the appropriate connections"
        File.open(Rails.root.join("config", "widget-list.yml"), 'w') { |file|
          file.write("#For connection examples see: http://sequel.rubyforge.org/rdoc/files/doc/opening_databases_rdoc.html\n\n")
          file.write("development:\n")
          file.write("  :primary:     sqlite:/\n")
          file.write("  :secondary:   sqlite:/\n")
          file.write("\n")
          file.write("test:\n")
          file.write("  :primary:     sqlite:/\n")
          file.write("  :secondary:   sqlite:/\n")
          file.write("\n")
          file.write("release:\n")
          file.write("  :primary:     sqlite:/\n")
          file.write("  :secondary:   sqlite:/\n")
          file.write("\n")
          file.write("production:\n")
          file.write("  :primary:     sqlite:/\n")
          file.write("  :secondary:   sqlite:/\n")
        }
      end
    end

    initializer "Include widget_list" do
      ActiveSupport.on_load(:action_controller) do
        if WidgetList::List::is_sequel(true) || WidgetList::List::is_sequel(false)
          require 'sequel'
        end
        require 'widget_list/sequel'
      end
    end


  end
end
