desc "Installs maintenance_notifier plugin."
namespace :maintenance_notifier do
  task :install do
    require 'fileutils'
    
    files_to_copy = []
    files_to_copy << {
      :src => "#{File.dirname(__FILE__)}/../src/app/controllers/maintenance_controller.rb",
      :dest => "#{RAILS_ROOT}/app/controllers/maintenance_controller.rb"
    }
    
    files_to_copy << {
      :src => "#{File.dirname(__FILE__)}/../src/app/views/maintenance/_maintenance_alert.html.erb",
      :dest => "#{RAILS_ROOT}/app/views/maintenance/_maintenance_alert.html.erb",
      :prerequisite => "#{RAILS_ROOT}/app/views/maintenance/"
    }
    
    files_to_copy << {
      :src => "#{File.dirname(__FILE__)}/../src/public/stylesheets/maintenance_notifier.css",
      :dest => "#{RAILS_ROOT}/public/stylesheets/maintenance_notifier.css"
    }

    puts "Copying files:"
    files_to_copy.each do |copy_info|
      src          = File.expand_path(copy_info[:src])
      dest         = File.expand_path(copy_info[:dest])
      prerequisite = File.expand_path(copy_info[:prerequisite]) if copy_info[:prerequisite]

      # The destination file already exists? Report the problem and continue. 
      if File.exists?(dest)
        puts "ERROR: Problem installing plugin. File #{dest} already exists."
      else
        begin
          if prerequisite && !File.exists?(prerequisite)
            puts "+ #{prerequisite} ... "
            FileUtils.mkdir_p prerequisite
            print "  "
          end
          
          puts "+ #{dest} ... "
          FileUtils.cp_r src, dest
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
    puts "Please look into README for usage and examples."
    puts "\n"
  end
end
