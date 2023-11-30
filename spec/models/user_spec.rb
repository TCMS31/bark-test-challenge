# frozen_string_literal: true

require 'rails_helper'

RSpec.describe User, type: :model do
  subject { build(:user) }

  it { is_expected.to validate_presence_of(:email) }
  # `ignoring_case_sensitivity` because `normalizes` folds the address before
  # it is compared; the case-insensitive behaviour is asserted explicitly below.
  it { is_expected.to validate_uniqueness_of(:email).ignoring_case_sensitivity }
  it { is_expected.to allow_value('user@example.com').for(:email) }
  it { is_expected.not_to allow_value('invalid_email').for(:email) }

  it { is_expected.to validate_presence_of(:password) }
  it { is_expected.to validate_length_of(:password).is_at_least(PasswordPolicy::MIN_LENGTH) }
  it { is_expected.to validate_length_of(:password).is_at_most(PasswordPolicy::MAX_LENGTH) }
  it { is_expected.to validate_confirmation_of(:password) }

  describe 'email normalisation' do
    it 'stores the address folded to lower case' do
      user = create(:user, email: '  Ada.Lovelace@Example.COM ')
      expect(user.email).to eq('ada.lovelace@example.com')
    end

    it 'treats a differently cased address as a duplicate' do
      create(:user, email: 'ada@example.com')
      duplicate = build(:user, email: 'ADA@Example.com')

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:email]).to include('has already been taken')
    end

    it 'is backed by a unique index, so the database rejects a duplicate that slips past validation' do
      create(:user, email: 'ada@example.com')
      duplicate = build(:user, email: 'ada@example.com')

      expect { duplicate.save!(validate: false) }
        .to raise_error(ActiveRecord::RecordNotUnique)
    end
  end

  describe 'password format' do
    it 'reports a readable message for a missing digit' do
      user = build(:user, password: 'Password!', password_confirmation: 'Password!')

      expect(user).not_to be_valid
      expect(user.errors.full_messages)
        .to include('Password must include at least one digit')
    end

    it 'is invalid without an uppercase letter' do
      user = build(:user, password: 'password1!', password_confirmation: 'password1!')
      expect(user).not_to be_valid
    end

    it 'is invalid without a lowercase letter' do
      user = build(:user, password: 'PASSWORD1!', password_confirmation: 'PASSWORD1!')
      expect(user).not_to be_valid
    end

    it 'is invalid without a special character' do
      user = build(:user, password: 'Password1', password_confirmation: 'Password1')
      expect(user).not_to be_valid
    end

    it 'lists every unmet rule rather than only the first' do
      user = build(:user, password: 'aaaaaaaa', password_confirmation: 'aaaaaaaa')
      user.valid?

      expect(user.errors[:password]).to match_array(PasswordPolicy::RULES.reject do |rule|
        rule.key == :lowercase
      end.map(&:message))
    end

    it 'delegates to PasswordPolicy rather than repeating the rules' do
      allow(PasswordPolicy).to receive(:violations).and_return([])

      build(:user, password: 'anything', password_confirmation: 'anything').valid?

      expect(PasswordPolicy).to have_received(:violations).with('anything')
    end
  end

  describe 'password confirmation' do
    it 'is required when a password is given' do
      user = build(:user, password_confirmation: nil)

      expect(user).not_to be_valid
      expect(user.errors[:password_confirmation]).to include("can't be blank")
    end

    it 'must match the password' do
      user = build(:user, password: 'Correct1!', password_confirmation: 'Different1!')
      expect(user).not_to be_valid
    end
  end

  describe 'storage' do
    it 'never persists the plaintext password' do
      user = create(:user, password: 'Analytical1!', password_confirmation: 'Analytical1!')

      expect(user.password_digest).to be_present
      expect(user.password_digest).not_to include('Analytical1!')
      expect(user.reload.authenticate('Analytical1!')).to eq(user)
    end
  end
end
