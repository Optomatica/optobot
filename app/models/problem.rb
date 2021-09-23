class Problem < ApplicationRecord
  enum problem_type: [:do_not_understand, :technical_problem,
                      :no_route_matching, :fallback_limit_exceeded, :not_allowed_value,
                      :provided_data_missing, :warning, :multiple_intent_in_same_context]

  belongs_to :project
  belongs_to :chatbot_message
end
