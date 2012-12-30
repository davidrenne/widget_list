#these scripts will create a new gem, mount a vendor folder and publish the gem

CAMELCASE=WidgetList
GEMNAME=widget_list

rvm gemset create $GEMNAME
rvm gemset use $GEMNAME
gem install bundler
bundle gem $GEMNAME
#chown wcapp:wcapp -R $GEMNAME/*
cd $GEMNAME/
mkdir -p vendor/assets/{images,javascripts,stylesheets} 
touch vendor/assets/javascripts/$GEMNAME.js
touch vendor/assets/stylesheets/$GEMNAME.css
touch lib/$GEMNAME/engine.rb
echo 'Add require "'$GEMNAME'/engine" to lib/'$GEMNAME'.rb'
echo 'Next Add //= require '$GEMNAME' to application.js in your rails application'
echo 'Next Add *= require '$GEMNAME' to application.css in your rails application'
echo 'module '$CAMELCASE > lib/$GEMNAME/engine.rb
echo '  class Engine < Rails::Engine' >> lib/$GEMNAME/engine.rb
echo '    # auto wire' >> lib/$GEMNAME/engine.rb
echo "    initializer 'static_assets.load_static_assets' do |app|" >> lib/$GEMNAME/engine.rb
echo '      app.middleware.use ::ActionDispatch::Static, "#{root}/vendor"' >> lib/$GEMNAME/engine.rb
echo '    end' >> lib/$GEMNAME/engine.rb
echo '  end' >> lib/$GEMNAME/engine.rb
echo 'end' >> lib/$GEMNAME/engine.rb

#to publish it
#curl -u incubus158 https://rubygems.org/api/v1/api_key.yaml > ~/.gem/credentials

#first edit version.rb and increment it to your new version, then run this
gem build *gemspec | awk 'NR==4{print $2}' > tmpfile.txt
GEMBUILD=`cat tmpfile.txt`
gem push $GEMBUILD
rm tmpfile.txt $GEMBUILD


