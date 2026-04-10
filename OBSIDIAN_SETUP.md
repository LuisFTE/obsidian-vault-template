# Obsidian Setup Guide

This guide walks you through configuring Obsidian and all required plugins after cloning the vault. Follow each step in order.

---

## 1. Open the vault

In Obsidian: **Open folder as vault** → select the cloned repo folder.

---

## 2. Install community plugins

Go to **Settings → Community plugins → Turn on community plugins**, then **Browse** and install each of the following:

| Plugin | Why |
|---|---|
| **Obsidian Git** | Auto push/pull to GitHub |
| **Dataview** | Powers the social heatmap and todo queries |
| **Heatmap Calendar** | Renders the social activity heatmap |
| **Calendar** | Sidebar date nav + daily note creation |
| **Advanced Progress Bars** | Sprint countdown and goal progress bars |

Enable each plugin after installing.

> **Optional:** Remotely Save (Google Drive backup for Claude chat access). Not required for core functionality.

---

## 3. Configure Obsidian Git

**Settings → Community plugins → Obsidian Git → Options**

| Setting | Value |
|---|---|
| Sync method | Rebase |
| Merge strategy (pull) | Theirs |
| Auto pull interval | 15 minutes |
| Auto push interval | 15 minutes |
| Pull on startup | On |
| Auto backup after file change | On |
| Changes before auto backup | 1 |
| Disable popups for no changes | On |

**On mobile** (iPhone/Android): same settings. Sync method may not be exposed — that's fine, `theirs` covers conflicts.

---

## 4. Configure Calendar plugin

**Settings → Community plugins → Calendar → Options**

| Setting | Value |
|---|---|
| Week starts on | Monday |
| Confirm before creating new note | Off |

---

## 5. Configure Dataview plugin

**Settings → Community plugins → Dataview → Options**

| Setting | Value |
|---|---|
| Enable DataviewJS | On |
| Enable inline DataviewJS | On |
| Enable inline Dataview | On |
| Render inline fields in Live Preview | On |

---

## 6. Configure Daily Notes (core plugin)

**Settings → Core plugins → Daily notes → Options**

| Setting | Value |
|---|---|
| Date format | `YYYY-MM-DD` |
| New file location | `Daily/Notes` |
| Template file location | `_Templates/Daily Life Note` |

---

## 7. Configure Advanced Progress Bars

No manual configuration needed — the plugin reads settings from `apb` code blocks in your notes. The bars in Dashboard and Now.md will render automatically once the plugin is enabled.

---

## 8. Fill in `_Index/Now.md`

This is the AI's entry point every session. Replace the placeholder content with your own:

- Who you are (name, role, location)
- Current sprint name, start date, end date (used by the sprint header script)
- Current projects and their status
- Life areas: finance, health, relationships

Keep it current — the agents read this first on every run.

**Required frontmatter fields** (used by scripts):
```yaml
sprint_name: Your Sprint Name
sprint_start: YYYY-MM-DD
sprint_end: YYYY-MM-DD
```

---

## 9. Verify git is connected

Open the Obsidian Git panel (ribbon icon or `Cmd/Ctrl+P` → "Open source control view"). You should see your repo connected. Try a manual pull to confirm.

---

## You're set up

Once the agents are running (see AGENTS.md), the vault maintains itself. Write in your daily note — the agents handle the rest.
