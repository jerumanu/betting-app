# Value8 Bets

A sports betting platform built with Phoenix LiveView and Elixir.

## Features

### User Features
- User registration and authentication
- View available sports games
- Place bets on games
- View betting history
- Real-time updates on game scores and bet status

### Admin Features
- View all users and their betting history
- Soft delete users and their associated data
- Track profits from game losses
- View betting statistics and analytics

### Superuser Features
- Configure and manage sport games
- Grant/revoke admin access to users
- Manage user roles and permissions

## Prerequisites

- Elixir 1.14 or later
- Phoenix 1.7.x
- PostgreSQL 12 or later

## Database Setup


1. Configure database credentials:
   Create/update `config/dev.exs`:
```elixir
config :value8_bets, Value8Bets.Repo,
  username: "value8_bets",
  password: "your_password",
  hostname: "localhost",
  database: "value8_bets_dev",
  stacktrace: true,
  show_sensitive_data_on_connection_error: true,
  pool_size: 10
```

1. Create and migrate database:
```bash
# Create database
mix ecto.create

# Run migrations
mix ecto.migrate

# Optional: Seed database with initial data
mix run priv/repo/seeds.exs
```

## Application Setup

1. Clone the repository:
```bash
git clone https://github.com/yourusername/value8_bets.git
cd value8_bets
```

2. Install dependencies:
```bash
mix deps.get
mix deps.compile
```

3. Start the Phoenix server:
```bash
mix phx.server
```

4. Visit [`localhost:4000`](http://localhost:4000) to access the application.

## Initial Setup

1. Create a superuser account:
```bash
# Register a new user
curl -X POST http://localhost:4000/api/users/register \
  -H "Content-Type: application/json" \
  -d '{
    "user": {
      "email": "superuser@example.com",
      "password": "SuperUser123!@#",
      "role": "superuser"
    }
  }'
```

2. Login as superuser:
```bash
curl -X POST http://localhost:4000/api/users/login \
  -H "Content-Type: application/json" \
  -d '{
    "user": {
      "email": "superuser@example.com",
      "password": "SuperUser123!@#"
    }
  }'
```

3. Save the returned token for admin operations.

## API Endpoints

### Authentication Routes

```bash
# User Registration
POST /api/users/register
Content-Type: application/json
{
  "user": {
    "email": "user@example.com",
    "password": "Password123!",
    "role": "user"
  }
}

# User/Admin Login
POST /api/users/login
Content-Type: application/json
{
  "user": {
    "email": "admin@example.com",
    "password": "Admin123!@#"
  }
}

# Admin Registration (requires superuser token)
POST /api/admin/users/register
Content-Type: application/json
Authorization: Bearer <superuser_token>
{
  "user": {
    "email": "newadmin@example.com",
    "password": "Admin123!@#",
    "role": "admin"
  }
}
```

### Admin Routes (requires admin token)

```bash
# Get Admin Dashboard
GET /api/admin/dashboard
Authorization: Bearer <admin_token>

# List All Users
GET /api/admin/users
Authorization: Bearer <admin_token>

# Get User Details
GET /api/admin/users/:id
Authorization: Bearer <admin_token>

# View Profits
GET /api/admin/profits
Authorization: Bearer <admin_token>

# Create Game
POST /api/admin/games
Authorization: Bearer <admin_token>
{
  "game": {
    "home_team": "Team A",
    "away_team": "Team B",
    "game_time": "2024-03-20T15:00:00Z",
    "sport_type": "football",
    "odds_home": "1.5",
    "odds_away": "2.5"
  }
}

# Update Game
PUT /api/admin/games/:id
Authorization: Bearer <admin_token>
{
  "game": {
    "status": "completed",
    "home_team_score": 2,
    "away_team_score": 1
  }
}
```

### Betting Routes (requires user token)

```bash
# List Available Games
GET /api/games

# Get Betting History
GET /api/betting/history
Authorization: Bearer <token>

# Get Game Details for Betting
GET /api/betting/:id
Authorization: Bearer <token>

# Place Bet
POST /api/betting/:id/place-bet
Authorization: Bearer <token>
{
  "bet": {
    "amount": "100.00",
    "team_picked": "home",
    "odds": "1.5"
  }
}

# View User's Bets
GET /api/user/bets
Authorization: Bearer <token>
```

### User Management Routes (requires superuser token)

```bash
# Delete User
DELETE /api/admin/users/:id
Authorization: Bearer <superuser_token>

# Toggle Admin Status
PUT /api/admin/users/:id/toggle-admin
Authorization: Bearer <superuser_token>
```

### User Profile Routes (requires user token)

```bash
# Get Current User
GET /api/get_user
Authorization: Bearer <token>
```

### Response Formats

Success responses follow this format:
```json
{
  "data": {
    // Response data here
  }
}
```

Error responses follow this format:
```json
{
  "error": "Error message"
}
```

or for validation errors:
```json
{
  "errors": {
    "field_name": ["error message"]
  }
}
```

## Authentication

The application uses Guardian for JWT-based authentication. Protected routes require a valid JWT token in the Authorization header:

```
Authorization: Bearer <token>
```

## Notes

1. Password Requirements:
   - Minimum 6 characters
   - Should contain a mix of letters and numbers

2. Role Types:
   - "admin": Can access admin dashboard and manage users
   - "superuser": Has all admin permissions plus can create other admins

3. Token Usage:
   - Include the token in subsequent requests:
   ```
   Authorization: Bearer <token>
   ```
   - Token expires in 60 days

4. Admin Privileges:
   - Access to /api/admin/* endpoints
   - User management
   - Game management
   - View profits and statistics

## Error Handling

The application uses Phoenix's error handling middleware to provide consistent error responses. Common errors include:

- 401 Unauthorized: Missing or invalid token
- 404 Not Found: Resource not found
- 422 Unprocessable Entity: Validation errors

## Testing

The application includes unit tests with ExUnit and integration tests with Phoenix.Test.

