# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ProfilesController, type: :request do
  let(:user) { create(:user) }

  before do
    sign_in user
  end

  describe 'PATCH /user/profiles/:id' do
    let(:profile) { create(:profile, user: user, name: 'OldName', avatar_id: 'coolCat') }

    it 'updates name and avatar with valid avatar_id' do
      patch "/user/profiles/#{profile.id}", params: { profile: { name: 'NewName', avatar_id: 'cuteCat' } }, as: :json

      expect(response).to have_http_status(:ok)
      parsed = JSON.parse(response.body)
      expect(parsed['profile']['name']).to eq 'NewName'
      expect(parsed['profile']['avatar_id']).to eq 'cuteCat'
      expect(profile.reload.name).to eq 'NewName'
    end

    it 'returns error for invalid avatar_id' do
      patch "/user/profiles/#{profile.id}", params: { profile: { avatar_id: 'invalid_avatar' } }, as: :json

      expect(response).to have_http_status(:unprocessable_entity)
      parsed = JSON.parse(response.body)
      expect(parsed['error'] || parsed['errors']).to be_present
    end
  end
end
