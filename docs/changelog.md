# Changelog

All notable project changes are documented in this file.

## [1.8.0] - 2025-03-23
### Added
- Full server source tracking in repository (while excluding generated and sensitive files).
- Frozen API contract documentation.
- Release checklist document.

### Changed
- CI pipeline added for Flutter and server analyze/test checks.
- App environment profile support (dev/staging/prod).
- Basic telemetry bootstrap for app-start and runtime error/event logging.

## [1.7.0] - 2025-03-20
### Added
- Widget tests for investment management, admin dashboard, and superadmin dashboard screens.

### Changed
- Screen constructors now support controller injection for testability.

## [1.6.0] - 2025-03-19
### Added
- Refresh-token flow with `/auth/refresh` endpoint.
- Logout-all session invalidation endpoint.

### Changed
- Access-token type enforcement on protected backend routes.
- Client auth service now manages access and refresh tokens.
- Drawer menu now hides admin/superadmin entries unless role permits access.

## [1.5.0] - 2025-03-18
### Added
- Superadmin dashboard with role distribution metrics.
- Superadmin role management endpoint and UI role update action.

## [1.4.0] - 2025-03-16
### Added
- Admin dashboard summary endpoint and UI cards.
- User listing endpoint for admin/superadmin operators.

## [1.3.0] - 2025-03-15
### Added
- User role field added to schema and JWT claims.
- First-user bootstrap as superadmin.
- `GET /users/me` profile endpoint.

## [1.2.0] - 2025-03-14
### Added
- Investment CRUD endpoints (`POST/PUT/DELETE /investments`).
- Investment management UI for add/edit/delete flows.
- Investment model/repository/controller extensions for mutation handling.

## [1.1.0] - 2025-03-05
### Added
- Login and registration flow refactor to controller-based state management using Provider.
- Dedicated `LoginController` and `RegisterController` for auth workflow state.
- Focused unit tests for login/register controllers covering success/failure and state transitions.

### Changed
- App branding constants updated to `EarnPlusPlus` and `EarnPlusPlus Dashboard`.
- Authentication screens updated to consume controller state and error handling.

## [1.0.0] - 2025-03-02
### Added
- Minimum Viable Product (MVP) delivered.
- Secure authentication baseline and user-scoped investment retrieval foundation.
- Initial dashboard experience and core investment-tracking flow.

### Notes
- This release marks the first production-capable milestone for the project.

## Documentation Location Rule
- All project documentation files except README files are stored under `docs/`.
