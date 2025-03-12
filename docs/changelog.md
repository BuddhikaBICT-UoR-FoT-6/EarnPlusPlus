# Changelog

All notable project changes are documented in this file.

## [1.5.0] - 2025-03-14 (Planned)
### Added
- Superadmin dashboard milestone defined for:
- System-wide oversight.
- Role governance and permission control.
- Platform-level reporting and audit visibility.

### Notes
- This milestone is documented as the next target after admin dashboard completion.

## [1.4.0] - 2025-03-12 (Planned)
### Added
- Admin dashboard milestone defined for:
- User oversight and management workflows.
- Investment moderation and review tooling.
- Operational summaries for portfolio activity.

### Notes
- This milestone is documented as the operational management layer before superadmin controls.

## [1.3.0] - 2025-03-10 (Planned)
### Added
- User management milestone defined for:
- User profile and account lifecycle handling.
- Role assignment model preparation.
- User-focused account administration workflows.

### Notes
- This milestone is documented as the role and account management foundation.

## [1.2.0] - 2025-03-08 (Planned)
### Added
- Investment details management milestone defined for:
- Detailed investment-level view and handling.
- Data model expansion path for richer portfolio records.
- Workflow planning for investment create/update/delete operations.

### Notes
- This milestone is documented as the next product depth layer after MVP stabilization.

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
