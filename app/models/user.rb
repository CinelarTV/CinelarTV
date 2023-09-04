# frozen_string_literal: true

class User < ApplicationRecord
  before_create :has_developer_email?
  after_create :create_main_profile
  rolify
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  validates :username, presence: true, uniqueness: true, length: { minimum: 3, maximum: 20 }

  has_many :profiles, dependent: :destroy # Si se elimina un usuario, se eliminan sus perfiles

  protected

  def has_developer_email?
    if SiteSetting.developer_emails.present?
      allowed_emails = SiteSetting.developer_emails.split(",").map(&:strip)
      if allowed_emails.include?(email)
        add_role(:admin) # Add admin role to the user
      end
    end
  end

  def create_main_profile
    main_profile_data = {
      user_id: self.id,
      name: self.username.upcase,
      profile_type: "OWNER",
      avatar_id: "coolCat", # Default avatar
    }
    Profile.create(main_profile_data)
  end
end
