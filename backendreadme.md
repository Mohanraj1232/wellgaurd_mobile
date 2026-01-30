# WellGuard Backend API

## Base URL
```
http://localhost:<PORT>/api
```

## Endpoints

| Method | Endpoint | Description | Request Body | Success Response | Error Response |
|--------|----------|-------------|--------------|------------------|----------------|
| `POST` | `/api/auth/login` | Handles both user login and registration. If email exists, validates password. If new email, creates a new user account. | `{ "email": "user@example.com", "password": "your_password" }` | `{ "success": true, "statusCode": 200, "message": "Subscriptions fetched successfully", "data": { "userId": 1, "isExistingUser": true } }` | `{ "success": false, "statusCode": 409, "message": "password Incorrect" }` |
| `POST` | `/api/auth/onboarding` | Saves emergency contact information for a user. | `{ "userId": 1, "emergencyContact": { "name": "John Doe", "whatsappNumber": 1234567890, "smsNumber": 1234567890 } }` | `{ "success": true, "statusCode": 200, "message": "Onboarding completed successfully", "data": { "userId": 1, "message": "Emergency contact saved successfully" } }` | `{ "success": false, "statusCode": 404, "message": "User not found" }` |
| `GET` | `/api/info/user/:userId` | Retrieves user information including email and emergency contact details. | None (userId in URL parameter) | `{ "success": true, "statusCode": 200, "message": "User information fetched successfully", "data": { "userId": 1, "email": "user@example.com", "emergencyContact": { "name": "John Doe", "whatsappNumber": 1234567890, "smsNumber": 1234567890 } } }` | `{ "success": false, "statusCode": 404, "message": "User not found" }` |

---

## Response Format

All API responses follow this standard format:

**Success:**
```json
{
  "success": true,
  "statusCode": <HTTP_STATUS_CODE>,
  "message": "<SUCCESS_MESSAGE>",
  "data": { }
}
```

**Error:**
```json
{
  "success": false,
  "statusCode": <HTTP_STATUS_CODE>,
  "message": "<ERROR_MESSAGE>"
}
```

## Status Codes
- `200` - OK
- `404` - Not Found
- `409` - Conflict
- `500` - Internal Server Error

## Setup

1. Install dependencies:
```bash
npm install
```

2. Create `.env` file with required environment variables

3. Run the server:
```bash
npm start          # Production mode
npm run dev        # Development mode with auto-reload
```
