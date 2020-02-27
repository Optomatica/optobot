class UserMailer < ApplicationMailer
    def invitation_to_chatbot(user, sender, url)
        mail(to: user[:email], from: sender.email, subject: "invitation to a chatbot", content_type: "text/html",
            body: "#{sender.name} is inviting you to be a #{user[:role]} in his/her chatbot. This is the project link. Please copy and paste it in your browser: '#{url}'.\n It will be great to see you there.\nBest regards,\n#{sender.name}.")
    end

    def problem_in_chatbot(users_emails, problem_type)
        users_emails.each do |user_email|
            mail(to: user_email, from: "optobot@example.com", subject: "problem in your chatbot", content_type: "text/html",
                body: "Your chatbot is facing a problem understanding one of your subscribers.\n Problem type: #{problem_type}")
        end
    end
end
