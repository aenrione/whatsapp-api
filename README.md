# 📲 WhatsApp Notification API (Baileys + Express + Docker)

A lightweight RESTful API for sending WhatsApp messages using [Baileys](https://github.com/WhiskeySockets/Baileys). Ideal for self-hosted notification systems like **Sonarr, Radarr, Prowlarr**, or custom alerting tools.

---

## ✨ Features

- 🔌 REST API to send messages
- 🧠 Persistent WhatsApp sessions
- 🐳 Docker & Docker Compose ready
- 🛠 Built with TypeScript & Express
- 💬 Based on WhatsApp Web (Baileys)
- 🔐 QR-based login with session reuse

---

## 🚀 Quick Start

### 1. Clone the repo

```bash
git clone https://github.com/aenrione/whatsapp-api.git
cd whatsapp-api
````

### 2. Build & Run with Docker

```bash
docker-compose up --build
```

### 3. Scan the QR Code

When you start the container, scan the QR code printed in the logs using your WhatsApp mobile app. This logs in your bot.

---

## 🔁 Example API Usage

### POST `/send`

Send a message to a WhatsApp number or group (it's based on jid).

#### Request:

```http
POST /send
Content-Type: application/json

{
  "number": "1234567890",
  "message": "Hello from WhatsApp API!"
}
```

* `number`: Phone number with country code (no `+`, dashes or spaces) or group jid
* `message`: Text content to send

#### Response:

```json
{ "status": "Message sent" }
```

---

## 🔧 Configuration

* Runs on port `3000` by default.
* Authentication is stored in the `auth/` folder (persisted via Docker volume).
* No rate-limiting or spam filtering included — use responsibly.

---

## 📂 Project Structure

```
.
├── src/
│   ├── index.ts          # Express server
│   └── whatsapp.ts       # Baileys socket logic
├── auth/                 # Saved WhatsApp session (auto-generated)
├── Dockerfile
├── docker-compose.yml
├── package.json
├── tsconfig.json
└── README.md
```

---

## 🛑 Disclaimer

This project uses the **unofficial WhatsApp Web API** and is not affiliated with or endorsed by WhatsApp Inc. Use at your own risk and respect their [Terms of Service](https://www.whatsapp.com/legal/terms-of-service/).

---

## 🧑‍💻 Contributing

Feel free to fork, improve, or submit issues and pull requests. Star the repo if you find it useful! ⭐

---

## 📜 License

MIT License © 2025 \[Your Name]

```

---

Let me know if you want this adjusted for npm publishing, or to include multi-device tips, message formats (media, buttons, etc.), or authentication tokens for protected APIs.
