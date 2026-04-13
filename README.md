# CinelarTV 🎬

CinelarTV is a powerful open-source platform that allows you to create your own Video on Demand (VOD) streaming platform. Take your audiovisual content to the next level with CinelarTV!

## Key Features 🚀

- 🎥 Stream your video content on-demand.
- 📊 Detailed audience and performance statistics.
- 📜 Easy and customizable content management.
- 🌐 Support for multiple devices and browsers.
- 🌟 RESTful JSON API for seamless integration with other services.


## Installation and Configuration 🛠️

---

TODO

---

## Stack 🛠️
CinelarTV is powered by the following technologies:

Backend: Ruby on Rails 💎

Frontend: Vue 3 (consumes the JSON API) 🖥️

## API Authentication for Mobile/Native Clients 🔐

CinelarTV now provides a complete RESTful API authentication system designed for mobile apps (iOS/Android) and other native clients.

### Available Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/v1/auth/login` | Login with email/username + password, returns OAuth tokens |
| POST | `/api/v1/auth/refresh` | Refresh an expired access token |
| GET | `/api/v1/auth/me` | Get current user with profiles |
| GET | `/api/v1/auth/profile-status` | Check if user has selected a profile |
| POST | `/api/v1/auth/select-profile` | Select an active profile |
| POST | `/api/v1/auth/deassign-profile` | Deselect current profile |
| DELETE | `/api/v1/auth/logout` | Logout and revoke token |

### Quick Example

**Login:**
```bash
curl -X POST https://your-domain.com/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email": "user@example.com", "password": "secret"}'
```

**Get Current User:**
```bash
curl -X GET https://your-domain.com/api/v1/auth/me \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

For complete API documentation with examples in JavaScript, Swift, and Kotlin, see: [API_AUTH_DOCUMENTATION.md](API_AUTH_DOCUMENTATION.md)

## Contribution 🤝
We welcome contributions! If you'd like to contribute to CinelarTV, please fork, fix, commit and send a pull request for the maintainers to review and merge into the main code base 😄.

## License 📝
This project is licensed under the MIT License. See the LICENSE file for more details.

## Contact 📧
Have questions or feedback? Feel free to reach out to us at cinelartv@yanquisalexander.me.

---

Thank you for using CinelarTV! We hope you enjoy creating your own Video on Demand streaming platform. 🍿📺