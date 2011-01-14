require 'httparty'

class ApplicationController < ActionController::Base

  def catch_routes
    response = HTTParty.get(session[:domain] + "/" + params[:path])
    send_data(response, :type =>  response.headers["content-type"].to_s, :disposition  =>  'inline')
  end

  def proxify
    unless params[:url]
      @response = "Welcome to proxify"
      render :template => "application/index"
      return
    end

    url = params[:url]
    url = "http://" + url if(url.index(/\b(?:https?:\/\/)\S+\b/) == nil)
    get_url(url, params)
    session[:domain] =  url.match(/\b(?:https?:\/\/)\S+\b/).to_s
    
    send_data(@response, :type =>  "xml", :disposition  =>  'inline') if @response_format == "xml"
    
  end

  def get_url(url, post_params = nil)
    if request.post?
      @response = HTTParty.post(url, :query => post_params)
    else
      @response = HTTParty.get(url)
    end
    @response_format = @response.headers["content-type"].split('/').last.split(';').first
    @response =  @response_format == 'html' ? @response.html_safe : (@response_format == 'javascript' ? @response.to_json.html_safe : @response.to_xml)
  end

end
