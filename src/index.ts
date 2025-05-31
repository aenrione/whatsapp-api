import express, { Request, Response } from 'express'
import { sendMessage, startWhatsAppClient } from './whatsapp'

const app = express()
const PORT = process.env.PORT || 3000

app.use(express.json())

app.post('/send', async (req: Request, res: Response): Promise<any> => {
  const { number, message } = req.body
  if (!number || !message) {
    return res.status(400).json({ error: 'Missing number or message' })
  }

  try {
    await sendMessage(number, message)
    res.status(200).json({ status: 'Message sent' })
  } catch (err) {
    console.error(err)
    res.status(500).json({ error: 'Failed to send message' })
  }
})

app.listen(PORT, async () => {
  console.log(`API running on http://localhost:${PORT}`)
  await startWhatsAppClient()
})

