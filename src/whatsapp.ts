import makeWASocket, {
  useMultiFileAuthState,
  DisconnectReason,
  WASocket
} from '@whiskeysockets/baileys'
import QRCode from 'qrcode'
import { saveChat, saveContact } from './store/sqliteStore'

let sock: WASocket

export async function startWhatsAppClient() {
  const { state, saveCreds } = await useMultiFileAuthState('auth')
  sock = makeWASocket({
    auth: state,
  })

  sock.ev.on('connection.update', async ({ connection, lastDisconnect, qr }) => {
    if (qr) {
      console.log(await QRCode.toString(qr, { type: 'terminal', small: true }))
    }
    if (connection === 'close') {
      const shouldReconnect = (lastDisconnect?.error as any)?.output?.statusCode !== DisconnectReason.loggedOut
      console.log('Connection closed. Reconnecting:', shouldReconnect)
      if (shouldReconnect) {
        startWhatsAppClient()
      }
    } else if (connection === 'open') {
      console.log('WhatsApp connection opened.')
    }
  })

  sock.ev.on('chats.upsert', (chats) => {
    for (const chat of chats) {
      saveChat(chat.id, chat.name || '', Date.now())
    }
  })

  sock.ev.on('chats.update', (updates) => {
    for (const update of updates) {
      if (update.id) {
        const name = update.name || update.messages?.[0]?.message?.pushName
        saveChat(update.id, name, Date.now())
      }
    }
  })

  sock.ev.on('contacts.upsert', (contacts) => {
    for (const contact of contacts) {
      saveContact(contact.id, contact.name || contact.notify || '')
    }
  })


  sock.ev.on('creds.update', saveCreds)
}

export async function sendMessage(jid: string, message: string) {
  if (!sock) throw new Error('WhatsApp socket not initialized.')
  const formattedJid = jid.includes('@') ? jid : `${jid}@s.whatsapp.net`
  await sock.sendMessage(formattedJid, { text: message })
}

