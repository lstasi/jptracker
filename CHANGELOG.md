# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Initial project structure
- Project documentation
- README with project overview
- TODO.md with planned tasks
- Architecture proposal document
- Project proposal document
- Planning phase documentation
- **Database design and schema (SQLite/PostgreSQL compatible)**
- **Comprehensive database documentation**
  - Database design rationale document
  - Unified architecture document (merged system and database architecture)
  - SQLite/PostgreSQL-compatible schema with triggers, indexes, and views
  - Migration guide with setup instructions
  - Database FAQ addressing common design questions
- **Automatic bid handling system**
  - Database triggers for winning bid determination
  - Optimized incremental counters
  - Performance-tuned indexes

### Changed
- **Database technology**: SQLite for development → PostgreSQL for production
  - Development uses SQLite for simplicity and zero configuration
  - Production uses PostgreSQL for scalability and concurrent bidding
  - Schema designed to be compatible with both databases
  - Clear migration path documented
  - Rationale: Unique offers don't preclude structured relationships; ACID transactions critical for bidding
  - See [architecture.md](docs/architecture.md) for full explanation and migration path
- **Architecture documents**: Merged database-specific and system architecture into single unified document

### Deprecated
- N/A

### Removed
- N/A

### Fixed
- N/A

### Security
- N/A

---

## Notes

This project is currently in the planning phase. Active development has not yet begun.
