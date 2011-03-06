require 'httparty'

class ApplicationController < ActionController::Base
  before_filter :check_session_domain, :only => [:proxify, :catch_routes]

  def catch_routes
    response = HTTParty.get(session[:domain] + "/" + params[:path], :basic_auth => {:username => session[:basic_auth_username], :password => session[:basic_auth_password]})
    render_asset_response(response)
  end

  def proxify
    url = url_check(params[:url])
    get_url(url)
    session[:domain] =  url
  end

  def index
	#session[:domain] = "" if session[:domain]
  end
  
  def credentials
  end

  def clear_session
    reset_session
    redirect_to "/"
  end

  ############
  private
  ############

  def get_url(url)
    options = get_query_params
    @response = request.post? ? HTTParty.post(url, options) : HTTParty.get(url, options)
    @response_format = @response.headers["content-type"].split('/').last.split(';').first
    redirect_to :credentials if @response.code == 401
    #@response =  @response_format == 'html' ? @response.html_safe : (@response_format == 'javascript' ? @response.to_json.html_safe : @response.to_xml)
    render_response
  end
  
  def render_response
    case @response_format
      when 'html'
        #@response = @response.gsub(img_regex, img_replace_val).gsub(link_regex, link_replace_val).html_safe
        @response = @response.gsub(img_regex, img_replace_val)
        links = @response.scan(link_regex).flatten
        links.each do |link|
          new_link = link.gsub(/href="((http|https)?:\/\/)/, link_replace_val)
          @response = @response.gsub(link, new_link)
        end
        @response = @response.html_safe
      when  'javascript' 
        @response = @response.to_json.html_safe
      when "xml"
        @response = @response.to_xml
        send_data(@response, :type =>  "xml", :disposition  =>  'inline')
      else
        render_asset_response(@response)
    end
  end
  
  def get_query_params
    if params[:basic_auth_username].present?
      session[:basic_auth_username] = params[:basic_auth_username]
      session[:basic_auth_password] = params[:basic_auth_password]
      @auth = {:username => params[:basic_auth_username], :password => params[:basic_auth_password]}
      options = request.post? ? { :query => params, :basic_auth => @auth } : {:basic_auth => @auth}
    else
       session[:basic_auth_username] = nil
       session[:basic_auth_password] = nil
      options = request.post? ? { :query => params} : {}
    end
    return options
  end

  def check_session_domain
    if params[:url].blank? && session[:domain].present?
      params[:url] = session[:domain]
    elsif params[:url].blank?
      render :template => "application/index"
      return
    end
  end
  
  def url_check(url)
    url = "http://" + url if(url.index(/\b(?:https?:\/\/)\S+\b/) == nil)
    url =  url.match(/\b(?:https?:\/\/)\S+\b/).to_s
    url
  end
  
  def render_asset_response(response)
    send_data(response, :type =>  response.headers["content-type"], :disposition  =>  'inline')
  end
  
  def img_regex
    /src="((http|https)?:\/\/)/
  end
  
  def link_regex
    /<link\s+[^>]*(href\s*=\s*(['"]).*?\2)/
  end
  
  def img_replace_val
    "src=\"#{SITE_URL}?url=http://"
  end
  
  def link_replace_val
    "href=\"#{SITE_URL}?url=http://"
  end
  
end
