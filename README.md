# Signup form with one shared password policy

One screen, one form. You give it an email address and a password, it checks the
password against a published policy in the browser *and* again in the model, and
it writes a `User` row holding a bcrypt digest. That is the entire application:
no session, no login, no account management. It is a take-home exercise and it
deliberately does one thing.

Rails 8.1 on Ruby 3.4.12 and PostgreSQL, with Hotwire (Turbo and Stimulus)
served through importmap and Bootstrap compiled by Sprockets.

## The form

| Live checklist as you type | A rejected submission comes back with its errors |
| --- | --- |
| ![Signup form with all five password rules ticked green and both fields marked valid](docs/screenshots/01-signup-live-validation.png) | ![Signup form re-rendered with a red panel listing two problems: email taken and a missing digit](docs/screenshots/02-signup-server-errors.png) |

| Confirmation after a successful signup | Unknown `/users/:id` |
| --- | --- |
| ![Confirmation card showing the new account's email address and registration time](docs/screenshots/03-account-created.png) | ![Error 404 card reading "Page not found" with a link back to signup](docs/screenshots/04-not-found.png) |

| Phone, live checklist | Phone, rejected submission |
| --- | --- |
| <img src="docs/screenshots/05-mobile-live-validation.png" width="260" alt="The signup form at phone width with every rule met"> | <img src="docs/screenshots/06-mobile-server-errors.png" width="260" alt="The signup form at phone width with the email and password fields outlined in red"> |

Captured with Playwright (1440x900 and 390x844) against the Docker Compose stack
below. The "email has already been taken" error is against one of the sample
accounts that `db:prepare` seeds into a fresh database.

## Accessibility

- A rejected submission marks each failing field with Bootstrap's `is-invalid`
  and `aria-invalid="true"` as well as listing the errors in a `role="alert"`
  panel. Rails' default `field_with_errors` wrapper is turned off in
  `config/application.rb` because Bootstrap does not style it.
- Each item of the live password checklist carries visually hidden "(met)" /
  "(not met yet)" text that the Stimulus controller keeps current, so the state
  is not conveyed by colour alone. The email and confirmation hints are polite
  live regions.
- Every text colour in `app/assets/stylesheets/_palette.scss` (pine on warm
  paper) clears 4.5:1, and focus gets a visible outline.

## One place where the password rules live

The only structurally interesting thing here is that a signup form has *two*
places that must agree about what a strong password is, and this one has a
single definition feeding both.

[`app/models/password_policy.rb`](app/models/password_policy.rb) holds the rules
as data — a list of `{key, pattern}` structs plus `MIN_LENGTH` (8) and
`MAX_LENGTH` (72, because bcrypt silently truncates anything past 72 bytes and
accepting a password whose tail is ignored is worse than rejecting it).

From there the same list reaches both enforcement points:

- **Server.** `PasswordFormatValidator` is an `ActiveModel::EachValidator`, so
  `User` just declares `validates :password, password_format: true`. Length
  stays on Rails' built-in `length` validator, which keeps the standard
  `:too_short` / `:too_long` error types working for the shoulda matchers.
- **Browser.** `PasswordPolicy.as_json` is rendered into the form as a Stimulus
  value (`data-user-policy-value`), and `user_controller.js` does
  `new RegExp(rule.pattern)` on the exact `Regexp#source` the server validated
  with. The client is guidance, not a gate — every rule is checked again
  server-side.

That second path only holds while the patterns stay portable, so
`spec/models/password_policy_spec.rb` asserts that no rule uses lookbehind, a
POSIX bracket class, a Ruby-only anchor or a regexp option, none of which
survive the `.source` round trip into JavaScript.

Adding a rule is one entry in `RULES` and two lines in `config/locales/en.yml`.
Whitespace deliberately does not count as a special character (`[^A-Za-z0-9\s]`),
and a spec pins that.

## A signup, end to end

```mermaid
sequenceDiagram
    actor Visitor
    participant JS as user_controller.js
    participant C as UsersController
    participant U as User
    participant P as PasswordPolicy
    participant DB as PostgreSQL

    Visitor->>JS: types a password
    JS->>JS: test each embedded rule
    JS-->>Visitor: checklist turns green, no request sent

    Visitor->>C: POST /users
    C->>U: User.new(email, password, confirmation)
    U->>U: strip and downcase the email
    U->>P: violations(password)
    P-->>U: unmet rules

    alt everything valid
        U->>DB: INSERT with bcrypt digest
        DB-->>U: id
        C-->>Visitor: 302 to /users/:id
    else validation failed
        C-->>Visitor: 422 with the form and its errors
    else address claimed between the check and the insert
        DB-->>U: unique index violation
        C-->>Visitor: 422 with "Email has already been taken"
    end
```

The last branch is the one worth noticing: `validates :uniqueness` issues a
`SELECT` that two concurrent signups can both pass, so the unique index on
`email` is what actually decides. `create` rescues `ActiveRecord::RecordNotUnique`
and renders it as an ordinary form error rather than letting it surface as a 500.
Email is normalised on assignment rather than compared with
`case_sensitive: false`, which would emit `LOWER(email) = LOWER($1)` and could
not use that index.

## Running it

With Docker, nothing else needed:

```bash
cp .env.example .env
echo "SECRET_KEY_BASE=$(openssl rand -hex 64)" >> .env
docker compose up --build   # http://localhost:8570
```

This builds the production image (Ruby 3.4.12 slim, assets precompiled, runs
as an unprivileged user), starts PostgreSQL 16 and runs `db:prepare`, which on
a fresh database also loads the four sample accounts from `db/seeds.rb`. The
container reports healthy once `/up` answers. `docker compose down -v` removes
the stack and its database volume.

Without Docker you need Ruby 3.4.12 (see `.ruby-version`) and a PostgreSQL
server:

```bash
bin/setup          # bundle install, copy .env.example, create and seed the database
bin/rails server   # http://localhost:3000
```

`bin/rails db:seed` is idempotent and re-adds the four sample accounts to an
existing database.

## Environment variables

Everything is read from the environment and `config/database.yml` carries no
literal credentials. `DATABASE_URL`, if set, overrides the individual database
variables. Note that the Rails process itself does not load `.env` (there is no
`dotenv` gem); `bin/setup` writes it for you, and `docker compose` is what reads
it.

| Variable | Required | Default | Purpose |
| --- | --- | --- | --- |
| `DATABASE_HOST` | no | `localhost` | PostgreSQL host |
| `DATABASE_PORT` | no | `5432` | PostgreSQL port |
| `DATABASE_USER` | no | unset (local socket user) | PostgreSQL role |
| `DATABASE_PASSWORD` | no | unset | Password for that role |
| `DATABASE_NAME` | no | `bark_test_challenge_development` | Database in development and production |
| `TEST_DATABASE_NAME` | no | `bark_test_challenge_test` | Database used by the suite |
| `DATABASE_URL` | no | unset | Full connection URL, overriding the five above |
| `RAILS_MAX_THREADS` | no | `5` | Puma threads *and* the Active Record pool size, so the pool can never be smaller than the threads competing for it |
| `RAILS_LOG_LEVEL` | no | `info` | Production log level |
| `FORCE_SSL` | no | `true` | Set to `false` when TLS is terminated upstream or when running over plain HTTP |
| `SECRET_KEY_BASE` | in production | none | Cookie and signed-message key, from `bin/rails secret` |
| `REDIS_URL` | no | `redis://localhost:6379/1` | Action Cable adapter in production only |

## The suite

```
$ bundle exec rspec
60 examples, 0 failures

$ bundle exec rubocop
35 files inspected, no offenses detected
```

A PostgreSQL server has to be reachable — point the suite at one with
`DATABASE_HOST` / `DATABASE_PORT` or `DATABASE_URL`. bcrypt runs at its minimum
cost factor in the test environment, so the full run takes a couple of seconds.
Examples run in random order; rerun a failing order with `--seed`.

The spec files are layered on purpose:

- `spec/models/password_policy_spec.rb` — the rules themselves, plus the
  JavaScript-portability guard described above.
- `spec/models/user_spec.rb` — validations, email normalisation, and that the
  unique index is a real backstop rather than a comment.
- `spec/requests/users_spec.rb` — real templates rendered. This is the layer
  that pins the status codes: 422 on a rejected form so Turbo replaces the page,
  400 when the `user` params key is missing or is not a hash, 422 on a lost
  uniqueness race, and 404 for an unknown id.
- `spec/controllers/users_controller_spec.rb` — assignment and template choice.
- `spec/system/signup_spec.rb` — the form as rendered, filled in and submitted
  through Capybara's `rack_test` driver: the happy path, rejected fields and
  their `aria-invalid` marks, a duplicate address in a different case, and the
  rule list.

Controller specs do not render views, which is exactly how a re-rendered form
that raises can hide behind a green suite; that is why the request specs exist.

## Choices worth a reviewer's time

**Only the railties this app uses.** `config/application.rb` requires Active
Record, Action Controller, Action View, Active Job and Action Cable by name
instead of `rails/all`. Active Storage, Action Mailbox, Action Text and Action
Mailer are not referenced anywhere, so they are not loaded — one less pile of
configuration to keep correct. Action Cable stays because Turbo depends on it,
and its development adapter is `async`, so no Redis server is needed to run the
app locally.

**Errors are handled where the template is.** `ExceptionHandler` carries only the
genuinely app-wide case (`RecordNotFound` → a 404 page). `ParameterMissing`
recovery lives in `UsersController`, because re-rendering `users/new` is that
controller's business and a shared concern should not need to know which views
exist where.

**Nothing is fetched from a third party.** No CDN script, style, font or image;
Bootstrap is compiled from the gem and headings use a local serif stack, so the
page renders identically offline. That lets the content security policy be
`self` throughout, with a per-request nonce for importmap's inline
`<script type="importmap">` and Turbo's injected progress bar.

**Scale, honestly.** One table, one insert, one primary-key lookup. There is no
N+1 to fix and no page that grows with the data — the only per-request query
beyond the insert is the uniqueness `SELECT`, which the unique index already
serves. What would actually matter under load is the connection pool, which is
why it is sized from the same `RAILS_MAX_THREADS` Puma uses. Adding pagination
or a `created_at` index today would be decoration.

## Out of scope

- **No authentication.** `/users/:id` is a sequential id, so anyone who knows one
  can read that account's email address. A real product would render the
  confirmation from a session rather than a guessable URL.
- No password reset, email verification, rate limiting or lockout.
- Composition rules are weak protection on their own. A real system should also
  check the password against a breach corpus, such as Have I Been Pwned's range
  API.
- `config/credentials.yml.enc` is committed without its key, so it cannot be
  decrypted from a clone. Production reads `SECRET_KEY_BASE` from the
  environment instead.
- The system spec runs without JavaScript, so the live checklist itself is only
  exercised by hand and by the screenshot run. A JavaScript-driven system spec
  would need a headless browser in the test environment.
- Styles go through `sassc-rails`, whose libsass engine is no longer developed.
  Bootstrap 5.3 still compiles cleanly with it; moving to Dart Sass is the next
  step if Bootstrap stops supporting libsass.

## License

MIT, see [LICENSE](LICENSE).
