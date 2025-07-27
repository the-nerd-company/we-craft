# WeCraft 🚀

**WeCraft** is a public build-in-public platform connecting technical founders and developers, built with Phoenix LiveView and implementing a context-driven architecture with clean separation of concerns.

## Overview

WeCraft enables technical founders to showcase their projects and connect with skilled developers who want to contribute to exciting ventures. Whether you're building the next big SaaS, exploring fintech solutions, or working on cutting-edge healthtech innovations, WeCraft helps you find the right collaborators.

### Key Features

- **Project Showcase**: Technical founders can create detailed project profiles with descriptions, tech stacks, and current status
- **Developer Matching**: Smart search and filtering to match developers with projects based on technical skills and business domains  
- **Real-time Chat**: Built-in messaging system for project discussions and collaboration
- **Magic Link Authentication**: Passwordless login system for seamless user experience
- **Tag-based Discovery**: Comprehensive tagging system for technologies (Elixir, Phoenix, React, etc.) and business domains (Fintech, Healthtech, SaaS, etc.)
- **Project Status Tracking**: Track projects from idea stage through development to live deployment

## Architecture

### Core Structure

- **Phoenix Contexts**: Clean separation with `Accounts`, `Projects`, `Profiles`, and `Chats` contexts
- **Use Case Pattern**: Business logic delegated to `WeCraft.*.UseCases.*UseCase` modules
- **Domain Models**: Schema validation and business logic in `lib/we_craft/*/`
- **LiveView Frontend**: Interactive web layer in `lib/we_craft_web/` with real-time updates

### Authentication System

- **Magic Link Based**: No passwords required - uses email token-based authentication
- **Scoped Authentication**: User sessions with `WeCraft.Accounts.Scope.for_user/1`
- **User Roles**: Technical Founder or Developer personas
- **Session Management**: Secure token-based sessions with remember-me functionality

### Database Design

- **PostgreSQL**: Primary database with array fields for flexible tag storage
- **Project Status Enum**: `[:idea, :in_dev, :private_beta, :public_beta, :live]`
- **Tag Validation**: Predefined technical and business tag lists with validation
- **Real-time Features**: Chat messaging with Phoenix PubSub

## Getting Started

### Prerequisites

- Elixir 1.15+
- Erlang/OTP 26+
- Node.js (for assets)
- PostgreSQL
- (Optional) asdf for version management

### Installation

1. **Clone the repository**

   ```bash
   git clone https://github.com/the-nerd-company/we-craft.git
   cd we-craft
   ```

2. **Setup development environment with asdf (recommended)**

   ```bash
   make init-asdf
   ```

3. **Install dependencies and setup database**

   ```bash
   mix setup
   ```

4. **Start the Phoenix server**

   ```bash
   mix phx.server
   ```

5. **Visit the application**

   Open [`localhost:4000`](http://localhost:4000) in your browser

### Alternative Setup Commands

- **Manual dependency installation**: `mix deps.get`
- **Database setup**: `mix ecto.setup`
- **Asset compilation**: `mix assets.build`
- **Full database reset**: `mix ecto.reset`

## Development Workflow

### Key Commands

```bash
# Run tests (with database reset)
make test

# Generate test coverage reports
make coverage

# Reset test database only
make reset-test-db

# Extract and merge translations
make generate-translations

# Build assets for development
mix assets.build

# Build assets for production
mix assets.deploy
```

### Project Structure

```text
lib/
├── we_craft/                     # Core business logic
│   ├── accounts/                 # User management & authentication
│   ├── projects/                 # Project management & search
│   ├── profiles/                 # User profile management
│   └── chats/                    # Real-time messaging
├── we_craft_web/                 # Web interface
│   ├── live/                     # LiveView modules
│   ├── components/               # Reusable UI components
│   └── controllers/              # HTTP controllers
└── we_craft.ex                   # Main application module

test/
├── we_craft/                     # Business logic tests
├── we_craft_web/                 # Web layer tests
└── support/                      # Test fixtures and helpers
```

### Tag System

WeCraft uses a comprehensive tagging system for project discovery:

**Technical Tags**: `elixir`, `phoenix`, `react`, `javascript`, `python`, `docker`, `kubernetes`, etc.
**Business Domains**: `fintech`, `healthtech`, `saas`, `ecommerce`, `productivity`, `analytics`, etc.

Tags are validated against predefined lists and automatically normalized to lowercase.

### LiveView Architecture

All major features use Phoenix LiveView with proper mount hooks:

```elixir
live_session :require_authenticated_user,
  on_mount: [{WeCraftWeb.UserAuth, :require_authenticated}]
```

## Testing

The project includes comprehensive test coverage:

```bash
# Run all tests with fresh test database
make test

# Generate LCOV coverage report  
make coverage

# Run specific test files
mix test test/we_craft/projects/
```

### Test Fixtures

Tests use fixtures from `test/support/fixtures/*_fixtures.ex`:

- `AccountsFixtures.user_fixture/1` for authenticated users
- `ProjectsFixtures.project_fixture/1` for test projects
- `AccountsFixtures.user_scope_fixture/1` for scoped contexts

## Production Deployment

### Docker Support

The project includes multi-stage Docker builds:

```bash
# Build and push Docker image
make build-and-push-docker-image

# Deploy to production
make deploy-to-prod
```

### Production Configuration

- **Web Server**: Bandit adapter for optimal Phoenix LiveView performance
- **Telemetry**: OpenTelemetry integration with custom logger backend
- **Assets**: Minified CSS/JS with Phoenix digest for cache busting
- **Database**: PostgreSQL with connection pooling

## Monitoring & Observability

WeCraft includes comprehensive monitoring:

- **OpenTelemetry**: Distributed tracing and metrics
- **Phoenix LiveDashboard**: Real-time application metrics
- **Custom Telemetry**: Application-specific metrics and logging
- **Health Checks**: `/health` endpoint for load balancer monitoring

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Run tests (`make test`)
4. Commit your changes (`git commit -m 'Add amazing feature'`)
5. Push to the branch (`git push origin feature/amazing-feature`)
6. Open a Pull Request

### Code Quality

The project maintains high code quality with:

- **Credo**: Static code analysis
- **Dialyzer**: Type checking and static analysis
- **ExCoveralls**: Test coverage reporting
- **Git Hooks**: Pre-commit hooks for code quality

## License

This project is **open source** with a **non-commercial license**.

**WeCraft Open Source License (Non-Commercial)** - See [LICENSE](LICENSE) file for details.

### What's Allowed ✅
- Personal use and learning
- Educational purposes  
- Research and development
- Open source contributions
- Non-profit organizations
- Forking and modifying the code

### What's Not Allowed ❌
- Commercial use without permission
- Selling the software or services based on it
- Monetizing through advertising, subscriptions, etc.
- Offering as a service (SaaS)
- Any revenue-generating activities

### Commercial Use 💼
Want to use WeCraft commercially? Commercial licenses are available! Please contact the project owner for reasonable commercial licensing terms that support the ongoing development of this open source project.

### Contributing 🤝
We welcome contributions from the community! By contributing, you help make WeCraft better for everyone while the project remains free for non-commercial use.
