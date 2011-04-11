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
    if history = EmailHistory.find_by_unique(params[:history])
      if archive = EmailArchive.find_by_message_id(history.message_id)
        mail = Mail.new(archive.body)
        sender = mail['List-ID'] ? mail['List-ID'].value : mail.froms.first
      else
        sender = history.from.email
      end
      history.to.blocked_lists.create :sender => sender
    else
      # preferably, not error out on such 404
      logger.warn "EmailHistory unsubscribed, but not found - #{params[:history].inspect}"
    end
  end

end
