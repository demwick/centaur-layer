# Example Centaur Contract: Web Feature

AI may accelerate implementation, but the human owns intent, tradeoffs, risk, and final judgment.

## Repository Defaults

### Human Owns

- route structure and data ownership decisions
- validation rules for user input
- final approval of auth, persistence, and API shape changes

### AI May Do

- implement UI components inside `app/` and `components/`
- write tests for the approved behavior
- update docs for the changed workflow

### Requires Explicit Confirmation

- database schema changes
- auth or permission changes
- edits outside `app/`, `components/`, and `tests/`
- dependency additions

### Verification Required

- test command passes
- changed user flow is described
- one edge case is named before acceptance

## Active Contract

### Goal

Add a settings form for updating a user's display name.

### Human Owns

- deciding whether display names must be unique
- deciding how validation errors are presented

### AI May Do

- implement the form component
- add client-side validation
- add tests for empty and valid display names

### Out Of Scope

- authentication changes
- database schema changes
- avatar upload

### Risk Gates

- Any persistence or API contract change requires explicit confirmation.

### Acceptance Checks

- Empty display name is rejected.
- Valid display name submits successfully.
- Existing settings page layout remains unchanged outside the form area.
