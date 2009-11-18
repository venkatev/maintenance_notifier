class MaintenanceController < ApplicationController
  # Sets session entry for hiding maintenance message for this session.  
  def hide
    session[MaintenanceNotifier::MaintenanceConstants::HIDE_SESSION_KEY] = true
    render :nothing => true
  end
end