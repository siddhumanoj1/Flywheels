# FLYWHEELS AUTO

Production-oriented garage management platform with a Flutter mobile app and a Node.js backend.

## Stack

- Flutter mobile app: `D:\soft\Flywheels\flywheels`
- Node.js + Express + Prisma backend: `D:\soft\Flywheels\backend`
- PostgreSQL via Docker Compose: `D:\soft\Flywheels\docker-compose.yml`

## Highlights

- Phone OTP authentication with JWT sessions
- Customer and owner role-based dashboards
- Multi-car management, service history, quotation approvals, invoices, and notifications
- Live workflow states for garage jobs
- Deterministic invoice/quotation parser that preserves line item descriptions and supports `800*5` arithmetic
- Telegram-compatible document parsing flow inspired by the existing Flywheels bot contract
- PDF invoice generation with repo branding
- Prisma schema for PostgreSQL and Socket.IO real-time hooks

## Run Backend

1. Copy `backend/.env.example` to `backend/.env`
2. Start PostgreSQL:

```bash
docker compose up -d postgres
```

3. Install and generate Prisma client:

```bash
cd backend
npm install
npm run prisma:generate
npm run prisma:migrate
```

4. Start the API:

```bash
npm run dev
```

## Run Flutter App

```bash
cd flywheels
flutter pub get
flutter run
```

The app is configured to use `http://10.0.2.2:8080/api/v1` by default on Android emulators and falls back to seeded demo data if the backend is unavailable.

