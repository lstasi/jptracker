-- JPTracker Database Schema
-- Auction tracking system with flexible offer management

-- ============================================================================
-- OFFERS TABLE
-- Each offer represents a unique auction listing
-- Offers are treated as independent entities since each has unique conditions
-- ============================================================================
CREATE TABLE offers (
    id BIGSERIAL PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    
    -- Product details stored directly with the offer
    -- This avoids brittle dependencies on a product catalog
    -- since each offer is unique (different condition, seller, etc.)
    condition VARCHAR(50), -- e.g., 'new', 'like-new', 'used-good', 'used-fair'
    
    -- Pricing
    starting_price DECIMAL(10, 2) NOT NULL,
    current_price DECIMAL(10, 2) NOT NULL,
    buy_now_price DECIMAL(10, 2), -- Optional buy-it-now price
    reserve_price DECIMAL(10, 2), -- Optional reserve price (hidden)
    
    -- Timing
    start_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    end_time TIMESTAMP NOT NULL,
    
    -- Status
    status VARCHAR(20) NOT NULL DEFAULT 'active', -- active, ended, cancelled, sold
    
    -- Seller information (simplified - could be FK to users table if implementing user mgmt)
    seller_id VARCHAR(100),
    seller_name VARCHAR(255),
    
    -- Metadata
    image_urls TEXT[], -- Array of image URLs
    location VARCHAR(255),
    shipping_cost DECIMAL(10, 2),
    
    -- Tracking
    view_count INTEGER DEFAULT 0,
    bid_count INTEGER DEFAULT 0,
    
    -- Timestamps
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    -- Constraints for data validation
    CONSTRAINT check_end_time CHECK (end_time > start_time),
    CONSTRAINT check_prices CHECK (starting_price >= 0 AND current_price >= starting_price)
);

-- Indexes for efficient querying
CREATE INDEX idx_offers_status ON offers(status);
CREATE INDEX idx_offers_end_time ON offers(end_time);
CREATE INDEX idx_offers_seller ON offers(seller_id);
CREATE INDEX idx_offers_created_at ON offers(created_at);

-- ============================================================================
-- BIDS TABLE
-- Tracks all bids placed on offers
-- Maintains complete history for audit and analysis
-- NOTE: The is_winning flag and offer's current_price/bid_count are automatically
--       maintained by triggers when new bids are inserted. No manual updates needed.
-- ============================================================================
CREATE TABLE bids (
    id BIGSERIAL PRIMARY KEY,
    offer_id BIGINT NOT NULL,
    
    -- Bidder information
    bidder_id VARCHAR(100) NOT NULL,
    bidder_name VARCHAR(255),
    
    -- Bid details
    amount DECIMAL(10, 2) NOT NULL,
    is_winning BOOLEAN DEFAULT false, -- Denormalized for quick lookups
    is_autobid BOOLEAN DEFAULT false, -- Whether this was placed by autobid system
    max_autobid_amount DECIMAL(10, 2), -- Maximum autobid amount (if using proxy bidding)
    
    -- Timing
    placed_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    -- Status
    status VARCHAR(20) NOT NULL DEFAULT 'active', -- active, outbid, won, retracted
    
    FOREIGN KEY (offer_id) REFERENCES offers(id) ON DELETE CASCADE,
    CONSTRAINT check_bid_amount CHECK (amount > 0)
);

-- Indexes for efficient querying
CREATE INDEX idx_bids_offer_id ON bids(offer_id);
CREATE INDEX idx_bids_bidder_id ON bids(bidder_id);
CREATE INDEX idx_bids_placed_at ON bids(placed_at);
CREATE INDEX idx_bids_winning ON bids(offer_id, is_winning) WHERE is_winning = true;
-- Compound index for finding highest bid efficiently
CREATE INDEX idx_bids_offer_amount ON bids(offer_id, amount DESC, placed_at ASC);

-- ============================================================================
-- TAGS TABLE
-- Flexible categorization system for offers
-- Enables "soft" relationships between similar offers without enforcing rigid structure
-- ============================================================================
CREATE TABLE tags (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    category VARCHAR(50), -- Optional grouping (e.g., 'brand', 'product-type', 'condition')
    usage_count INTEGER DEFAULT 0, -- Track popularity
    
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT check_tag_name CHECK (LENGTH(name) >= 2)
);

CREATE INDEX idx_tags_name ON tags(name);
CREATE INDEX idx_tags_category ON tags(category);

-- ============================================================================
-- OFFER_TAGS TABLE
-- Many-to-many relationship between offers and tags
-- Allows flexible categorization and discovery of related offers
-- ============================================================================
CREATE TABLE offer_tags (
    offer_id BIGINT NOT NULL,
    tag_id INTEGER NOT NULL,
    
    -- Track who/what added this tag
    added_by VARCHAR(100), -- user_id or 'system' for auto-generated tags
    added_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    PRIMARY KEY (offer_id, tag_id),
    FOREIGN KEY (offer_id) REFERENCES offers(id) ON DELETE CASCADE,
    FOREIGN KEY (tag_id) REFERENCES tags(id) ON DELETE CASCADE
);

CREATE INDEX idx_offer_tags_tag_id ON offer_tags(tag_id);

-- ============================================================================
-- WATCHES TABLE (Optional)
-- Allows users to watch/follow specific offers
-- ============================================================================
CREATE TABLE watches (
    id BIGSERIAL PRIMARY KEY,
    offer_id BIGINT NOT NULL,
    user_id VARCHAR(100) NOT NULL,
    
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (offer_id) REFERENCES offers(id) ON DELETE CASCADE,
    UNIQUE(offer_id, user_id)
);

CREATE INDEX idx_watches_user_id ON watches(user_id);
CREATE INDEX idx_watches_offer_id ON watches(offer_id);

-- ============================================================================
-- VIEWS
-- Convenient views for common queries
-- ============================================================================

-- Active offers with current winning bid
CREATE VIEW active_offers_with_winning_bid AS
SELECT 
    o.*,
    b.amount as current_bid_amount,
    b.bidder_id as current_bidder_id,
    b.placed_at as last_bid_time
FROM offers o
LEFT JOIN bids b ON o.id = b.offer_id AND b.is_winning = true
WHERE o.status = 'active' AND o.end_time > CURRENT_TIMESTAMP;

-- Offer summary with tag list
CREATE VIEW offers_with_tags AS
SELECT 
    o.*,
    ARRAY_AGG(t.name) as tags
FROM offers o
LEFT JOIN offer_tags ot ON o.id = ot.offer_id
LEFT JOIN tags t ON ot.tag_id = t.id
GROUP BY o.id;

-- ============================================================================
-- FUNCTIONS
-- Utility functions for common operations
-- ============================================================================

-- Update the updated_at timestamp automatically
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_offers_updated_at BEFORE UPDATE ON offers
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Update tag usage count
CREATE OR REPLACE FUNCTION update_tag_usage_count()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE tags SET usage_count = usage_count + 1 WHERE id = NEW.tag_id;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE tags SET usage_count = usage_count - 1 WHERE id = OLD.tag_id;
    END IF;
    RETURN NULL;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_tag_usage_count_trigger
    AFTER INSERT OR DELETE ON offer_tags
    FOR EACH ROW EXECUTE FUNCTION update_tag_usage_count();

-- Update winning bid status automatically
-- When a new bid is placed, update is_winning flags for all bids on that offer
CREATE OR REPLACE FUNCTION update_winning_bid()
RETURNS TRIGGER AS $$
DECLARE
    winning_bid_id BIGINT;
    winning_bid_amount DECIMAL(10, 2);
    old_winning_bid_id BIGINT;
BEGIN
    -- Find the previously winning bid (to update efficiently)
    SELECT id INTO old_winning_bid_id
    FROM bids
    WHERE offer_id = NEW.offer_id AND is_winning = true
    LIMIT 1;
    
    -- Find the new winning bid (highest amount, earliest if tied)
    SELECT id, amount INTO winning_bid_id, winning_bid_amount
    FROM bids
    WHERE offer_id = NEW.offer_id
      AND status = 'active'
    ORDER BY amount DESC, placed_at ASC
    LIMIT 1;
    
    -- Update only the affected bids for efficiency
    -- Set old winning bid to false (if exists and different from new winner)
    IF old_winning_bid_id IS NOT NULL AND old_winning_bid_id != winning_bid_id THEN
        UPDATE bids SET is_winning = false WHERE id = old_winning_bid_id;
    END IF;
    
    -- Set new winning bid to true
    IF winning_bid_id IS NOT NULL THEN
        UPDATE bids SET is_winning = true WHERE id = winning_bid_id;
    END IF;
    
    -- Update the offer's current price to the winning bid amount (not NEW.amount)
    -- Increment bid_count (more efficient than COUNT(*) for high-volume auctions)
    UPDATE offers
    SET current_price = COALESCE(winning_bid_amount, starting_price),
        bid_count = bid_count + 1
    WHERE id = NEW.offer_id;
    
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_winning_bid_trigger
    AFTER INSERT ON bids
    FOR EACH ROW EXECUTE FUNCTION update_winning_bid();

-- ============================================================================
-- SAMPLE QUERIES
-- Examples of how to use this schema effectively
-- ============================================================================

-- Find similar offers using tags (despite each offer being unique)
-- Example: Find offers similar to offer ID 123
COMMENT ON TABLE offer_tags IS 
'Example query - Find similar offers:
SELECT o2.*, COUNT(ot2.tag_id) as matching_tags
FROM offers o1
JOIN offer_tags ot1 ON o1.id = ot1.offer_id
JOIN offer_tags ot2 ON ot1.tag_id = ot2.tag_id
JOIN offers o2 ON ot2.offer_id = o2.id
WHERE o1.id = 123 AND o2.id != 123
GROUP BY o2.id
ORDER BY matching_tags DESC
LIMIT 10;';

-- Find all offers with specific tags
COMMENT ON TABLE tags IS
'Example query - Find offers by tags:
SELECT o.*
FROM offers o
JOIN offer_tags ot ON o.id = ot.offer_id
JOIN tags t ON ot.tag_id = t.id
WHERE t.name IN (''electronics'', ''smartphone'')
  AND o.status = ''active''
ORDER BY o.end_time;';

-- User bid history
COMMENT ON TABLE bids IS
'Example query - User bid history:
SELECT o.title, b.amount, b.placed_at, b.status
FROM bids b
JOIN offers o ON b.offer_id = o.id
WHERE b.bidder_id = ''user123''
ORDER BY b.placed_at DESC;';
