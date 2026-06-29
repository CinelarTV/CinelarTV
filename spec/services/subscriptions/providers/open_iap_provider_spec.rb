# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Subscriptions::Providers::OpenIapProvider, type: :service do
  let(:provider) { described_class.new }

  describe '#provider_key' do
    it 'returns open_iap' do
      expect(provider.provider_key).to eq('open_iap')
    end
  end

  describe '#create_subscription!' do
    let(:user) { create(:user) }

    context 'when purchase_token and product_id are provided' do
      before do
        allow(SiteSetting).to receive(:open_iap_api_key).and_return('test-api-key')
        allow(SiteSetting).to receive(:open_iap_base_url).and_return('https://kit.openiap.dev')
      end

      it 'raises ArgumentError when purchase_token is missing' do
        expect {
          provider.create_subscription!(user: user, product_id: 'test-product')
        }.to raise_error(ArgumentError, /purchase_token and product_id are required/)
      end

      it 'raises ArgumentError when product_id is missing' do
        expect {
          provider.create_subscription!(user: user, purchase_token: 'test-token')
        }.to raise_error(ArgumentError, /purchase_token and product_id are required/)
      end
    end
  end

  describe '#normalize_remote_for_update' do
    let(:subscription) { build(:user_subscription, provider: 'open_iap') }

    it 'maps ENTITLED to active' do
      remote = { 'isValid' => true, 'state' => 'ENTITLED' }
      result = provider.normalize_remote_for_update(subscription, remote)
      expect(result[:status]).to eq('active')
    end

    it 'maps CANCELED to cancelled' do
      remote = { 'isValid' => false, 'state' => 'CANCELED' }
      result = provider.normalize_remote_for_update(subscription, remote)
      expect(result[:status]).to eq('cancelled')
    end

    it 'maps EXPIRED to cancelled' do
      remote = { 'isValid' => false, 'state' => 'EXPIRED' }
      result = provider.normalize_remote_for_update(subscription, remote)
      expect(result[:status]).to eq('cancelled')
    end

    it 'maps PENDING to pending' do
      remote = { 'isValid' => false, 'state' => 'PENDING' }
      result = provider.normalize_remote_for_update(subscription, remote)
      expect(result[:status]).to eq('pending')
    end
  end
end
