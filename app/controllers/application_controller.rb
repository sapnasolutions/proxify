require 'httparty'

class ApplicationController < ActionController::Base
  #protect_from_forgery
  respond_to :xml, :json

  def rescue_action(e)
    puts "--------------------------------------In here"
  end

  def catch_all
    #get_url(params[:url])
    @response = HTTParty.get(session[:domain] + "/" + params[:path])
    @response= @response.html_safe
    render :template => "application/proxify"
  end

  def proxify
    get_url(params[:url], params)
    urls = params[:url].split("/")
    session[:domain] =  urls[0..2].join('/')
    puts "--------#{urls[0..2].join('/')}"
     #@response = @response.html_safe unless @response.headers.has_value?("text/javascript")
#    puts "***********#{@response.headers["content-type"].split('/').last.split(';').first}"
     
    #respond_with(@response)
    respond_to do |format|
      format.html{}
      format.json{render :json=> @response}
      format.xml{render :xml=> @response}
    end
  end

  def get_url(url, post_params = nil)
    if request.post?
      @response = HTTParty.post(url, :query => post_params)
    else
      @response = HTTParty.get(url)
    end
    @resp_format = @response.headers["content-type"].split('/').last.split(';').first
    re=  @resp_format == 'html' ? @response.html_safe : (@resp_format == 'javascript' ? @response.to_json.html_safe : @response.to_xml.html_safe)
    @response = re
  end

end
