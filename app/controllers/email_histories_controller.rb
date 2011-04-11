class EmailHistoriesController < ApplicationController
  # GET /email_histories
  # GET /email_histories.xml
  def index(klass = EmailHistory)
    @email_histories = klass.order('created_at DESC').page(params[:page])

    respond_to do |format|
      format.html { render :action => 'index' }
      format.xml  { render :xml => @email_histories }
    end
  end

  def bounced
    index(EmailHistory.bounced)
  end

  def visited
    index(EmailHistory.visited)
  end

  # GET /email_histories/1
  # GET /email_histories/1.xml
  def show
    @email_history = EmailHistory.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @email_history }
    end
  end

  # GET /email_histories/new
  # GET /email_histories/new.xml
  def new
    @email_history = EmailHistory.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @email_history }
    end
  end

  # GET /email_histories/1/edit
  def edit
    @email_history = EmailHistory.find(params[:id])
  end

  # POST /email_histories
  # POST /email_histories.xml
  def create
    @email_history = EmailHistory.new(params[:email_history])

    respond_to do |format|
      if @email_history.save
        format.html { redirect_to(@email_history, :notice => 'Email history was successfully created.') }
        format.xml  { render :xml => @email_history, :status => :created, :location => @email_history }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @email_history.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /email_histories/1
  # PUT /email_histories/1.xml
  def update
    @email_history = EmailHistory.find(params[:id])

    respond_to do |format|
      if @email_history.update_attributes(params[:email_history])
        format.html { redirect_to(@email_history, :notice => 'Email history was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @email_history.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /email_histories/1
  # DELETE /email_histories/1.xml
  def destroy
    @email_history = EmailHistory.find(params[:id])
    @email_history.destroy

    respond_to do |format|
      format.html { redirect_to(email_histories_url) }
      format.xml  { head :ok }
    end
  end
end
