# Admin Registration

Register a new admin user. This endpoint requires superuser authentication.

## Endpoint

```
POST /api/admin/users/register
```

## Request Headers

```
Authorization: Bearer <superuser_token>
```

## Request Body

```json
{
  "user": {
    "email": "newadmin@example.com",
    "password": "admin_password",
    "role": "admin"  // Can be "admin" or "superuser"
  }
}
```

## Success Response (201 Created)

```json
{
  "data": {
    "id": 2,
    "email": "newadmin@example.com",
    "role": "admin",
    "created_at": "2024-03-20T10:00:00Z"
  }
}
```

## Error Responses

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
    "password": ["should be at least 12 characters"]
  }
}
```

## Example cURL Request

```bash
curl -X POST http://localhost:4000/api/admin/users/register \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <superuser_token>" \
  -d '{
    "user": {
      "email": "newadmin@example.com",
      "password": "admin_password",
      "role": "admin"
    }
  }'
```

## Notes

- Only superusers can create new admin accounts
- Password must meet security requirements:
  - Minimum 12 characters
  - At least one uppercase letter
  - At least one number
  - At least one special character
- Email must be unique in the system 