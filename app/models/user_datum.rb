class UserDatum < ApplicationRecord
    belongs_to :user_project
    belongs_to :variable
    belongs_to :option, optional: true

    validates :value, presence: true, unless: :option_id
    validates :option_id, presence: true, unless: :value

end
