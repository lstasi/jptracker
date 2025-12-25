# Database Migration Guide

## Initial Setup

### Prerequisites
- PostgreSQL 12 or higher (for array support and advanced features)
- Database user with CREATE privileges

### Creating the Database

```bash
# Create database
createdb jptracker

# Or via SQL
psql -U postgres
CREATE DATABASE jptracker;
\c jptracker
```

### Running the Schema

```bash
# Apply schema
psql -U your_user -d jptracker -f schema/schema.sql
```

## Schema Evolution Strategy

### Adding New Features

When adding new tables or columns, follow this pattern:

1. **Create migration file** (e.g., `schema/migrations/001_add_feature.sql`)
2. **Use transactions** to ensure all-or-nothing application
3. **Make changes backwards compatible** when possible

Example migration:
```sql
BEGIN;

-- Add new column with default value (backwards compatible)
ALTER TABLE offers ADD COLUMN auction_type VARCHAR(20) DEFAULT 'standard';

-- Add new index
CREATE INDEX idx_offers_auction_type ON offers(auction_type);

-- Record migration
INSERT INTO schema_migrations (version, description) 
VALUES (1, 'Add auction_type to offers');

COMMIT;
```

### Migration Tracking Table

Create this table to track applied migrations:

```sql
CREATE TABLE schema_migrations (
    version INTEGER PRIMARY KEY,
    description TEXT NOT NULL,
    applied_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);
```

## Sample Data for Testing

### Insert Test Offers

```sql
-- Active offer
INSERT INTO offers (title, description, condition, starting_price, current_price, end_time, seller_id, seller_name, status)
VALUES 
('iPhone 13 Pro 256GB - Excellent Condition', 
 'Barely used iPhone 13 Pro with original box and accessories', 
 'like-new', 
 650.00, 
 750.00, 
 NOW() + INTERVAL '3 days',
 'seller001',
 'John Doe',
 'active');

-- Another active offer
INSERT INTO offers (title, description, condition, starting_price, current_price, end_time, seller_id, seller_name, status)
VALUES 
('Samsung Galaxy S21 - Good Condition', 
 'Well maintained Galaxy S21, minor scratches on back', 
 'used-good', 
 350.00, 
 420.00, 
 NOW() + INTERVAL '2 days',
 'seller002',
 'Jane Smith',
 'active');
```

### Insert Test Tags

```sql
INSERT INTO tags (name, category) VALUES 
('smartphone', 'product-type'),
('apple', 'brand'),
('samsung', 'brand'),
('electronics', 'category'),
('mobile', 'category'),
('256gb', 'storage'),
('5g', 'feature');
```

### Link Offers to Tags

```sql
-- Tag iPhone offer
INSERT INTO offer_tags (offer_id, tag_id, added_by)
SELECT 1, id, 'system' FROM tags WHERE name IN ('smartphone', 'apple', 'electronics', 'mobile', '256gb', '5g');

-- Tag Samsung offer  
INSERT INTO offer_tags (offer_id, tag_id, added_by)
SELECT 2, id, 'system' FROM tags WHERE name IN ('smartphone', 'samsung', 'electronics', 'mobile', '5g');
```

### Insert Test Bids

```sql
-- Bids on iPhone
INSERT INTO bids (offer_id, bidder_id, bidder_name, amount, status)
VALUES 
(1, 'buyer001', 'Alice Johnson', 650.00, 'outbid'),
(1, 'buyer002', 'Bob Williams', 700.00, 'outbid'),
(1, 'buyer001', 'Alice Johnson', 750.00, 'active');

-- Update winning bid
UPDATE bids SET is_winning = true WHERE id = (
    SELECT id FROM bids WHERE offer_id = 1 ORDER BY amount DESC, placed_at ASC LIMIT 1
);

-- Bids on Samsung
INSERT INTO bids (offer_id, bidder_id, bidder_name, amount, status)
VALUES 
(2, 'buyer003', 'Charlie Brown', 350.00, 'outbid'),
(2, 'buyer004', 'Diana Prince', 400.00, 'outbid'),
(2, 'buyer003', 'Charlie Brown', 420.00, 'active');

-- Update winning bid
UPDATE bids SET is_winning = true WHERE id = (
    SELECT id FROM bids WHERE offer_id = 2 ORDER BY amount DESC, placed_at ASC LIMIT 1
);
```

## Useful Queries for Development

### Active Offers with Stats

```sql
SELECT 
    o.id,
    o.title,
    o.current_price,
    o.bid_count,
    o.end_time,
    ARRAY_AGG(t.name) as tags
FROM offers o
LEFT JOIN offer_tags ot ON o.id = ot.offer_id
LEFT JOIN tags t ON ot.tag_id = t.id
WHERE o.status = 'active'
GROUP BY o.id
ORDER BY o.end_time;
```

### Find Similar Offers

```sql
-- Find offers similar to offer ID 1 based on shared tags
WITH target_tags AS (
    SELECT tag_id FROM offer_tags WHERE offer_id = 1
)
SELECT 
    o.id,
    o.title,
    o.current_price,
    COUNT(ot.tag_id) as matching_tags
FROM offers o
JOIN offer_tags ot ON o.id = ot.offer_id
WHERE ot.tag_id IN (SELECT tag_id FROM target_tags)
  AND o.id != 1
  AND o.status = 'active'
GROUP BY o.id, o.title, o.current_price
ORDER BY matching_tags DESC, o.current_price ASC
LIMIT 5;
```

### User Bid History

```sql
SELECT 
    o.title,
    b.amount,
    b.placed_at,
    b.status,
    b.is_winning,
    o.current_price,
    o.status as offer_status
FROM bids b
JOIN offers o ON b.offer_id = o.id
WHERE b.bidder_id = 'buyer001'
ORDER BY b.placed_at DESC;
```

## Backup and Restore

### Backup

```bash
# Full database backup
pg_dump -U your_user jptracker > jptracker_backup.sql

# Schema only
pg_dump -U your_user --schema-only jptracker > schema_backup.sql

# Data only
pg_dump -U your_user --data-only jptracker > data_backup.sql
```

### Restore

```bash
# Restore full backup
psql -U your_user jptracker < jptracker_backup.sql
```

## Performance Tuning

### Analyze Query Performance

```sql
-- Enable timing
\timing on

-- Explain query plan
EXPLAIN ANALYZE
SELECT o.* FROM offers o
JOIN offer_tags ot ON o.id = ot.offer_id
JOIN tags t ON ot.tag_id = t.id
WHERE t.name = 'smartphone' AND o.status = 'active';
```

### Common Optimizations

1. **Regular VACUUM**: Keep statistics up to date
```sql
VACUUM ANALYZE offers;
VACUUM ANALYZE bids;
```

2. **Monitor Index Usage**
```sql
SELECT schemaname, tablename, indexname, idx_scan
FROM pg_stat_user_indexes
ORDER BY idx_scan;
```

3. **Archive Old Data**: Move ended offers to separate table
```sql
-- Create archive table
CREATE TABLE offers_archive (LIKE offers INCLUDING ALL);

-- Move old offers
INSERT INTO offers_archive 
SELECT * FROM offers 
WHERE status IN ('ended', 'sold', 'cancelled') 
  AND end_time < NOW() - INTERVAL '90 days';

-- Delete from main table
DELETE FROM offers 
WHERE status IN ('ended', 'sold', 'cancelled') 
  AND end_time < NOW() - INTERVAL '90 days';
```

## Monitoring

### Key Metrics to Track

```sql
-- Table sizes
SELECT 
    schemaname,
    tablename,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS size
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;

-- Active offers count
SELECT status, COUNT(*) FROM offers GROUP BY status;

-- Bid activity (last 24 hours)
SELECT COUNT(*) as bids_24h FROM bids WHERE placed_at > NOW() - INTERVAL '24 hours';

-- Most popular tags
SELECT t.name, t.usage_count 
FROM tags t 
ORDER BY t.usage_count DESC 
LIMIT 10;
```
