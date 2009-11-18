# = Maintenance notifier
# 
# Show scheduled maintenance messages to end users, notifying them about the
# expected downtime.
# 
# === Installation
# Using Git
#   script/plugin install http://github.com/venkatev/maintenance_notifier
# 
# === Setup
# After installing the plugin, run <b>rake maintenance_notifier:install</b> command
# to copy files required by the plugin to the project.
# 
# === Usage
# * Include assets required by the plugin using +maintenance_helper_includes+.
#   Typically this goes into the HEAD section in the layout.
# * Call +maintenance_alert+ helper in your layout/template at the point where
#   it should be rendered.
# 
# == Configuration
# The notifier can be configured as per your application needs as follows.
# 
# * By default, maintenance messages are enabled only for production environment.
#   For enabling them in development environment, override
#   ApplicationControll# enable_maintenance_message? to return true.
# * The default maintenance file is maintenance_schedule.csv located at project root.
#   It can be changed by setting MaintenanceNotifier::Configuration.maintenance_schedule_file.
# * The default notification period is 24 hours, i.e, the message will be started
#   to be shown 24 hours prior to the scheduled start time. It can be changed by
#   setting MaintenanceNotifier::Configuration.maintenance_notification_offset. 
#
# 
# Author: Vikram Venkatesan (vikram.venkatesan@yahoo.com)
# * http://venkatev.wordpress.com/
# * http://github.com/venkatev/
# 
module MaintenanceNotifier
  class Configuration
    @@maintenance_schedule_file = nil
    @@maintenance_notification_offset = nil

    # Returns the maintenance schedule file path. 
    def self.maintenance_schedule_file
      @@maintenance_schedule_file || MaintenanceConstants::SCHEDULE_FILE
    end
    
    # Sets the maintenance schedule file to use other than
    # MaintenanceConstants::SCHEDULE_FILE.
    # 
    # ==== Params
    # * <tt>file_name</tt> : path of the maintenance file w.r.t project root.
    def self.maintenance_schedule_file=(file_name)
      @@maintenance_schedule_file = file_name
    end
    
    # Returns the maintenance notification offset.
    def self.maintenance_notification_offset
      @@maintenance_notification_offset || MaintenanceConstants::NOTIFICATION_OFFSET
    end    

    # Sets the maintenance notification offset to use other than
    # MaintenanceConstants::NOTIFICATION_OFFSET.
    # 
    # ==== Params
    # * <tt>new_offset</tt> : time offset.
    def self.maintenance_notification_offset=(new_offset)
      @@maintenance_notification_offset = new_offset
    end
  end
  
  module MaintenanceConstants
    # Default schedule file. Please look into the sample schedule file
    # sample_schedule.csv for format.
    SCHEDULE_FILE = 'maintenance_schedule.csv'
    
    # Time before the maintenance that we want to start showing the message.
    NOTIFICATION_OFFSET = 24.hours
    
    # Rails session key for tracking per-session 'ignore' actions by the users.  
    HIDE_SESSION_KEY = :hide_maintenance_alert
  end
  
  module ActionControllerIncludes
    def self.included(base)
      base.send :include, InstanceMethods
      
      base.send :before_filter, :load_maintenance_info
      base.send :helper, MaintenanceNotifier::MaintenanceHelper
      base.helper_method :enable_maintenance_message?
    end
    
    module InstanceMethods
      private
      
      # Loads the latest maintenance schedule from the maintenance file.
      def load_maintenance_info
        return unless enable_maintenance_message?
        
        schedule_file = MaintenanceNotifier::Configuration.maintenance_schedule_file
        file_handle = File.open(File.join(RAILS_ROOT, schedule_file), 'rb')
        
        # Read only the top most line from the line.
        latest_maintenance_data = file_handle.readline.strip
        start_time, end_time = latest_maintenance_data.split(',')
        start_time.strip!
        end_time.strip!
        
        # No maintenance scheduled?
        return if start_time.blank? || end_time.blank?
        @maintenance_start_time = Time.parse(start_time)
        @maintenance_end_time = Time.parse(end_time)
      end
      
      # Returns whether to enable maintenance message. Defaults to true for
      # production alone.
      #
      # Override this helper method for testing in development environment.
      def enable_maintenance_message?
        RAILS_ENV == 'production'
      end      
    end
  end
  
  module MaintenanceHelper
    # Renders scheduled maintenance alert message, if any.
    def maintenance_alert
      # Maintenance enabled?
      should_show = enable_maintenance_message?
      # Any upcoming maintenance scheduled to happen within
      # maintenance_notification_offset from now?
      should_show &&= @maintenance_start_time && @maintenance_end_time
      should_show &&= (@maintenance_start_time - Time.now) < MaintenanceNotifier::Configuration.maintenance_notification_offset
      
      # Not ignored by user already?
      should_show &&= !session[MaintenanceNotifier::MaintenanceConstants::HIDE_SESSION_KEY]
      
      if should_show
        render :partial => 'maintenance/maintenance_alert'
      end      
    end
    
    # Includes assets for maintenance notifier. 
    def maintenance_helper_includes
      return unless enable_maintenance_message?
      stylesheet_link_tag('maintenance_notifier.css')
    end
  end
end