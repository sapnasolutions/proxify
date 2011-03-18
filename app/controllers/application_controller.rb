require 'httparty'

class ApplicationController < ActionController::Base
  before_filter :check_session_domain, :check_request_header, :only => [:proxify, :catch_routes]

  def catch_routes
	puts "==== in catch_routes ===="
    #response = send_get
	if session[:basic_auth_username].nil? || session[:basic_auth_username].blank?
		response = HTTParty.get(session[:domain] + "/" + params[:path])
	else
	    response = HTTParty.get(session[:domain] + "/" + params[:path], :basic_auth => {:username => session[:basic_auth_username], :password => session[:basic_auth_password]})
    end
	render_asset_response(response)
  end

  def proxify
	puts "==== in /proxify ===="
    url = url_check(params[:url])
    session[:domain] =  url
	get_url(url)
  end

  def index
	session[:domain] = "" if session[:domain]
  end
  
  def credentials
	puts "==== in credentials ===="
  end

  def clear_session
    reset_session
    redirect_to "/"
  end

  ############
  private
  ############

  def get_url(url)
	puts "==== in get_url ===="
    options = get_query_params
	puts "options: #{options}"
    @response = request.post? ? HTTParty.post(url, options) : HTTParty.get(url, options)
	puts "response: #{response}"
	#@response = request.post? ? send_post : send_get
    @response_format = @response.headers["content-type"].split('/').last.split(';').first
    redirect_to :credentials if @response.code == 401
    #@response =  @response_format == 'html' ? @response.html_safe : (@response_format == 'javascript' ? @response.to_json.html_safe : @response.to_xml)
    render_response
  end
  
  def send_post
	puts "==== in send_post ===="
	optional_hash = {}
	if request.headers[:authentication].blank?
		puts "in if conditions, since headers[:authentication] is blank"
		HTTParty.post(session[:domain] + "/" + params[:path])
	else
		puts "in else conditions, since headers[:authentication] is not blank"
		HTTParty.post(session[:domain] + "/" + params[:path], :basic_auth => optional_hash)
		base64_string = request.headers[:authentication].split(" ").last
		optional_hash = {:username => username_from_base64(base64_string), :password => password_from_base64(base64_string)} 
	end	
  end
  
  def send_get
	puts "==== in send_get ===="
	optional_hash = {}
	if request.headers["authentication"].blank?
		HTTParty.get(session[:domain] + "/" + params[:path])
	else
		base64_string = request.headers[:authentication].split(" ").last
		optional_hash = {:username => username_from_base64(base64_string), :password => password_from_base64(base64_string)} 
		HTTParty.get(session[:domain] + "/" + params[:path], :basic_auth => optional_hash)
	end	
  end
  
  def username_from_base64(base64_string)
	username = Base64.decode64(base64_string).split(":").first
  end
  
  def password_from_base64
	password = Base64.decode64(base64_string).split(":").last
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
  
  def check_request_header
	request.headers["username"]
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
