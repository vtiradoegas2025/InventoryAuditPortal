-- Create inventory_items table
CREATE TABLE IF NOT EXISTS inventory_items (
    id BIGSERIAL PRIMARY KEY,
    sku VARCHAR(255) NOT NULL UNIQUE,
    name VARCHAR(255) NOT NULL,
    qty INTEGER NOT NULL,
    location VARCHAR(255) NOT NULL,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_sku ON inventory_items(sku);
CREATE INDEX IF NOT EXISTS idx_location ON inventory_items(location);
CREATE INDEX IF NOT EXISTS idx_updated_at ON inventory_items(updated_at);
CREATE INDEX IF NOT EXISTS idx_location_updated ON inventory_items(location, updated_at);

