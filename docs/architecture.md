# Architecture - jptracker

## System Overview

jptracker is an auction tracking application designed to monitor and manage unique auction offers and their associated bids. The system follows a modern web application architecture with clear separation between frontend and backend components.

## Core Design Principles

### 1. Uniqueness First
Every auction offer is treated as a unique entity because:
- Each has different condition (new, used, refurbished, etc.)
- Same product from different sellers is effectively different
- Temporal uniqueness - offers don't recur
- Specific item variations (color, size, bundle contents)

### 2. Flexible Relationships
While offers are unique, we support discovering related items through:
- **Tags**: User-generated and system-generated categorization
- **Similarity**: Tag-based similarity matching
- **History**: Bid patterns and user behavior analysis

### 3. Data Integrity
Using a relational database ensures:
- Atomic bid operations (critical for auctions)
- Referential integrity between bids and offers
- Transaction support for concurrent bidding
- Audit trail preservation

## System Architecture Layers

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
│  │  SQLite (Development) → PostgreSQL (Production)        │  │
│  │  Schema with triggers, indexes, and views              │  │
│  │  See: DATABASE_DESIGN.md for details                   │  │
│  └───────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

## Component Details

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

**Database Evolution Path**: SQLite → PostgreSQL

#### Phase 1: Development & Initial Releases (SQLite)

**Technology**: SQLite

**Why SQLite for Development**:
- **Zero Configuration**: No server setup required
- **Portable**: Single file database, easy to version control for schema
- **Fast Development**: Instant setup, perfect for local development
- **Sufficient for MVP**: Handles thousands of offers and bids easily
- **Same SQL Syntax**: Easy migration path to PostgreSQL later

**Recommended for**:
- Local development environment
- Initial testing and prototyping
- First release (low traffic, < 1000 users)
- Demo and staging environments

**SQLite Limitations to Watch**:
- Concurrent writes (bidding might need careful handling)
- No built-in replication
- Limited scaling for high traffic

#### Phase 2: Production & Scaling (PostgreSQL)

**Technology**: PostgreSQL

**Why PostgreSQL for Production**:
- **Concurrent Bidding**: Excellent support for concurrent writes with MVCC
- **Scalability**: Read replicas, connection pooling, partitioning
- **Advanced Features**: Better indexing, full-text search, JSONB support
- **Reliability**: Industry-proven for high-traffic auction sites
- **Extensions**: PostGIS, pg_trgm for fuzzy search, etc.

**Migration Path**:
1. **Design Phase**: Use PostgreSQL-compatible SQL (done ✅)
2. **Development**: Use SQLite for simplicity
3. **Pre-Production**: Test with PostgreSQL in staging
4. **Migration**: Export SQLite data, import to PostgreSQL
5. **Production**: Deploy with PostgreSQL

**When to Migrate**:
- Before public launch (if expecting > 1000 users)
- When concurrent bidding becomes slow
- When you need read replicas for analytics
- When scaling beyond single server

## Data Model

### Core Entities

```
┌─────────────┐
│   Offers    │ ◄────────┐
│ (Primary)   │          │
└──────┬──────┘          │
       │                 │
       │ 1              │
       │                │
       │ *              │
┌──────▼──────┐    ┌────┴──────┐
│    Bids     │    │   Tags    │
└─────────────┘    └────┬──────┘
                        │
                        │ *
                   ┌────▼──────┐
                   │ OfferTags │
                   └───────────┘
```

### Entity Descriptions

**Offers**: Independent auction listings with complete product information embedded
- Self-contained (title, description, condition, images)
- No dependency on product master catalog
- Full lifecycle tracking (active → ended → sold/cancelled)

**Bids**: Historical record of all bidding activity
- Immutable audit trail
- Supports proxy/autobidding systems
- Tracks winning bid status (auto-maintained via triggers)

**Tags**: Flexible categorization vocabulary
- No predefined taxonomy
- Emergent from actual usage
- Optional categorization (brand, type, condition, etc.)

**OfferTags**: Many-to-many relationship enabling:
- Multiple tags per offer
- Tags shared across offers
- Discovery of related items

### Database Schema

The complete schema is available in [schema/schema.sql](../schema/schema.sql). Key tables:

```sql
Offers (self-contained auction listings)
- id (PK)
- title, description, condition
- starting_price, current_price
- start_time, end_time, status
- seller information
- image_urls (array) -- PostgreSQL feature, stored as TEXT in SQLite
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
- Full-text search support (see FAQ.md)

## Why Relational DB Despite Unique Offers

### Problem: Offers Don't Repeat
**Traditional Approach**: Normalize into product catalog
- **Issue**: Over-normalization creates brittle dependencies
- **Issue**: Catalog becomes cluttered with one-time items
- **Issue**: Variations hard to model (condition, bundling, etc.)

**Our Approach**: Treat offers as independent entities
- ✓ Each offer stands alone
- ✓ No forced categorization
- ✓ Natural fit for unique items
- ✓ Flexible enough for future patterns

### Solution: Optional Relationships via Tags
**Benefits**:
- Discover similar items without rigid structure
- Tags emerge organically from usage
- Users can find "items like this" despite uniqueness
- System can suggest tags based on title/description
- Analytics possible without predefined categories

### Relational DB Advantages

1. **Query Flexibility**
   ```sql
   -- Find my active bids
   -- Complex joins, filtering, sorting
   SELECT o.*, b.amount 
   FROM offers o 
   JOIN bids b ON o.id = b.offer_id 
   WHERE b.bidder_id = 'user123' 
     AND o.status = 'active'
   ORDER BY o.end_time;
   ```

2. **Data Integrity**
   - Can't bid on non-existent offers
   - Can't orphan bids when offers are deleted
   - Constraints ensure valid prices, dates

3. **Transactions**
   ```sql
   -- Place bid atomically
   BEGIN;
     INSERT INTO bids (...) VALUES (...);
     UPDATE offers SET current_price = ..., bid_count = bid_count + 1;
     UPDATE bids SET is_winning = false WHERE offer_id = ... AND id != ...;
   COMMIT;
   ```

4. **Performance**
   - Indexes on common queries (active offers, user bids, ending soon)
   - Efficient joins for finding similar items via tags
   - Aggregate queries for analytics

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

### Development Phase (SQLite)
- Single file database
- No server management
- Perfect for local development
- Suitable for MVP and early releases

### Production Phase (PostgreSQL)
- **Read Replicas**: For reporting and analytics
- **Partitioning**: Time-based (current vs historical offers)
- **Caching**: Redis for hot data (active offers, trending tags)
- **Archive Strategy**: Move ended offers to cold storage
- **Connection Pooling**: PgBouncer for efficient connection management

## Development Phases

### Phase 1: Foundation (Current - SQLite)
- [x] Project setup and planning
- [x] Database schema design
- [x] Architecture design
- [ ] Development environment setup (SQLite)
- [ ] Initial design mockups

### Phase 2: Core Backend (SQLite)
- [ ] Database implementation (SQLite + SQLAlchemy)
- [ ] Basic API structure
- [ ] Authentication system
- [ ] API endpoint scaffolding
- [ ] ORM models

### Phase 3: Scraping Module (SQLite)
- [ ] Scraper architecture
- [ ] Rate limiting implementation
- [ ] Target site analysis
- [ ] Scraper development
- [ ] Testing and validation

### Phase 4: Core Features (SQLite)
- [ ] Product management API
- [ ] Price comparison integration
- [ ] Bid tracking implementation
- [ ] Alert system foundation
- [ ] Background job setup

### Phase 5: Frontend Development (SQLite)
- [ ] UI/UX design
- [ ] HTML/CSS implementation
- [ ] JavaScript modules
- [ ] API integration
- [ ] User workflows

### Phase 6: Testing & Optimization (SQLite)
- [ ] End-to-end testing
- [ ] Bug fixes
- [ ] Performance optimization
- [ ] Security review
- [ ] Documentation completion

### Phase 7: Migration to PostgreSQL
- [ ] Set up PostgreSQL staging environment
- [ ] Test schema with PostgreSQL
- [ ] Verify trigger compatibility
- [ ] Load testing with PostgreSQL
- [ ] Data migration scripts
- [ ] Update deployment configuration

### Phase 8: Production Deployment (PostgreSQL)
- [ ] Production PostgreSQL setup
- [ ] Migrate data from SQLite
- [ ] Deployment automation
- [ ] Monitoring setup
- [ ] Launch

## Technology Stack Summary

| Component | Technology |
|-----------|-----------|
| Frontend | Vanilla JavaScript, HTML5, CSS3 |
| Backend | Python (Flask/FastAPI) |
| Database (Dev) | **SQLite** |
| Database (Prod) | **PostgreSQL** |
| ORM | SQLAlchemy |
| Scraping | BeautifulSoup4, Scrapy, or Selenium |
| API | RESTful |
| Auth | JWT |
| Task Queue | Celery (future) |
| Cache | Redis (future) |

## Deployment Architecture

### Development
```
Developer Machine
    │
    ├─→ Python Backend (Flask/FastAPI)
    │       │
    │       └─→ SQLite Database (single file)
    │
    └─→ Frontend (served locally)
```

### Production (Future)
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

## Implementation Recommendations

### Phase 1: Core Functionality (SQLite)
- [x] Design schema with offers, bids, tags
- [ ] Implement offer creation and listing
- [ ] Implement bidding system with atomic operations
- [ ] Build tag management
- [ ] Test with SQLite

### Phase 2: Discovery (SQLite)
- [ ] Tag suggestion based on offer content
- [ ] "Similar offers" using tag matching
- [ ] Search with tag filtering

### Phase 3: Analytics (SQLite)
- [ ] Price trend analysis
- [ ] Bidding pattern insights
- [ ] Popular tags and categories

### Phase 4: Migration Preparation
- [ ] Set up PostgreSQL staging
- [ ] Test all features with PostgreSQL
- [ ] Optimize queries for PostgreSQL
- [ ] Write migration scripts

### Phase 5: Production (PostgreSQL)
- [ ] Deploy with PostgreSQL
- [ ] Set up read replicas
- [ ] Implement caching
- [ ] Add monitoring and logging

## SQLite vs PostgreSQL: Key Differences

### Syntax Compatibility
The schema is designed to be compatible with both databases:
- Standard SQL data types used
- Triggers work in both (with minor syntax adjustments)
- Array types: PostgreSQL native, TEXT in SQLite
- JSON types: JSONB in PostgreSQL, TEXT in SQLite

### When to Use Which

**Use SQLite for**:
- ✅ Local development
- ✅ Testing and CI/CD
- ✅ MVP and initial release
- ✅ < 1000 concurrent users
- ✅ < 100 requests/second

**Migrate to PostgreSQL when**:
- ⚠️ Concurrent bidding becomes slow
- ⚠️ Need read replicas for analytics
- ⚠️ Expecting > 1000 concurrent users
- ⚠️ Need advanced features (full-text search, JSONB)
- ⚠️ Scaling beyond single server

## Conclusion

This architecture provides a pragmatic path from development to production:

1. **Start Simple**: Use SQLite for rapid development
2. **Design for Future**: Schema works with both SQLite and PostgreSQL
3. **Migrate When Needed**: Clear path to PostgreSQL when scaling
4. **Battle-Tested**: Both databases proven for auction systems

The key insight: **uniqueness of offers doesn't preclude relational storage**. The relationships that matter (bids to offers, tags to offers) are well-defined and benefit from SQL's strengths in both SQLite and PostgreSQL.

For detailed database design rationale, see [DATABASE_DESIGN.md](DATABASE_DESIGN.md).  
For implementation details, see [schema/schema.sql](../schema/schema.sql).  
For setup instructions, see [MIGRATION_GUIDE.md](MIGRATION_GUIDE.md).
