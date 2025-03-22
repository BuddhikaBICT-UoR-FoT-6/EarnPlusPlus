# API Contract (Frozen v1)

Base URL by environment:
- dev: `http://10.0.2.2:8080`
- staging: `https://staging-api.earnplusplus.com`
- prod: `https://api.earnplusplus.com`

Auth uses Bearer tokens in `Authorization` header.

## Auth

### POST `/auth/register`
Request:
```json
{
  "email": "user@example.com",
  "password": "secret123"
}
```
Response `201`:
```json
{
  "message": "User registered successfully",
  "role": "user"
}
```

### POST `/auth/login`
Request:
```json
{
  "email": "user@example.com",
  "password": "secret123"
}
```
Response `200`:
```json
{
  "token": "<access-token>",
  "refresh_token": "<refresh-token>",
  "role": "user"
}
```

### POST `/auth/refresh`
Request:
```json
{
  "refresh_token": "<refresh-token>"
}
```
Response `200`:
```json
{
  "token": "<new-access-token>",
  "role": "user"
}
```

### POST `/auth/logout-all`
Headers:
- `Authorization: Bearer <access-token>`
Response `200`:
```json
{
  "message": "Logged out from all sessions"
}
```

## Investments

### GET `/investments`
Response `200`:
```json
[
  {
    "id": 1,
    "date": "2025-03-01",
    "asset": "AAPL",
    "amount": 100.5
  }
]
```

### POST `/investments`
Request:
```json
{
  "date": "2025-03-01",
  "asset": "AAPL",
  "amount": 100.5
}
```
Response `201`:
```json
{
  "id": 1,
  "date": "2025-03-01",
  "asset": "AAPL",
  "amount": 100.5
}
```

### PUT `/investments/:id`
Request:
```json
{
  "date": "2025-03-02",
  "asset": "AAPL",
  "amount": 125.0
}
```
Response `200`:
```json
{
  "id": 1,
  "date": "2025-03-02",
  "asset": "AAPL",
  "amount": 125.0
}
```

### DELETE `/investments/:id`
Response `200`:
```json
{
  "message": "Investment deleted"
}
```

## User Management and Dashboards

### GET `/users/me`
Response `200`:
```json
{
  "id": 1,
  "email": "user@example.com",
  "role": "user",
  "created_at": "2025-03-02T10:00:00.000Z"
}
```

### GET `/admin/users`
Roles: `admin`, `superadmin`

### GET `/admin/dashboard`
Roles: `admin`, `superadmin`
Response:
```json
{
  "users": 10,
  "investments": 24,
  "total_amount": 1800.5
}
```

### GET `/superadmin/dashboard`
Role: `superadmin`
Response:
```json
{
  "users": 10,
  "investments": 24,
  "roles": {
    "user": 8,
    "admin": 1,
    "superadmin": 1
  }
}
```

### PATCH `/superadmin/users/:id/role`
Role: `superadmin`
Request:
```json
{
  "role": "admin"
}
```
Response `200`:
```json
{
  "message": "Role updated",
  "role": "admin"
}
```
