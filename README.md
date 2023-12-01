# Bark Test Assessment

This project is a simple web application built with Ruby on Rails. It uses PostgreSQL as its database.

In this app I am adding all necessary validations for user Password field. I have added these validations on both the Front-end and the Back-end. For backed the validations are added in the User Model. On Front-end I have used stimulus controller to validate the password filed on form submission.

## Features

- User: Represents a user with 2 fields email and password.
- View User: After the successful creation of user the app takes to the landing page.
- Add User: Any one can add a New Valid User.
- Email Validation:
  1. Email must be unique and must be valid(e.g. test@example.com).
- Password Validations:
  1. Password length validation
  2. Password must have at least one lowercase letter
  3. Password must have at least one uppercase letter
  4. Password must have at least one special letter
  5. Password must have at least one digit
- Password Confirmation:
  1. Confirmation must match the entered password

## Demo
[Watch Demo on Loom](https://www.loom.com/share/ac0143adcf5c40cf9abdcdfec903aaab?sid=a92783df-706d-4618-bb6d-a6f6570f6f2f)

# Build With

- Framework: Ruby on Rails 7.0, Hotwire Stimulus
- Database: PostgreSQL

# Getting Started

## Prerequisites

- ruby

  ```bash
  rvm install 3.2.2
  ```

## Installation

1. **Clone the Repository**:
   ```bash
   git clone [<repository-url>](https://github.com/Chsaleem31/bark-test-challenge.git)
   cd repo
   ```

2. **Initialize the Database**:
   - Before starting the application for the first time, ensure that the database is set up correctly.
   ```bash
   rails db:create db:migrate
   ```
3. **Bundeling Application**:
   ```bash
   bundle install
   ```

3. **Compiling assets**:
   ```bash
   rake assets:precompile
   ```

4. **Starting Server**:
   - Now run the application with
   ```bash
   rails server
   ```

## Run Tests

```bash
    rpsec
```
