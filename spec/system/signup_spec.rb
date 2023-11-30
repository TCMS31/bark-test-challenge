# frozen_string_literal: true

require 'rails_helper'

# The whole flow through real HTML, without a browser: rack_test submits the
# form exactly as rendered, so a renamed field or a broken template fails here
# even though the request specs post their own params.
RSpec.describe 'Signing up' do
  before { driven_by(:rack_test) }

  def fill_in_signup(email:, password:, confirmation: password)
    visit root_path
    fill_in 'Email address', with: email
    fill_in 'Password', with: password
    fill_in 'Confirm password', with: confirmation
    click_on 'Create account'
  end

  it 'creates the account and shows its confirmation' do
    fill_in_signup(email: 'Grace.Hopper@Example.com', password: 'Nanosecond2?')

    expect(page).to have_css('h1', text: 'You are registered')
    expect(page).to have_text('grace.hopper@example.com')
    expect(page).to have_css('[role="status"]', text: 'Your account was created.')
  end

  it 'keeps the visitor on the form and flags each rejected field' do
    fill_in_signup(email: 'not-an-email', password: 'weakpass', confirmation: 'different')

    expect(page).to have_css('[role="alert"]', text: 'stopped this account from being created')
    expect(page).to have_field('Email address', with: 'not-an-email', class: 'is-invalid')
    expect(page).to have_css('#user_password.is-invalid[aria-invalid="true"]')
  end

  it 'leaves the Bootstrap markup of a rejected field unwrapped' do
    fill_in_signup(email: '', password: '')

    expect(page).to have_css('#user_email.is-invalid')
    expect(page).to have_no_css('.field_with_errors')
  end

  it 'reports an address that is already registered, whatever its case' do
    create(:user, email: 'ada@example.com')

    fill_in_signup(email: 'ADA@example.com', password: 'Analytical1!')

    expect(page).to have_text('Email has already been taken')
  end

  it 'lists every password rule with a screen-reader state' do
    visit root_path

    within('#password-rules') do
      expect(page).to have_css('li.password-rule', count: PasswordPolicy::RULES.size + 1)
      expect(page).to have_css('[data-rule-state]', text: '(not met yet)', visible: :all,
                                                    count: PasswordPolicy::RULES.size + 1)
    end
  end
end
