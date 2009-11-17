desc "Installs maintenance_notifier plugin."
namespace :maintenance_notifier do
  task :install do
    require 'fileutils'
    
    files_to_copy = []
    files_to_copy << {
      :src => "#{File.dirname(__FILE__)}/../lib/src/maintenance_controller.rb",
      :dest => "#{RAILS_ROOT}/app/controllers/maintenance_controller.rb"
    }
    
    files_to_copy << {
      :src => "#{File.dirname(__FILE__)}/../lib/src/_maintenance_alert.html.erb",
      :dest => "#{RAILS_ROOT}/app/views/maintenance/_maintenance_alert.html.erb",
      :prerequisite => "#{RAILS_ROOT}/app/views/maintenance/"
    }
    
    files_to_copy << {
      :src => "#{File.dirname(__FILE__)}/../lib/src/maintenance_notifier.css",
      :dest => "#{RAILS_ROOT}/public/stylesheets/maintenance_notifier.css"
    }

    files_to_copy.each do |copy_info|
      src = copy_info[:src]
      dest = copy_info[:dest]
      prerequisite = copy_info[:prerequisite]

      # Controller with the name already exists? 
      if File.exists?(dest)
        puts "ERROR: Problem installing plugin. File #{dest} already exists."
      else
        begin
          if prerequisite && !File.exists?(prerequisite)
            print "Creating #{prerequisite} ... "
            FileUtils.mkdir_p prerequisite
            puts "DONE"
          end
          
          print "Creating #{dest} ... "
          FileUtils.cp_r src, dest
          puts "DONE"
        rescue => e
          puts e.inspect
          puts "ERROR: Problem installing plugin."
          puts "Please manually copy #{File.expand_path(src)} to #{dest}"
          exit 1
        end
      end
    end

    puts "\n"
    puts "Successfully installed Maintenance Notifier plugin."
  end
end
