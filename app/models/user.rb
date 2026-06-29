# frozen_string_literal: true

class User < ApplicationRecord
  before_create :developer_email?
  after_create :create_main_profile
  rolify
  # Include default devise modules. Others available are:
  # :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :trackable, :confirmable

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
 
  belongs_to :suspended_by, class_name: "User", optional: true, foreign_key: "suspended_by_id"
  belongs_to :deactivated_by, class_name: "User", optional: true, foreign_key: "deactivated_by_id"

  # Account suspension/deactivation helpers
  def suspended?
    return false unless suspended
    suspended_until.nil? || suspended_until > Time.current
  end

  def suspended_indefinitely?
    suspended? && suspended_until.nil?
  end

  def suspended_temporary?
    suspended? && suspended_until.present? && suspended_until > Time.current
  end

  def deactivated?
    deactivated_at.present?
  end

  def suspend!(until_time = nil, reason = nil, by = nil)
    update!(suspended: true, suspended_until: until_time, suspended_reason: reason, suspended_by_id: by&.id)
    revoke_oauth_tokens!

    # Schedule automatic unsuspend if a temporary until_time is provided and Sidekiq is available
    if until_time.present?
      begin
        UnsuspendUserJob.perform_at(until_time, id) if defined?(UnsuspendUserJob)
      rescue StandardError => e
        Rails.logger.error("Failed to schedule UnsuspendUserJob for user #{id}: #{e.message}")
      end
    end
  end

  def unsuspend!
    update!(suspended: false, suspended_until: nil, suspended_reason: nil, suspended_by_id: nil)
  end

  def deactivate!(by = nil, reason = nil)
    update!(deactivated_at: Time.current, deactivated_reason: reason, deactivated_by_id: by&.id)
    revoke_oauth_tokens!
  end

  def activate!
    update!(deactivated_at: nil, deactivated_reason: nil, deactivated_by_id: nil)
  end

  def revoke_oauth_tokens!
    return unless respond_to?(:access_tokens) && access_tokens.any?
    access_tokens.update_all(revoked_at: Time.current)
  end

  # Devise integration: block authentication for suspended/deactivated users
  def active_for_authentication?
    super && !deactivated? && !suspended?
  end

  def inactive_message
    return :account_deactivated if deactivated?
    return :account_suspended if suspended?
    super
  end

  def is_subscribed?
    return true if has_role?(:admin)
    user_subscriptions.active.exists?
  end

  protected

  def developer_email?
    return false unless SiteSetting.developer_emails.present?

    allowed_emails = SiteSetting.developer_emails.split(",").map(&:strip)
    return false unless allowed_emails.include?(email)

    skip_confirmation!
    add_role(:admin)
  end

  def create_main_profile
    main_profile_data = {
      user_id: id,
      name: username.upcase,
      profile_type: "OWNER",
      avatar_id: "dino", # Default avatar
    }
    Profile.create(main_profile_data)
  end
end
