import { Controller } from "@hotwired/stimulus"

// Live signup feedback.
//
// Every rule it enforces arrives from the server in the `policy` value
// (serialised from PasswordPolicy), so the browser and the model can never
// disagree about what a valid password is. The server still validates
// everything: this is guidance, not a gate.
export default class extends Controller {
  static targets = [
    "email",
    "emailFeedback",
    "password",
    "passwordConfirmation",
    "confirmationFeedback",
    "rule"
  ]

  static values = { policy: Object }

  connect() {
    const policy = this.policyValue || {}
    this.feedback = policy.feedback || {}
    this.minLength = policy.minLength || 0
    this.maxLength = policy.maxLength || Infinity
    this.rules = (policy.rules || []).map((rule) => ({
      key: rule.key,
      regexp: new RegExp(rule.pattern)
    }))

    this.validatePassword()
    this.validateConfirmation()
  }

  validateEmail() {
    const value = this.emailTarget.value.trim()
    if (value === "") return this.clear(this.emailTarget, this.emailFeedbackTarget)

    const valid = /\S+@\S+\.\S+/.test(value)
    this.mark(this.emailTarget, valid)
    this.say(
      this.emailFeedbackTarget,
      valid,
      valid ? this.feedback.email_valid : this.feedback.email_invalid
    )
  }

  validatePassword() {
    const password = this.passwordTarget.value

    this.ruleTargets.forEach((element) => {
      element.classList.toggle("is-met", this.ruleMet(element.dataset.rule, password))
    })

    if (password === "") {
      this.clear(this.passwordTarget)
    } else {
      this.mark(this.passwordTarget, this.allRulesMet(password))
    }

    if (this.passwordConfirmationTarget.value !== "") this.validateConfirmation()
  }

  validateConfirmation() {
    const password = this.passwordTarget.value
    const confirmation = this.passwordConfirmationTarget.value

    if (confirmation === "") {
      return this.clear(this.passwordConfirmationTarget, this.confirmationFeedbackTarget)
    }

    const matches = password === confirmation
    this.mark(this.passwordConfirmationTarget, matches)
    this.say(
      this.confirmationFeedbackTarget,
      matches,
      matches ? this.feedback.confirmation_match : this.feedback.confirmation_mismatch
    )
  }

  ruleMet(key, password) {
    if (key === "length") {
      return password.length >= this.minLength && password.length <= this.maxLength
    }

    const rule = this.rules.find((candidate) => candidate.key === key)
    return rule ? rule.regexp.test(password) : false
  }

  allRulesMet(password) {
    return this.ruleTargets.every((element) => this.ruleMet(element.dataset.rule, password))
  }

  mark(field, valid) {
    field.classList.toggle("is-valid", valid)
    field.classList.toggle("is-invalid", !valid)
  }

  clear(field, feedback) {
    field.classList.remove("is-valid", "is-invalid")
    if (feedback) {
      feedback.textContent = ""
      feedback.className = "form-text"
    }
  }

  say(element, valid, message) {
    element.textContent = message || ""
    element.className = valid ? "form-text text-success" : "form-text text-danger"
  }
}
