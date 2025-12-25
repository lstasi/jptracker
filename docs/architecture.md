# Architecture Proposal - jptracker

> **Note**: The database design has been completed and documented. See [DATABASE_DESIGN.md](DATABASE_DESIGN.md) and [ARCHITECTURE.md](ARCHITECTURE.md) (database-specific) for the implemented PostgreSQL schema, along with [schema/schema.sql](../schema/schema.sql) for the complete implementation.

## System Overview

jptracker is an auction tracking application designed with a clear separation between frontend and backend components, following a modern web application architecture pattern.

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                        Client Layer                          │
│  ┌───────────────────────────────────────────────────────┐  │
│  │          Frontend (Vanilla JavaScript SPA)             │  │
│  │  - Product Listings  - Auction Details                │  │
│  │  - User Dashboard    - Alert Management                │  │
│  └───────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
                            │
                   HTTP/REST API
                            │
┌─────────────────────────────────────────────────────────────┐
│                      Application Layer                       │
│  ┌───────────────────────────────────────────────────────┐  │
│  │              Python Backend API                        │  │
│  │  ┌──────────────┐  ┌──────────────┐  ┌─────────────┐ │  │
│  │  │ Product API  │  │  Bid API     │  │  Alert API  │ │  │
│  │  └──────────────┘  └──────────────┘  └─────────────┘ │  │
│  │  ┌──────────────┐  ┌──────────────┐  ┌─────────────┐ │  │
│  │  │  User API    │  │ Scraper API  │  │  Price API  │ │  │
│  │  └──────────────┘  └──────────────┘  └─────────────┘ │  │
│  └───────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
                            │
┌─────────────────────────────────────────────────────────────┐
│                       Service Layer                          │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────────┐  │
│  │   Scraping   │  │    Price     │  │      Alert       │  │
│  │   Service    │  │  Comparison  │  │     Service      │  │
│  │              │  │   Service    │  │                  │  │
│  └──────────────┘  └──────────────┘  └──────────────────┘  │
└─────────────────────────────────────────────────────────────┘
                            │
┌─────────────────────────────────────────────────────────────┐
│                      Data Access Layer                       │
│  ┌───────────────────────────────────────────────────────┐  │
│  │               ORM / Database Layer                     │  │
│  │  - Models    - Queries    - Migrations                │  │
│  └───────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
                            │
┌─────────────────────────────────────────────────────────────┐
│                       Storage Layer                          │
│  ┌───────────────────────────────────────────────────────┐  │
│  │            PostgreSQL Database ✅                      │  │
│  │  Schema with triggers, indexes, and views              │  │
│  │  See: docs/DATABASE_DESIGN.md for details              │  │
│  └───────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

## Components

### 1. Frontend (Client Layer)

**Technology**: Vanilla JavaScript (ES6+), HTML5, CSS3

**Responsibilities**:
- User interface rendering
- User interaction handling
- API communication
- Client-side validation
- State management

**Key Features**:
- Single Page Application (SPA) architecture
- Responsive design
- Dynamic content loading
- Real-time updates for alerts

### 2. Backend API (Application Layer)

**Technology**: Python (Flask or FastAPI recommended)

**Responsibilities**:
- Request handling and routing
- Business logic implementation
- Authentication and authorization
- Input validation
- Response formatting

**API Endpoints** (Planned):
- `/api/products` - Product management
- `/api/auctions` - Auction data
- `/api/bids` - Bid tracking
- `/api/users` - User management
- `/api/alerts` - Alert configuration
- `/api/prices` - Price comparison data

### 3. Service Layer

#### Scraping Service
**Responsibilities**:
- Web scraping execution
- Rate limiting to avoid bans
- HTML parsing and data extraction
- Error handling and retries
- Proxy management (if needed)

**Design Considerations**:
- Respect robots.txt
- Implement exponential backoff
- User-agent rotation
- Session management

#### Price Comparison Service
**Responsibilities**:
- External price data retrieval
- Price normalization
- Historical price tracking
- Price trend analysis
- Comparison algorithm

#### Alert Service
**Responsibilities**:
- Alert condition monitoring
- Notification triggering
- Alert delivery (email, push, etc.)
- Alert history tracking

### 4. Data Access Layer

**Technology**: SQLAlchemy (or similar ORM)

**Responsibilities**:
- Database abstraction
- Query building
- Transaction management
- Data mapping

### 5. Storage Layer

**Database**: PostgreSQL (Relational Database) ✅

**Rationale**: After thorough analysis (see [DATABASE_DESIGN.md](DATABASE_DESIGN.md)), a relational database was chosen despite each auction offer being unique because:
- Structured relationships (bids→offers, tags→offers) require ACID guarantees
- Complex queries needed for filtering, sorting, and joining
- Bidding operations require atomic transactions to prevent race conditions
- Tags provide flexible discovery without forcing rigid categorization

**Database Schema** (Implemented):

The complete schema is available in [schema/schema.sql](../schema/schema.sql). Key tables:

```
Offers (self-contained auction listings)
- id (PK)
- title, description, condition
- starting_price, current_price
- start_time, end_time, status
- seller information
- image_urls (array)
- view_count, bid_count
- Automatic triggers for bid management

Bids (complete audit trail)
- id (PK)
- offer_id (FK)
- bidder information
- amount, is_winning (auto-maintained)
- placed_at, status

Tags (flexible categorization)
- id (PK)
- name, description, category
- usage_count (auto-maintained)

OfferTags (many-to-many)
- offer_id (FK)
- tag_id (FK)
- added_by, added_at

Watches (user watchlist)
- id (PK)
- offer_id (FK), user_id
- created_at
```

**Database Features**:
- Automatic winning bid determination via triggers
- Incremental counters (O(1) performance)
- Compound indexes for hot queries
- Views for common query patterns
- Full-text search support (documented)

## Data Flow

### Product Scraping Flow
1. Scraping service runs on schedule
2. Fetches auction listings from target sites
3. Parses HTML and extracts product data
4. Stores products and auctions in database
5. Triggers price comparison service
6. Updates alert conditions

### Price Comparison Flow
1. Product data received
2. Query external price sources
3. Calculate price differences
4. Store historical price data
5. Return comparison results

### Alert Flow
1. Alert service monitors conditions
2. Checks auction end times
3. Checks price thresholds
4. Triggers notifications when conditions met
5. Updates alert status

## Security Considerations

- **Authentication**: JWT-based authentication
- **Authorization**: Role-based access control
- **Input Validation**: Sanitize all user inputs
- **Password Storage**: Bcrypt hashing
- **API Security**: Rate limiting, CORS configuration
- **Scraping Ethics**: Respect robots.txt, implement delays

## Scalability Considerations

- **Database**: PostgreSQL with standard scaling patterns (read replicas, partitioning - see [DATABASE_DESIGN.md](DATABASE_DESIGN.md))
- **Caching**: Implement Redis for frequently accessed data
- **Async Processing**: Use task queues (Celery) for scraping jobs
- **API**: Design for horizontal scaling
- **Rate Limiting**: Protect API endpoints

## Development Phases

### Phase 1: Foundation (Current)
- Project setup and planning
- Architecture design
- Technology selection

### Phase 2: Core Backend
- Database setup
- Basic API implementation
- Authentication system

### Phase 3: Scraping Module
- Scraper implementation
- Rate limiting
- Data extraction

### Phase 4: Frontend
- UI implementation
- API integration
- User workflows

### Phase 5: Advanced Features
- Price comparison
- Alert system
- Notifications

### Phase 6: Production
- Testing
- Deployment
- Monitoring

## Technology Stack Summary

| Component | Technology |
|-----------|-----------|
| Frontend | Vanilla JavaScript, HTML5, CSS3 |
| Backend | Python (Flask/FastAPI) |
| Database | **PostgreSQL** ✅ (see DATABASE_DESIGN.md) |
| ORM | SQLAlchemy |
| Scraping | BeautifulSoup4, Scrapy, or Selenium |
| API | RESTful |
| Auth | JWT |
| Task Queue | Celery (future) |
| Cache | Redis (future) |

## Deployment Architecture (Future)

```
Internet
    │
    ├─→ Web Server (Nginx/Apache)
    │       │
    │       ├─→ Static Files (Frontend)
    │       └─→ Reverse Proxy → Backend API
    │
    └─→ Application Server (Gunicorn/uWSGI)
            │
            └─→ Python Backend
                    │
                    ├─→ Database (PostgreSQL)
                    ├─→ Cache (Redis)
                    └─→ Task Queue (Celery Workers)
```

## Conclusion

This architecture provides a solid foundation for the jptracker application with clear separation of concerns, scalability, and maintainability. The modular design allows for incremental development and future enhancements.
