# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Subscriptions::Providers::GooglePlayProvider, type: :service do
  let(:provider) { described_class.new }

  describe '#verify_webhook!' do
    it 'returns true when verification token matches' do
      allow(SiteSetting).to receive(:google_play_pubsub_verification_token).and_return('secret-token')
      req = double(headers: { 'X-Play-Verification-Token' => 'secret-token' })

      expect(provider.verify_webhook!(req)).to be true
    end
  end
end
