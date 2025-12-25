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
- **Database design and schema (PostgreSQL)**
- **Comprehensive database documentation**
  - Database design rationale document
  - Database architecture document
  - PostgreSQL schema with triggers, indexes, and views
  - Migration guide with setup instructions
  - Database FAQ addressing common design questions
- **Automatic bid handling system**
  - Database triggers for winning bid determination
  - Optimized incremental counters
  - Performance-tuned indexes

### Changed
- **Database technology**: Changed from SQLite → NoSQL (planned) to PostgreSQL (relational)
  - Rationale: Unique offers don't preclude structured relationships; ACID transactions critical for bidding
  - See [DATABASE_DESIGN.md](docs/DATABASE_DESIGN.md) for full explanation

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
