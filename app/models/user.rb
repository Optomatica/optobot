class User < ActiveRecord::Base
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable
  include DeviseTokenAuth::Concerns::User

  has_many :user_projects
  has_many :projects, through: :user_projects

  def self.get_or_create_users(user_emails)
    return [] if user_emails.nil?

    users = []
    user_emails.each do |email|
      user = self.find_by_email(email)
      if user.nil?
        user = User.create!(email: email, uid: email, provider: "project")
      end
      users.push(user)
    end

    users
  end

  def self.create_anonymous_user
    anonymous_email = loop do
      random_email = "#{SecureRandom.hex(8)}@anonymous.an"
      break random_email unless self.exists?("email": random_email)
    end
    password = SecureRandom.hex(4)

    self.create!(email: anonymous_email, password: password)
  end

  def create_wit_app(token, app_name)
    uri = URI.parse('https://api.wit.ai/apps?v=20170307')

    request = Net::HTTP::Post.new(uri)
    request.content_type = 'application/json'
    request['Authorization'] = "Bearer #{token}"
    request.body = JSON.dump('name' => app_name, 'lang' => 'en',
                             'private' => 'true')
    req_options = { use_ssl: uri.scheme == 'https' }

    Net::HTTP.start(uri.hostname, uri.port, req_options) { |h| h.request(request) }
  end

  private

  def password_required?
    super if self.provider != 'project'
  end
end
