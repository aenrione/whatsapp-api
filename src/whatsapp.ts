import makeWASocket, {
  useMultiFileAuthState,
  DisconnectReason,
  AnyMessageContent,
  WASocket
} from '@whiskeysockets/baileys'
import QRCode from 'qrcode'

let sock: WASocket

export async function startWhatsAppClient() {
  const { state, saveCreds } = await useMultiFileAuthState('auth')
  sock = makeWASocket({
    auth: state,
  })

  sock.ev.on('connection.update', async ({ connection, lastDisconnect, qr }) => {
    if (qr) {
      // as an example, this prints the qr code to the terminal
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

  sock.ev.on('creds.update', saveCreds)
}

export async function sendMessage(jid: string, message: string) {
  if (!sock) throw new Error('WhatsApp socket not initialized.')
  const formattedJid = jid.includes('@s.whatsapp.net') ? jid : `${jid}@s.whatsapp.net`
  await sock.sendMessage(formattedJid, { text: message })
}

