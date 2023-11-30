# frozen_string_literal: true

# Cross-cutting error handling. Only genuinely application-wide failures belong
# here; a controller that needs to recover into one of its own templates should
# rescue locally (see UsersController) so this concern never has to know which
# views exist where.
module ExceptionHandler
  extend ActiveSupport::Concern

  included do
    rescue_from ActiveRecord::RecordNotFound do
      render 'shared/not_found', status: :not_found
    end
  end
end
