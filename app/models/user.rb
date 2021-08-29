class User < ActiveRecord::Base
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable
  include DeviseTokenAuth::Concerns::User

  has_many :user_projects
  has_many :admin_project, -> { where(role: [UserProject.roles[:admin], UserProject.roles[:author]]) }, class_name: "UserProject"
  has_many :projects, through: :admin_project

  def self.get_or_create_users(user_emails)
    return [] if user_emails&.empty?

    user_emails.map do |email|
      user = self.find_by_email(email)
      user || User.create!(email: email, uid: email, provider: "email")
    end
  end

  def self.create_anonymous_user
    anonymous_email = loop do
      random_email = "#{SecureRandom.hex(8)}@anonymous.an"
      break random_email unless self.exists?("email": random_email)
    end

    self.create!(email: anonymous_email, password: SecureRandom.hex(4))
  end
end
