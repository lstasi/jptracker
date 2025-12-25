# jptracker

Auction Tracker - A web-based application for tracking auction items, monitoring prices, and managing bids.

## Overview

jptracker is an auction tracking system designed to help users monitor auction items, compare prices against real market values, track bids, and receive alerts for expiring auctions.

## Features (Planned)

- **Web Scraping**: Automated scraping of auction listings with rate limiting to avoid bans
- **Product Storage**: Persistent storage of product information and auction data
- **Price Comparison**: Compare auction prices/bids against real market prices
- **Bid Tracking**: Monitor user bids across multiple auctions
- **Expiration Alerts**: Receive notifications for expiring auctions

## Technology Stack

### Backend
- **Language**: Python
- **Database**: SQLite (development) → PostgreSQL (production) - see [Architecture](docs/architecture.md) for migration path
- **API**: RESTful API backend

### Frontend
- **Framework**: Vanilla JavaScript
- **Architecture**: Single Page Application (SPA)
- **Communication**: API-based frontend-backend communication

## Project Status

🚧 **Planning Phase** - No code implementation yet

This project is currently in the planning and design phase. See the `docs/` folder for architectural proposals and the `TODO.md` file for planned tasks.

## Documentation

### Planning & Proposals
- [Architecture Proposal](docs/architecture.md) - System architecture and component design
- [Project Proposal](docs/proposal.md) - Full project proposal and requirements
- [TODO](TODO.md) - Task list and project roadmap
- [CHANGELOG](CHANGELOG.md) - Project change history

### Database Design (Completed)
- [Database Design Rationale](docs/DATABASE_DESIGN.md) - Why relational DB for unique offers
- [Database Schema](schema/schema.sql) - PostgreSQL/SQLite schema with triggers and indexes
- [Migration Guide](docs/MIGRATION_GUIDE.md) - Setup instructions and sample data
- [Database FAQ](docs/FAQ.md) - Common questions about the database design

## Getting Started

Coming soon - the project is currently in the planning phase.

## License

TBD
