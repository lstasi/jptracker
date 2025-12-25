# jptracker
Auction Tracker

## Overview
JPTracker is an auction tracking system designed to monitor and manage unique auction offers and their associated bids.

## Documentation
- [Architecture Overview](docs/ARCHITECTURE.md) - System design and rationale
- [Database Design](docs/DATABASE_DESIGN.md) - Why relational DB and design decisions
- [Database Schema](schema/schema.sql) - SQL schema with tables, indexes, and examples
- [Migration Guide](docs/MIGRATION_GUIDE.md) - Setup instructions and sample data
- [FAQ](docs/FAQ.md) - Common questions about the database design

## Key Features
- Track unique auction offers with complete product information
- Manage bidding with ACID guarantees
- Flexible tagging system for discovering similar items
- Historical bid tracking and analytics
- Support for proxy/auto-bidding

## Database Design
This project uses a relational database (PostgreSQL) despite each auction offer being unique. See [Database Design](docs/DATABASE_DESIGN.md) for detailed rationale.

Key design principles:
- **Offers are independent entities** - Each offer is self-contained with no forced normalization
- **Flexible relationships via tags** - Discover similar items without rigid categorization  
- **Data integrity** - ACID transactions for bidding operations
- **Query flexibility** - SQL enables complex filtering and analytics
