class LinksController < ApplicationController

  def visit
    time_now = Time.now
    link = Link.find_by_unique(params[:link])
    history = EmailHistory.find_by_unique(params[:history])
    timestamps = {:open_at => time_now}
    timestamps.merge!(:visit_at => time_now) if params[:activity] == 'visit'
    history.update_attributes!(timestamps)
    redirect_to link.url
  end

  def unsubscribe
  end

end
