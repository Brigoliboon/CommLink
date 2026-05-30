const express = require('express');
const { Pool } = require('pg');
const cors = require('cors');
require('dotenv').config();

const app = express();
const port = process.env.PORT || 3000;

app.use(cors());
app.use(express.json());

const pool = new Pool({
  host: process.env.PG_HOST || 'localhost',
  port: process.env.PG_PORT || 5432,
  database: process.env.PG_DATABASE || 'commlink',
  user: process.env.PG_USER || 'postgres',
  password: process.env.PG_PASSWORD || 'postgres',
});

const initDatabase = async () => {
  const client = await pool.connect();
  try {
    await client.query(`
      CREATE TABLE IF NOT EXISTS devices (
        id SERIAL PRIMARY KEY,
        fingerprint VARCHAR(255) UNIQUE NOT NULL,
        name VARCHAR(255) NOT NULL,
        ip_address VARCHAR(45) NOT NULL,
        channel INTEGER DEFAULT 1,
        is_online BOOLEAN DEFAULT true,
        last_seen TIMESTAMP DEFAULT NOW(),
        created_at TIMESTAMP DEFAULT NOW()
      )
    `);

    await client.query(`
      CREATE TABLE IF NOT EXISTS transmissions (
        id SERIAL PRIMARY KEY,
        from_fingerprint VARCHAR(255) NOT NULL,
        from_name VARCHAR(255) NOT NULL,
        channel INTEGER NOT NULL,
        duration_ms INTEGER NOT NULL,
        created_at TIMESTAMP DEFAULT NOW()
      )
    `);

    await client.query(`
      CREATE INDEX IF NOT EXISTS idx_devices_channel ON devices(channel)
    `);

    await client.query(`
      CREATE INDEX IF NOT EXISTS idx_transmissions_channel ON transmissions(channel)
    `);

    console.log('Database tables initialized');
  } catch (err) {
    console.error('Error initializing database:', err);
  } finally {
    client.release();
  }
};

app.get('/api/health', (req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

app.post('/api/devices', async (req, res) => {
  const { name, fingerprint, ip_address, channel } = req.body;
  try {
    const result = await pool.query(
      `INSERT INTO devices (name, fingerprint, ip_address, channel, is_online)
       VALUES ($1, $2, $3, $4, true)
       ON CONFLICT (fingerprint) DO UPDATE SET
         name = EXCLUDED.name,
         ip_address = EXCLUDED.ip_address,
         channel = EXCLUDED.channel,
         is_online = true,
         last_seen = NOW()
       RETURNING *`,
      [name, fingerprint, ip_address, channel || 1]
    );
    res.status(201).json(result.rows[0]);
  } catch (err) {
    console.error('Error registering device:', err);
    res.status(500).json({ error: 'Failed to register device' });
  }
});

app.get('/api/devices', async (req, res) => {
  const { channel } = req.query;
  try {
    let query = 'SELECT * FROM devices WHERE is_online = true';
    const params = [];

    if (channel) {
      query += ' AND channel = $1';
      params.push(channel);
    }

    query += ' ORDER BY last_seen DESC';
    const result = await pool.query(query, params);
    res.json(result.rows);
  } catch (err) {
    console.error('Error getting devices:', err);
    res.status(500).json({ error: 'Failed to get devices' });
  }
});

app.put('/api/devices/:fingerprint', async (req, res) => {
  const { fingerprint } = req.params;
  const { is_online } = req.body;
  try {
    const result = await pool.query(
      `UPDATE devices SET is_online = $1, last_seen = NOW()
       WHERE fingerprint = $2 RETURNING *`,
      [is_online, fingerprint]
    );
    res.json(result.rows[0]);
  } catch (err) {
    console.error('Error updating device:', err);
    res.status(500).json({ error: 'Failed to update device' });
  }
});

app.delete('/api/devices/:fingerprint', async (req, res) => {
  const { fingerprint } = req.params;
  try {
    await pool.query('DELETE FROM devices WHERE fingerprint = $1', [fingerprint]);
    res.json({ message: 'Device deleted' });
  } catch (err) {
    console.error('Error deleting device:', err);
    res.status(500).json({ error: 'Failed to delete device' });
  }
});

app.post('/api/transmissions', async (req, res) => {
  const { from_fingerprint, from_name, channel, duration_ms } = req.body;
  try {
    const result = await pool.query(
      `INSERT INTO transmissions (from_fingerprint, from_name, channel, duration_ms)
       VALUES ($1, $2, $3, $4) RETURNING *`,
      [from_fingerprint, from_name, channel, duration_ms]
    );
    res.status(201).json(result.rows[0]);
  } catch (err) {
    console.error('Error recording transmission:', err);
    res.status(500).json({ error: 'Failed to record transmission' });
  }
});

app.get('/api/transmissions', async (req, res) => {
  const { channel, limit } = req.query;
  try {
    let query = 'SELECT * FROM transmissions';
    const params = [];

    if (channel) {
      query += ' WHERE channel = $1';
      params.push(channel);
    }

    query += ' ORDER BY created_at DESC';
    query += ` LIMIT $${params.length + 1}`;
    params.push(parseInt(limit) || 50);

    const result = await pool.query(query, params);
    res.json(result.rows);
  } catch (err) {
    console.error('Error getting transmissions:', err);
    res.status(500).json({ error: 'Failed to get transmissions' });
  }
});

initDatabase().then(() => {
  app.listen(port, '0.0.0.0', () => {
    console.log(`CommLink server running on port ${port}`);
    console.log(`Database: ${process.env.PG_DATABASE || 'commlink'}@${process.env.PG_HOST || 'localhost'}`);
  });
});