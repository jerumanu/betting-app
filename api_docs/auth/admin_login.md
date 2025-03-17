# Admin Login

Authenticates an admin user and returns a JWT token along with user details.

## Endpoint

```
POST /api/users/login
```

## Request Body

```json
{
  "user": {
    "email": "admin@example.com",
    "password": "admin_password"
  }
}
```

## Success Response (200 OK)

```json
{
  "data": {
    "id": 1,
    "email": "admin@example.com",
    "role": "admin",
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
  }
}
```

## Error Responses

### Invalid Credentials (401 Unauthorized)
```json
{
  "error": "Invalid email or password"
}
```

### Non-Admin User (403 Forbidden)
```json
{
  "error": "Insufficient permissions"
}
```

### Invalid Request Format (400 Bad Request)
```json
{
  "error": "Invalid request format"
}
```

## Example cURL Request

```bash
curl -X POST http://localhost:4000/api/users/login \
  -H "Content-Type: application/json" \
  -d '{
    "user": {
      "email": "admin@example.com",
      "password": "admin_password"
    }
  }'
```

## Notes

- The returned JWT token must be included in subsequent API requests in the Authorization header:
  ```
  Authorization: Bearer <token>
  ```
- Admin users have access to additional endpoints under /api/admin/*
- Token expiration is set to 60 days
- All timestamps are in UTC

## Admin-Only Endpoints

After successful login, admin users can access:

1. User Management
```
GET /api/admin/users - List all users
GET /api/admin/users/:id - Get user details
```

2. Dashboard
```
GET /api/admin/dashboard - View admin dashboard
```

3. Game Management
```
POST /api/admin/games - Create new game
PUT /api/admin/games/:id - Update game
```

4. Profit Reports
```
GET /api/admin/profits - View profit reports
``` 