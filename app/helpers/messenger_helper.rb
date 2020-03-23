include APICalls
include ChatbotHelper

module MessengerHelper

    def self.send_responses(page_access_token, responses, user_psid, variable, project, user_project, persona_id) # type:, value:
        p "in MessengerHelper in send_message  given responses ======  " , responses
        set_user_project(project, user_project)
        requestes_responses = []
        url = "https://graph.facebook.com/v2.6/me/messages?access_token=#{page_access_token}"

        @body = {
            "messaging_type" => "response",
            "message" => {},
            "recipient" => {
                "id" => user_psid
            }
        }
        button_or_generic_tem = responses.select{ |res| res[:title] || res[:button_type]}

        responses.each_with_index do |response, index|
            if response.keys.length == 1 and response[:text]
                @body["message"] = self.get_text_message(response[:text])
            elsif response.keys.length == 1 and (response[:image] or response[:video])
                @body["message"] = self.get_media_message(page_access_token, response)
            elsif response[:list_url] || response[:list_template]
                @body["message"] = self.get_list!(response[:list_url], response[:list_template], response[:list_url_headers] || {})
            end
            @body["persona_id"] = persona_id if persona_id
            requestes_responses << APICalls.postRequest(url, nil, @body.to_json) if index != responses.length - 1
        end

        if button_or_generic_tem.count > 0
          if button_or_generic_tem.find{ |res| res[:title] }.nil?
            @body["message"] = self.button_template(button_or_generic_tem)
          else 
            @body["message"] = self.generic_template(button_or_generic_tem)
          end
          requestes_responses << APICalls.postRequest(url, nil, @body.to_json)
        end

        self.send_options(page_access_token, variable, user_psid) if variable
        p " RESPONSE - @body.to_json ========== " , @body.to_json
        requestes_responses << APICalls.postRequest(url, nil, @body.to_json) if @body
        return requestes_responses
    end

    def self.send_options(page_access_token, variable, user_psid)
        p "in MessengerHelper in send_quick_reply", variable, variable.class, variable[:responses]
        p "in MessengerHelper in send_quick_reply", variable, variable.class, variable[:options]
        requestes_responses = []
        url = "https://graph.facebook.com/v2.6/me/messages?access_token=#{page_access_token}"
        response_attatchment = false

        variable[:options].each do |option|
            if (option.keys.length == 2  and option[:text]) or (option.keys.length == 1 and option[:text])
                self.add_quick_reply!(option[:text], option[:icon])
            else
                if response_attatchment
                    response_attatchment = false
                    requestes_responses << APICalls.postRequest(url, nil, @body.to_json)
                    @body["message"] = nil
                end
                self.generic_template(option)
            end
        end

        p " OPTIONS - @body.to_json ========== " , @body.to_json
    end

    def self.get_text_message(text)
        {
            "text" => text.gsub("\\n", "\n")
        }
    end

    def self.get_media_message(page_access_token, media_type)
        url = "https://graph.facebook.com/v2.6/me/message_attachments?access_token=#{page_access_token}"
        body = {
            "message" => {
                "attachment" => {
                    "type" => "image",
                    "payload" => {
                    "is_reusable" => true,
                    "url" => media_type.values[0]
                    }
                }
            }
        }
        p response = APICalls.postRequest(url, nil, body.to_json)
        parsed_response = JSON.parse(response.body)
        return {
            "attachment" =>  {
                "type" =>  "template",
                "payload" =>  {
                    "template_type" =>  "media",
                    "elements" =>  [
                        {
                            "media_type" =>  media_type.keys[0].upcase,
                            "attachment_id" =>  parsed_response["attachment_id"]
                        }
                    ]
                }
            }
        }

    end

    def self.add_quick_reply!(text, icon)
        p " in add_quick_reply with text == #{text} , icon = #{icon} and @body == #{@body}"
        # @body["message"] = [] if @body["message"].nil?
        @body["message"]["quick_replies"] = [] if @body["message"]["quick_replies"].nil?
        @body["message"]["quick_replies"] << {
            "content_type" => "text",
            "title" => text,
            "payload" => text
        }

        if icon
          @body["message"]["quick_replies"].last["payload"] = ''
          @body["message"]["quick_replies"].last["image_url"] = icon
        end
    end

    def self.get_list!(url, template, headers = {})
        if url
            elements = []
            uri = URI.parse(URI.encode(fix_response_text(url)))
            request = Net::HTTP::Get.new(uri)
            headers.keys.each{|k|
                request[k] = fix_response_text(headers[k])
            }
            request.content_type = "application/json"
            request["Cache-Control"] = "no-cache"
            req_options = {
                use_ssl: uri.scheme == "https",
            }
            response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
                http.request(request)
            end
            response = JSON.parse(response.body) rescue response.body
            response = [response] if response.is_a? Hash
            return unless response.is_a? Array
            response.each{|response|
                response.each{ |k,v|
                    response[k] = v.each_with_index.map{|v,index| [index.to_s, v]}.to_h if v.is_a?(Array)
                }
                elements << JSON.parse(fix_response_text(template, response))
            }
        else
            elements = fix_response_text(template)
        end

        return {
          "attachment" => {
            "type" => "template",
            "payload" => {
                "template_type" => "generic",
                "elements" => elements
            }
          }
        }
    end

    def self.generic_template(responses)
        card_response = responses.find{|res| res[:title]}
        button_response = responses.select{|res| res[:button_type]}
        @body["message"] = { 
            "attachment" => {
              "type" => "template",
              "payload" => {
                  "template_type" => "generic",
                  "elements" => [
                      {
                          "title" => card_response[:title],
                          "image_url" => card_response[:card_image],
                          "subtitle" => card_response[:sub_title]
                      }
                  ]
              }
            }
        }
        if button_response
          buttons = []
          button_response.each do |button|
            buttons << add_button(button)
          end
            @body["message"]["attachment"]["payload"]["elements"][0]["buttons"] = buttons
        end
      @body["message"]
    end

  def self.button_template(responses)
    buttons = []
    responses.each do |response|
      buttons << self.add_button(response)
    end
    return {"attachment" => {
        "type" => "template",
        "payload" => {
          "template_type" => "button",
          "text" => text = responses.find{ |res| res[:button_text]}[:button_text],
          "buttons" => buttons
        }
      }
    }
  end

  def self.add_button(response)
    button = {}
    button['type'] = response[:button_type]
    button['title'] = response[:button_title]
    response[:button_type] == 'web_url' ? button['url'] = response[:button_url] : button['payload'] = response[:button_payload]
    button
  end

    def self.account_link(page_access_token, user_psid)
        url = "https://graph.facebook.com/v2.6/me/messages?access_token=#{page_access_token}"
        body = {
            "attachment" => {
                "type" => "template",
                "payload" => {
                    "template_type" => "button",
                    "text" => "please login to link your facebook account to your optobot account",
                    "buttons" => [
                        {
                            "type" => "account_link",
                            "url" => "https://beta.optobot.ai/"
                        }
                    ]
                }
            }
        }
        p "response **************", APICalls.postRequest(url, nil, body.to_json)
    end

    def self.account_linking_callback(redirect_uri, authorization_code)
        url = "#{redirect_uri}&authorization_code=#{authorization_code}"
        response = APICalls.getRequest(url, nil)
        return response.code
    end

    def self.send_action(page_access_token, user_psid, sender_action)
        url = "https://graph.facebook.com/v2.6/me/messages?access_token=#{page_access_token}"
        body = {
            "recipient" => {
                "id" => user_psid
            },
            "sender_action" => sender_action
        }
        APICalls.postRequest(url, nil, body.to_json)
    end
end
