module MaintenanceNotifier
  module MaintenanceConstants
    SCHEDULE_FILE       = 'maintenance_schedule.csv'
    NOTIFICATION_OFFSET = 12.hours
    HIDE_SESSION_KEY    = :hide_maintenance_alert
  end
  
  module ActionControllerIncludes
    def self.included(base)
      base.send :before_filter, :load_maintenance_info
      base.helper_method :enable_maintenance_message?
      base.send :helper, MaintenanceNotifier::MaintenanceHelper
    end
    
    private
    
    # Loads the latest maintenance schedule from the maintenance file.
    def load_maintenance_info
      return unless enable_maintenance_message?
      
      # Open <i>SCHEDULE_FILE</i> located inside w.r.t. <i>RAILS_ROOT</i>. 
      file_handle = File.open(File.join(RAILS_ROOT, MaintenanceConstants::SCHEDULE_FILE), 'rb')
      
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
  
  module MaintenanceHelper
    # Renders scheduled maintenance alert message, if any.
    def maintenance_alert
      # Maintenance enabled?
      should_show = enable_maintenance_message?
      # Any upcoming maintenance scheduled to happen within
      # <i>NOTIFICATION_OFFSET</i> from now?
      should_show &&= @maintenance_start_time && @maintenance_end_time
      should_show &&= (@maintenance_start_time - Time.now) < MaintenanceConstants::NOTIFICATION_OFFSET

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