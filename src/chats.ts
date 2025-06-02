import { Router } from 'express'
import { Chat, getChats } from './store/sqliteStore'

export type ChatIndexParams = {
  name?: string
  jid?: string
  page?: number
  limit?: number
}

const router = Router()

router.get('/chats', (req, res) => {
  const name = (req.query.name as string || '')
  const jid = (req.query.jid as string || '')
  const page = parseInt(req.query.page as string) || 1
  const limit = parseInt(req.query.limit as string) || 20

  const results = getChats({name, jid, page, limit}) as Chat[]
  // parse results timestamp
  results.forEach(chat => {
    chat.timestamp = new Date(chat.timestamp).toISOString()
  })
  res.json({
    page,
    limit,
    results
  })
})

export default router

