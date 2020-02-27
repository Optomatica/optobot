require 'rails_helper'
require 'rspec_api_documentation'
require 'rspec_api_documentation/dsl'

RspecApiDocumentation.configure do |config|
  config.format = :json
  config.curl_host = 'http://localhost:3000'
  config.api_name = "OptoBot API"

  config.request_headers_to_include = ["Host", "Content-Type"]
  config.response_headers_to_include = ["Host", "Content-Type"]
  config.keep_source_order = true
  #config.curl_headers_to_filter = ["Authorization"] # Remove this if you want to show Auth headers in request

#   config.define_group :cdn do |config|
#     config.docs_dir = Rails.root.join("public", "assets", "api", "cdn")
#     config.filter = :cdn
#   end

#   config.define_group :management do |config|
#     config.docs_dir = Rails.root.join("public", "assets", "api", "management")
#     config.filter = :management
#   end
# end



# #   config.format = [:open_api, :html]
# #   config.api_name = "Example App API"
# #   config.api_explanation = "API Example Description"
end


