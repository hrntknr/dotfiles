import { readdir, readFile } from "node:fs/promises";
import { join } from "node:path";

const commandDir = join(process.env.HOME ?? "", ".config/opencode/commands");
const returnsByCommand = new Map();
const sessions = new Map();

const frontmatterPattern = /^---\n([\s\S]*?)\n---/;

const listMarkdown = async (dir) => {
  try {
    const entries = await readdir(dir, { withFileTypes: true });
    const files = await Promise.all(
      entries.map(async (entry) => {
        const path = join(dir, entry.name);
        if (entry.isDirectory()) return listMarkdown(path);
        if (entry.isFile() && entry.name.endsWith(".md")) return [path];
        return [];
      }),
    );
    return files.flat();
  } catch {
    return [];
  }
};

const parseReturns = (frontmatter) => {
  const lines = frontmatter.split("\n");
  const start = lines.findIndex((line) => line === "return:");
  if (start === -1) return [];

  const returns = [];
  for (const line of lines.slice(start + 1)) {
    if (/^[a-zA-Z_-]+:/.test(line)) break;
    const item = line.match(/^\s*-\s*(.*)$/)?.[1]?.trim();
    if (item) returns.push(item);
  }
  return returns;
};

const loadCommands = async () => {
  returnsByCommand.clear();

  for (const file of await listMarkdown(commandDir)) {
    const text = await readFile(file, "utf8");
    const frontmatter = text.match(frontmatterPattern)?.[1];
    if (!frontmatter) continue;

    const returns = parseReturns(frontmatter);
    const command = file.replace(/\.md$/, "").split("/commands/").pop();
    if (command && returns.length) returnsByCommand.set(command, returns);
  }
};

const commandPart = (text) => {
  const match = text.match(/^\/([^\s]+)(?:\s+([\s\S]*))?$/);
  if (!match) return;
  return { command: match[1], arguments: match[2] ?? "" };
};

const processReturn = async (client, sessionID, state) => {
  const next = state.returns[state.index];
  if (!next) {
    sessions.delete(sessionID);
    return;
  }

  state.index += 1;

  const command = commandPart(next);
  if (command) {
    await client.session.command({ path: { id: sessionID }, body: command });
    return;
  }

  await client.session.promptAsync({
    path: { id: sessionID },
    body: { parts: [{ type: "text", text: next }] },
  });
};

export const ReturnPlugin = async ({ client }) => {
  await loadCommands();

  return {
    "command.execute.before": async (input) => {
      const returns = returnsByCommand.get(input.command);
      if (!returns?.length) return;

      sessions.set(input.sessionID, { returns, index: 0 });
    },

    event: async ({ event }) => {
      if (event.type !== "session.idle") return;

      const sessionID = event.properties.sessionID;
      const state = sessions.get(sessionID);
      if (state) await processReturn(client, sessionID, state);
    },
  };
};
