# frozen_string_literal: true

# The app loads no third-party script, style, font or image, so the policy can
# be as tight as `self`. Importmap's inline <script type="importmap"> and
# Turbo's injected progress-bar <style> are allowed through a per-request
# nonce, which both read from the csp_meta_tag in the layout.
Rails.application.configure do
  config.content_security_policy do |policy|
    policy.default_src     :self
    policy.base_uri        :self
    policy.connect_src     :self
    policy.font_src        :self
    policy.form_action     :self
    policy.frame_ancestors :none
    policy.img_src         :self, :data
    policy.object_src      :none
    policy.script_src      :self
    policy.style_src       :self
  end

  config.content_security_policy_nonce_generator = ->(_request) { SecureRandom.base64(16) }
  config.content_security_policy_nonce_directives = %w[script-src style-src]
end
