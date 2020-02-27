require 'json'
require 'net/https'

module APICalls

  def self.encodeUrl(url, params)
    URI::encode( "#{url}?").concat(params.collect { |k,v| URI::encode("#{k}=#{v.to_s}").gsub("&", "%26") }.join('&'))
  end

  def self.getRequest(url, params, headers={"Content-Type": "application/json"})
    url = APICalls.encodeUrl(url, params) unless params.nil?
    puts "*** Get-Request To: #{url}"
    url = URI.parse(url)
    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = url.scheme == 'https'
    while true
      begin
        http.start do |http|
          req = Net::HTTP::Get.new("#{url.path}?#{url.query}", headers)
          resp = http.request(req)
          return resp
        end
      rescue Exception => e  
        puts e.message 
        p "open timeout rescued"
      end
    end
  end

  def self.postRequest(url, params, body, headers={"Content-Type": "application/json"})
    p " in postRequest with url = #{url} , params = #{params} and body == #{body}"
    url = APICalls.encodeUrl(url, params) unless params.nil?
    url = URI.parse(url)
    p " url ========== " , url
    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = url.scheme == 'https'
    p " http ========== " , http
    http.start do |http|
      req = Net::HTTP::Post.new("#{url.path}?#{url.query}")
      req["Content-Type"] = "application/json"
      req.body = body
      p " req ========== " , req
      p "req.body ============= #{req.body} "
      resp = http.request(req)
      return resp
    end

  end

  def self.postRequestAuthentication(url,body,user)
    url = URI.parse(url)
    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = url.scheme == 'https'
    http.start do |http|
      req = Net::HTTP::Post.new("#{url.path}?#{url.query}")
      req["Content-Type"] = "application/json"
      req["Authorization"] = "Bearer " + user.auth_token
      req.body = body.to_json
      resp = http.request(req)
      return resp
    end
  end

  def self.putRequest(url, params, body, to_json = true)
    url = APICalls.encodeUrl(url, params)
    url = URI.parse(url)
    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = url.scheme == 'https'
    http.start do |http|
      req = Net::HTTP::Put.new("#{url.path}?#{url.query}")
      req.body = to_json ? body.to_json : body
      resp = http.request(req)
      return resp
    end
  end

  def self.deleteRequest(url, params)
    url = APICalls.encodeUrl(url, params)
    url = URI.parse(url)
    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = url.scheme == 'https'
    http.start do |http|
      req = Net::HTTP::Delete.new("#{url.path}?#{url.query}")
      resp = http.request(req)
      return resp
    end
  end

end
