# Release Checklist

## Code Quality
- [ ] Flutter analyze passes (`flutter analyze lib test`)
- [ ] Flutter tests pass (`flutter test`)
- [ ] Server analyze passes (`dart analyze`)
- [ ] CI workflow green

## Security
- [ ] Production JWT secret configured via environment variable
- [ ] `.env` and secret files excluded from git
- [ ] Refresh token and logout-all flows validated
- [ ] Admin and superadmin role access verified

## Product
- [ ] Investment CRUD validated end-to-end
- [ ] Admin dashboard metrics validated
- [ ] Superadmin role update flow validated

## Documentation
- [ ] README demo section updated with final screenshots (manual)
- [ ] Changelog updated for release date/version
- [ ] API contract reviewed
