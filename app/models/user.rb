class User < ActiveRecord::Base
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable
  include DeviseTokenAuth::Concerns::User

  has_many :user_projects
  has_many :projects, through: :user_projects

  def self.get_or_create_users(user_emails)
    return [] if user_emails&.empty?

    user_emails.map do |email|
      user = self.find_by_email(email)
      user || User.create!(email: email, uid: email, provider: "project")
    end
  end

  def self.create_anonymous_user
    anonymous_email = loop do
      random_email = "#{SecureRandom.hex(8)}@anonymous.an"
      break random_email unless self.exists?("email": random_email)
    end

    self.create!(email: anonymous_email, password: SecureRandom.hex(4))
  end

  private

  def password_required?
    super if self.provider != 'project'
  end
end
