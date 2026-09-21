# frozen_string_literal: true

module Auth
  class Result
    include ActiveModel::Model

    attr_accessor :email, :name, :username, :email_valid,
                  :uid, :extra_data, :user, :access_token, :refresh_token,
                  :failed, :failed_reason
  end
end
