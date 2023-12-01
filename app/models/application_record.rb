# frozen_string_literal: true

# Base class for every model; holds the connection and any behaviour that is
# genuinely shared by all tables.
class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class
end
