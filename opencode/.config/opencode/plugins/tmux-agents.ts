import type { Plugin } from "@opencode-ai/plugin"

export const TmuxAgentsPlugin: Plugin = async ({ $ }) => {
  if (!process.env.TMUX || !process.env.TMUX_PANE) return {}

  const statuses = new Map<string, "working" | "idle">()
  const permissions = new Map<string, string>()
  let lastStatus: "working" | "blocked" | "idle" | undefined
  let reportQueue = Promise.resolve()

  const aggregateStatus = (): "working" | "blocked" | "idle" => {
    if (permissions.size > 0) return "blocked"
    if ([...statuses.values()].some((status) => status === "working")) return "working"
    return "idle"
  }

  const report = () => {
    const status = aggregateStatus()
    if (status === lastStatus) return reportQueue
    lastStatus = status
    reportQueue = reportQueue
      .then(async () => {
        await $`tmux-agents report opencode ${status}`.quiet().nothrow()
      })
      .catch(() => {})
    return reportQueue
  }

  return {
    event: async ({ event }) => {
      switch (event.type) {
        case "session.status": {
          const status = event.properties.status.type === "idle" ? "idle" : "working"
          statuses.set(event.properties.sessionID, status)
          await report()
          break
        }
        case "session.idle":
          statuses.set(event.properties.sessionID, "idle")
          await report()
          break
        case "permission.asked":
          permissions.set(event.properties.id, event.properties.sessionID)
          await report()
          break
        case "permission.replied":
          permissions.delete(event.properties.requestID)
          await report()
          break
        case "session.deleted":
          statuses.delete(event.properties.info.id)
          for (const [requestID, sessionID] of permissions) {
            if (sessionID === event.properties.info.id) permissions.delete(requestID)
          }
          await report()
          break
      }
    },
  }
}
