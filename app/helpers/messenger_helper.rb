include APICalls

module MessengerHelper

    def self.send_responses(page_access_token, responses, user_psid, variable) # type:, value:
        p "in MessengerHelper in send_message  given responses ======  " , responses
        requestes_responses = []
        url = "https://graph.facebook.com/v2.6/me/messages?access_token=#{page_access_token}"
        @body = {
            "messaging_type" => "response",
            "message" => {},
            "recipient" => {
                "id" => user_psid
            }
        }

        responses.each_with_index do |response, index|
          if response.keys.length == 1 and response[:text]
              @body["message"] = self.add_text_message(response[:text])
          elsif response.keys.length == 1 and response[:image] or response[:video]
              @body["message"] = self.add_media_message(page_access_token, response)
          elsif response.keys.length > 1 and response[:text] or response[:image] or response[:video]
              self.add_card!(response[:text], response[:title], response[:image], response[:button])
              next
          end
          requestes_responses << APICalls.postRequest(url, nil, @body.to_json) if index != responses.length - 1
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
                self.add_card!(option[:text], option[:title], option[:image], option[:button])
            end
        end

        p " OPTIONS - @body.to_json ========== " , @body.to_json
    end

    def self.add_text_message(text)
        {
            "text" => text
        }
    end

    def self.add_media_message(page_access_token, media_type, attachment_url)
        url = "https://graph.facebook.com/v2.6/me/message_attachments?access_token=#{page_access_token}"
        body = {
            "message" => {
                "attachment" => {
                    "type" => "image",
                    "payload" => {
                    "is_reusable" => true,
                    "url" => attachment_url
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
                            "media_type" =>  media_type,
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


    def self.add_card!(text, title, image, button)
        p "in add_card with text == #{text} ,title == #{title} , image == #{image} , and button == #{button}"
        if title.nil?
            title = text
        end
        if text.length > 20
            subtitle = text
        end

        # @body["message"] = {
        #     "text" => text
        # }


        if @body["message"]["attachment"].nil?
            @body["message"]["attachment"] = {
                "type" => "template",
                "payload" => {
                    "template_type" => "generic",
                    "elements" => [
                        {
                            "title" => title,
                            "image_url" => image,
                            "subtitle" => subtitle
                        }
                    ]
                }
            }
        else
            @body["message"]["attachment"]["payload"]["elements"] << {
                "title" => title,
                "image_url" => image,
                "subtitle" => subtitle
            }
        end
        if button
            @body["message"]["attachment"]["payload"]["elements"][0]["buttons"] = [
                {
                    "type" => "postback",
                    "title" => button,
                    "payload" => text
                }
            ]
        end
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
                            "url" => ENV['ACCOUNT_LINK_URL']
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
