# frozen_string_literal: true

class User < ApplicationRecord
  SYSTEM_USER_UUID = "00000000-0000-0000-0000-000000000000"

  before_create :developer_email?
  after_create :create_main_profile, unless: :system_user?
  after_commit :clear_user_cache
  rolify
  # Include default devise modules. Others available are:
  # :lockable, :timeoutable, :trackable and :omniauthable
  # NOTE: :omniauthable is intentionally excluded — OmniAuth strategies are
  # managed dynamically by Middleware::OmniauthBypassMiddleware, which builds
  # the provider stack at request time from Auth::Registry.  Leaving
  # :omniauthable here causes Devise to insert its own (empty) OmniAuth::Builder
  # into the Rack stack, which intercepts /auth/* before our middleware can and
  # then falls through to the Rails router, producing a RoutingError.
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :trackable, :confirmable

  validates :username, presence: true, uniqueness: true, length: { minimum: 3, maximum: 20 }, unless: :system_user?
  validate :validate_username_format, unless: :system_user?

  # --- System User ---
  def self.system_user
    find_by(id: SYSTEM_USER_UUID)
  end

  def self.ensure_system_user!
    find_or_create_by!(id: SYSTEM_USER_UUID) do |u|
      u.email = "system@cinelartv.local"
      u.username = "system"
      u.password = SecureRandom.hex(32)
      u.confirmed_at = Time.current
    end.tap do |u|
      u.add_role(:admin) unless u.has_role?(:admin)
    end
  end

  def system_user?
    id == SYSTEM_USER_UUID
  end

  def validate_username_format
    UsernameValidator.perform_validation(self, :username)
  end

  has_many :profiles, dependent: :destroy # Si se elimina un usuario, se eliminan sus perfiles
  has_many :oauth_identities, dependent: :destroy
  has_many :subscriptions, dependent: :destroy
  has_many :payments, dependent: :destroy
  has_many :subscription_access_grants, dependent: :destroy

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
    return unless until_time.present?

    begin
      UnsuspendUserJob.perform_at(until_time, id) if defined?(UnsuspendUserJob)
    rescue StandardError => e
      Rails.logger.error("Failed to schedule UnsuspendUserJob for user #{id}: #{e.message}")
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

  # Confirmation deadline helpers (7-day window from confirmation_sent_at)
  CONFIRMATION_PERIOD = 7.days

  def confirmation_deadline
    return nil if confirmed?
    return nil unless confirmation_sent_at

    confirmation_sent_at + CONFIRMATION_PERIOD
  end

  def days_until_confirmation_deadline
    return nil if confirmed?

    deadline = confirmation_deadline
    return nil unless deadline

    [(deadline.to_date - Date.current).to_i, 0].max
  end

  def confirmation_expired?
    return false if confirmed?

    deadline = confirmation_deadline
    return false unless deadline

    deadline < Time.current
  end

  def is_subscribed?
    return true if is_admin?

    CinelarTV.cache.fetch("user_subscribed/#{id}", expires_in: 1.hour) do
      Billing::AccessPolicy.active?(self)
    end
  end

  def is_admin?
    CinelarTV.cache.fetch("user_admin/#{id}", expires_in: 5.minutes) do
      has_role?(:admin)
    end
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

  def clear_user_cache
    CinelarTV.cache.delete("user/#{id}")
    CinelarTV.cache.delete("user_admin/#{id}")
    CinelarTV.cache.delete("user_subscribed/#{id}")
  end
end
