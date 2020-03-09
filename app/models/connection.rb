class Connection < ApplicationRecord
  belongs_to :user_project
  enum connection_type: [:facebook]
end
