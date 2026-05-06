require('dotenv').config();
const postgres = require('postgres');

const connectionString = process.env.DATABASE_URL;

const sql = postgres(connectionString, {
  ssl: 'require' // important for Supabase cloud connections
});

module.exports = sql;
