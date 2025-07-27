# WeCraft - Phoenix LiveView SaaS Platform

WeCraft is a public build-in platform connecting technical founders and developers using Phoenix LiveView, implementing a context-driven architecture with clean separation of concerns.

## Architecture Overview

**Core Structure**: Phoenix contexts (`Accounts`, `Projects`, `Profiles`, `Chats`) with delegated use cases pattern

- `WeCraft.Projects` delegates to `WeCraft.Projects.UseCases.*UseCase` modules
- Domain models in `lib/we_craft/*/` with schema validation and business logic
- Web layer in `lib/we_craft_web/` with LiveView components and controllers

**Authentication**: Magic link-based system with session tokens

- No passwords required - uses `UserToken.build_email_token/2` for "login" context
- Scoped authentication with `WeCraft.Accounts.Scope.for_user/1`
- User roles: Technical Founder or Developer

**Database**: PostgreSQL with array fields for tags/needs/business_domains

- Projects table uses Ecto enums: `status: [:idea, :in_dev, :private_beta, :public_beta, :live]`
- Tag validation against predefined lists in `TechnicalTags` and `BusinessTags` modules

## Development Workflow

**Setup**: `make init-asdf` → `mix setup` → `mix phx.server`
**Testing**: `make test` (resets test DB) or `make coverage` for LCOV reports
**Assets**: Tailwind + esbuild with `mix assets.build` for development

**Key Commands**:

- `make reset-test-db` - Essential before running tests
- `mix ecto.reset` - Full database reset with seeds
- `make generate-translations` - Extract/merge gettext translations

## Project-Specific Patterns

**LiveView Structure**: All major features use LiveView with mount hooks

```elixir
live_session :require_authenticated_user,
  on_mount: [{WeCraftWeb.UserAuth, :require_authenticated}]
```

**Tag System**: Predefined technical and business tags with validation

- Technical: `WeCraft.Projects.TechnicalTags.all_tags/0` (elixir, phoenix, react, etc.)
- Business: `WeCraft.Projects.BusinessTags.all_tags/0` (fintech, healthtech, etc.)
- Auto-lowercase normalization in `Project.changeset/2`

**Search/Filtering**: `WeCraft.Projects.search_projects/1` accepts params for tags, title, business_domains, status

**Telemetry**: OpenTelemetry integration with custom logger backend

- Config: `LoggerOpenTelemetryBackend` in `lib/logger_open_telemetry_backend.ex`
- Metrics endpoint: `/telemetry-test`

## File Conventions

**Tests**: Use fixtures from `test/support/fixtures/*_fixtures.ex`

- `AccountsFixtures.user_fixture/1` for authenticated users
- `AccountsFixtures.user_scope_fixture/1` for scoped contexts

**Migrations**: Timestamped with descriptive names, include @moduledoc
**Components**: Phoenix components in `lib/we_craft_web/components/`
**Use Cases**: Single-responsibility modules in `lib/we_craft/*/use_cases/`

## Deployment

**Docker**: Multi-stage build with Debian, includes Rust toolchain setup
**Production**: Uses Bandit adapter, releases with OpenTelemetry
**Assets**: `mix assets.deploy` for minified production build
