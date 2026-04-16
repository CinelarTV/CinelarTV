# frozen_string_literal: true

class User < ApplicationRecord
  before_create :developer_email?
  after_create :create_main_profile
  rolify
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :trackable

  validates :username, presence: true, uniqueness: true, length: { minimum: 3, maximum: 20 }

  has_many :profiles, dependent: :destroy # Si se elimina un usuario, se eliminan sus perfiles
  has_many :user_subscriptions, dependent: :destroy
  has_many :subscription_payments, dependent: :destroy

  # Doorkeeper related

  has_many :access_grants,
           class_name: "Doorkeeper::AccessGrant",
           foreign_key: :resource_owner_id,
           dependent: :delete_all # or :destroy if you need callbacks

  has_many :access_tokens,
           class_name: "Doorkeeper::AccessToken",
           foreign_key: :resource_owner_id,
           dependent: :delete_all # or :destroy if you need callbacks

  has_many :device_grants,
           class_name: "Doorkeeper::DeviceAuthorizationGrant::DeviceGrant",
           foreign_key: :resource_owner_id,
           dependent: :delete_all # or :destroy if you need callbacks

  def is_subscribed?
    return true if has_role?(:admin)
    user_subscriptions.active.exists?
  end

  protected

  def developer_email?
    return false unless SiteSetting.developer_emails.present?

    allowed_emails = SiteSetting.developer_emails.split(",").map(&:strip)
    return false unless allowed_emails.include?(email)

    add_role(:admin) # Add admin role to the user
  end

  def create_main_profile
    main_profile_data = {
      user_id: id,
      name: username.upcase,
      profile_type: "OWNER",
      avatar_id: "coolCat", # Default avatar
    }
    Profile.create(main_profile_data)
  end
end
