import Database from 'better-sqlite3'
import { ChatIndexParams } from '../chats'

export type Chat = {
  jid: string;
  name: string | null;
  timestamp: string;
}

const db = new Database('whatsapp.db')

db.exec(`
  CREATE TABLE IF NOT EXISTS chats (
    jid TEXT PRIMARY KEY,
    name TEXT,
    timestamp INTEGER
  );

  CREATE TABLE IF NOT EXISTS contacts (
    jid TEXT PRIMARY KEY,
    name TEXT
  );
`)

// Upsert chat
export function saveChat(jid: string, name: string | null, timestamp: number) {
  console.log(`Saving chat: ${jid}, name: ${name}, timestamp: ${timestamp}`)
  db.prepare(`
    INSERT INTO chats (jid, name, timestamp)
    VALUES (?, ?, ?)
    ON CONFLICT(jid) DO UPDATE SET name=excluded.name, timestamp=excluded.timestamp
  `).run(jid, name, timestamp)
}

// Upsert contact
export function saveContact(jid: string, name: string | null) {
  console.log(`Saving contact: ${jid}, name: ${name}`)
  db.prepare(`
    INSERT INTO contacts (jid, name)
    VALUES (?, ?)
    ON CONFLICT(jid) DO UPDATE SET name=excluded.name
  `).run(jid, name)
}

// Query chats with search & pagination
export function getChats(params: ChatIndexParams) {
  const { name = '', jid = '', page = 1, limit = 20 } = params;
  const offset = (page - 1) * limit;

  let conditions: string[] = [];
  let placeholders: any[] = [];

  if (name) {
    conditions.push('name LIKE ?');
    placeholders.push(`%${name}%`);
  }

  if (jid) {
    conditions.push('jid LIKE ?');
    placeholders.push(jid);
  }

  const conditionString = conditions.join(' AND ');

  const stmt = db.prepare(`
    SELECT jid, name, timestamp FROM chats
    ${conditionString.length > 0 ? `WHERE ${conditionString}` : ''}
    ORDER BY timestamp DESC
    LIMIT ? OFFSET ?
  `);

  return stmt.all(...placeholders, limit, offset);
}

