# frozen_string_literal: true

# Idempotent sample data. Passwords here are throwaway development values and
# are never used outside `bin/rails db:seed`.
SAMPLE_USERS = [
  { email: 'ada.lovelace@example.com', password: 'Analytical1!' },
  { email: 'grace.hopper@example.com', password: 'Nanosecond2?' },
  { email: 'alan.turing@example.com', password: 'Enigma1942#' },
  { email: 'katherine.johnson@example.com', password: 'Trajectory3$' }
].freeze

SAMPLE_USERS.each do |attributes|
  User.find_or_create_by!(email: attributes[:email]) do |user|
    user.password = attributes[:password]
    user.password_confirmation = attributes[:password]
  end
end

puts "Seeded #{User.count} users."
