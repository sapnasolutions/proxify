require 'httparty'

class ApplicationController < ActionController::Base
  #protect_from_forgery
  layout false

  def proxify
    requested_url = params[:url]
    if request.post?
      response = HTTParty.post(requested_url, :query => params)
    else
      response = HTTParty.get(requested_url)
    end
    respond_to do |format|
      format.xml  { render :xml => response}
      format.json { render :json => response}
    end
  end

end
