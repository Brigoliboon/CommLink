CREATE TABLE IF NOT EXISTS devices (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    device_id VARCHAR(255) NOT NULL UNIQUE,
    full_name VARCHAR(255) NOT NULL
);

CREATE TABLE IF NOT EXISTS channels (
    id SERIAL PRIMARY KEY,
    channel_id INTEGER NOT NULL CHECK (channel_id >= 1 AND channel_id <= 5),
    device_id UUID NOT NULL REFERENCES devices(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    device_id UUID NOT NULL REFERENCES devices(id) ON DELETE CASCADE,
    ip VARCHAR(45) NOT NULL,
    login_time TIMESTAMP NOT NULL DEFAULT NOW()
);