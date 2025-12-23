-- Create audit_events table
CREATE TABLE IF NOT EXISTS audit_events (
    id BIGSERIAL PRIMARY KEY,
    event_type VARCHAR(255) NOT NULL,
    entity_type VARCHAR(255) NOT NULL,
    entity_id BIGINT NOT NULL,
    user_id VARCHAR(255),
    details TEXT,
    timestamp TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_entity_type_id ON audit_events(entity_type, entity_id);
CREATE INDEX IF NOT EXISTS idx_user_id ON audit_events(user_id);
CREATE INDEX IF NOT EXISTS idx_timestamp ON audit_events(timestamp);
CREATE INDEX IF NOT EXISTS idx_event_type ON audit_events(event_type);

