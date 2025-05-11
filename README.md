# EarnPlusPlus

EarnPlusPlus is a full-stack, mobile-first investment tracker built to solve a common gap: beginner investors need clarity and control, but most tools are either oversimplified spreadsheets or overly complex trading platforms.

## The Problem

In practice, student and first-time investors often track entries manually across notes, sheets, and banking apps. That creates three real issues:

- Data gets fragmented and hard to trust over time.
- There is no clear separation between one user and another user's data.
- Financial values are easy to mis-handle if precision is treated casually.

The project goal was to build a focused system that made investment tracking simple without sacrificing backend discipline.

## The Solution

I built a Flutter client with a Dart Shelf API and MySQL storage.

At a high level, the app provides:

- Account registration and login.
- JWT-based session handling.
- User-scoped investment retrieval.
- A dashboard flow that handles loading, empty, error, and unauthorized states.
- Portfolio Insights: P/L %, trend badges, allocation pie chart, monthly snapshot.
- Smart Notifications: price/goal alerts, inactivity nudges, milestone notifications.
- Trust-oriented UX: audit/history timeline and improved error-recovery messaging.
- Production UI polish: animated KPI cards, shimmer loading states, chart micro-interactions.

## Approach Before Coding

Before implementation, I intentionally split the system into three concerns:

- Presentation state: UI controllers should own loading/error state.
- Data access: repositories should handle HTTP and parsing concerns.
- Backend trust boundaries: routes should enforce authentication and data ownership.

Two alternatives were considered and rejected:

- Calling HTTP directly from screens: quick at first, but tightly couples UI and networking.
- Keeping auth checks only in the client: unsafe, because trust must be enforced by the API.

## Tech Stack and Rationale

- Flutter: one codebase for mobile UI and rapid iteration on screens.
- Provider with ChangeNotifier: lightweight, explicit state changes suitable for project scope.
- Shelf + shelf_router: minimal backend surface with clear route control.
- MySQL: relational model works well for users and investment records.
- dart_jsonwebtoken + bcrypt: practical baseline for auth and password security.
- flutter_secure_storage: token persistence in a safer device storage layer.
- decimal: financial value handling without floating-point surprises.
- fl_chart: concise visual trend representation for dashboard insights.

## Key Technical Decisions

### 1) Precision-First Money Handling

I treated money as a precision problem, not just a display problem. Using decimal-based handling for investment amounts reduces rounding drift risk that appears when binary floating-point math is used for financial values.

### 2) Repository + Controller Separation

I moved network and parsing logic into repositories, while controllers handle view-state transitions. This kept widgets focused on rendering and made error/loading behavior easier to reason about and test.

### 3) API-Enforced Data Ownership

The backend extracts the authenticated user from JWT and filters investment data by that user ID. This design prevents cross-user data access even if a client is modified or malicious.

## What Worked Well

- Layering the app reduced coupling and made feature changes safer.
- Explicit state transitions improved UX around non-happy-path scenarios.
- Security and ownership rules embedded in API routes simplified client logic.

## What I Would Do Differently

- Add integration tests for end-to-end auth and investment flows much earlier.
- Introduce refresh tokens and token rotation instead of only short-lived access tokens.
- Establish environment profiles (dev/staging/prod) at the beginning.
- Add CI quality gates (analyze + tests) from day one.

## Lessons Learned

- Most engineering effort goes into edge cases, not just the happy path.
- Security boundaries belong on the server, not only in the UI layer.
- Early architecture decisions compound; small shortcuts become expensive later.
- Writing reflective documentation improves technical decision quality.

## Recent Product Enhancements

The latest delivery phase focused on turning the dashboard from a baseline feature
into a production-grade experience:

- Portfolio Insights panel with allocation and performance summary.
- Smart notification center with user preference toggles.
- Micro-interactions for filter transitions, card feedback, and chart tooltips.
- Audit/history timeline to improve trust and traceability.

All of these were implemented via separate atomic commits with scheduled dates to keep
history clean and reviewable.


