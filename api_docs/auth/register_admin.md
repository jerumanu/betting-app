# Register Admin User

Register a new admin user. This endpoint requires superuser authentication.

## Endpoint

```
POST /api/admin/users/register
```

## Request Headers

```
Content-Type: application/json
Authorization: Bearer <superuser_token>
```

## Request Body

```json
{
  "user": {
    "email": "admin@example.com",
    "password": "Admin123!@#",
    "role": "admin"
  }
}
```

## Success Response (201 Created)

```json
{
  "data": {
    "id": 1,
    "email": "admin@example.com",
    "role": "admin",
    "created_at": "2024-03-20T10:00:00Z"
  }
}
```

## Error Responses

### Invalid Request Format (400 Bad Request)
```json
{
  "error": "Invalid request format"
}
```

### Unauthorized (401 Unauthorized)
```json
{
  "error": "Not authenticated"
}
```

### Insufficient Permissions (403 Forbidden)
```json
{
  "error": "Only superusers can create admin accounts"
}
```

### Validation Errors (422 Unprocessable Entity)
```json
{
  "errors": {
    "email": ["has already been taken"],
    "password": ["should be at least 12 characters"],
    "role": ["must be admin or superuser"]
  }
}
```

## Example cURL Request

```bash
# First, get a superuser token
curl -X POST http://localhost:4000/api/users/login \
  -H "Content-Type: application/json" \
  -d '{
    "user": {
      "email": "superuser@example.com",
      "password": "superuser_password"
    }
  }'

# Then use the token to create an admin user
curl -X POST http://localhost:4000/api/admin/users/register \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <superuser_token>" \
  -d '{
    "user": {
      "email": "admin@example.com",
      "password": "Admin123!@#",
      "role": "admin"
    }
  }'
```

## Required Fields

| Field    | Type   | Description                                |
|----------|--------|--------------------------------------------|
| email    | string | Valid email address                        |
| password | string | Password meeting security requirements      |
| role     | string | Must be either "admin" or "superuser"      |

## Password Requirements

- Minimum 12 characters
- At least one uppercase letter
- At least one lowercase letter
- At least one number
- At least one special character (!@#$%^&*)

## Notes

1. Only authenticated superusers can create admin accounts
2. Email addresses must be unique in the system
3. The role field must be either "admin" or "superuser"
4. All timestamps are returned in UTC format
5. The Authorization header must contain a valid superuser JWT token 