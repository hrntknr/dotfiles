import { mkdir, appendFile } from "node:fs/promises"
import { join } from "node:path"

const version = "2026-05-09.2"

const logPath = join(process.env.XDG_STATE_HOME ?? join(process.env.HOME, ".local/state"), "opencode", "notification.log")
const externalURL = process.env.OPENCODE_EXTERNAL_URL

const sessionTitles = new Map()
const assistantMessageIDs = new Map()
const lastAssistantTexts = new Map()

const debug = async (message) => {
  try {
    await mkdir(join(logPath, ".."), { recursive: true })
    await appendFile(logPath, `${new Date().toISOString()} ${message}\n`)
  } catch {
  }
}

const truncate = (text, max = 180) => {
  if (!text) return ""
  const value = text.replace(/\s+/g, " ").trim()
  return value.length > max ? `${value.slice(0, max - 1)}…` : value
}

const firstParagraph = (text) => {
  return truncate(text?.split(/\n\s*\n/).map((part) => part.trim()).find(Boolean))
}

const setSessionTitle = (sessionID, title) => {
  const value = truncate(title, 80)
  if (value) sessionTitles.set(sessionID, value)
}

const notificationURL = (sessionID) => {
  if (!externalURL) return
  const url = new URL(externalURL)
  url.searchParams.set("session", sessionID)
  return url.toString()
}

const addAssistantMessageID = (sessionID, messageID) => {
  if (!messageID) return
  const ids = assistantMessageIDs.get(sessionID) ?? new Set()
  ids.add(messageID)
  assistantMessageIDs.set(sessionID, ids)
}

const setAssistantText = (sessionID, text) => {
  const value = firstParagraph(text)
  if (value) lastAssistantTexts.set(sessionID, value)
}

const notificationTitle = (sessionID) => `opencode: ${sessionTitles.get(sessionID) ?? "opencode"}`

const notify = async ($, { title, group, message }) => {
  const url = notificationURL(group)

  if (url) {
    await $`ntf --title ${title} --url ${url} --group ${group} ${message}`
  } else {
    await $`ntf --title ${title} --group ${group} ${message}`
  }
}

export const NotificationPlugin = async ({ client, $ }) => {
  return {
    event: async ({ event }) => {
      if (event.type === "session.idle") {
        const sessionID = event.properties.sessionID
        await debug(`session.idle version=${version} sessionID=${sessionID}`)

        try {
          const title = `opencode: ${sessionTitles.get(sessionID) ?? "opencode"}`
          const message = lastAssistantTexts.get(sessionID) ?? "作業が完了しました"

          await debug(`session.idle detail sessionID=${sessionID} ${JSON.stringify({
            title,
            message,
          })}`)
          await notify($, { title, group: sessionID, message })
          await debug(`session.idle notified sessionID=${sessionID} title=${title}`)
        } catch (error) {
          await debug(`session.idle detail failed sessionID=${sessionID} error=${error?.stack ?? error}`)
          await notify($, { title: "opencode", group: sessionID, message: "作業が完了しました" })
          await debug(`session.idle notified sessionID=${sessionID} detailed=false`)
        }
      }

      if (event.type === "session.created" || event.type === "session.updated") {
        setSessionTitle(event.properties.sessionID, event.properties.info?.title)
        await debug(`${event.type} sessionID=${event.properties.sessionID} title=${event.properties.info?.title ?? ""}`)
      }

      if (event.type === "message.updated") {
        if (event.properties.info?.role === "assistant" || event.properties.info?.type === "assistant") {
          addAssistantMessageID(event.properties.sessionID, event.properties.info.id)
        }
      }

      if (event.type === "message.part.updated") {
        const { sessionID, part } = event.properties
        if (part.type === "text" && assistantMessageIDs.get(sessionID)?.has(part.messageID)) {
          setAssistantText(sessionID, part.text)
        }
      }

      if (event.type === "session.next.text.ended") {
        setAssistantText(event.properties.sessionID, event.properties.text)
      }

      if (event.type === "permission.asked") {
        const { sessionID, permission, patterns } = event.properties
        const detail = patterns.length ? `${permission}: ${patterns.join(", ")}` : permission
        await notify($, { title: notificationTitle(sessionID), group: sessionID, message: `権限確認待ちです\n${truncate(detail)}` })
        await debug(`permission.asked notified sessionID=${sessionID} permission=${permission}`)
      }

      if (event.type === "question.asked") {
        const { sessionID, questions } = event.properties
        const question = questions[0]
        const options = question?.options?.map((option) => option.label).join(" / ")
        const detail = [
          firstParagraph(question?.question),
          options ? `選択肢: ${truncate(options)}` : "",
        ].filter(Boolean).join("\n")

        await notify($, { title: notificationTitle(sessionID), group: sessionID, message: `選択肢への回答待ちです\n${truncate(detail)}` })
        await debug(`question.asked notified sessionID=${sessionID}`)
      }
    },
  }
}
