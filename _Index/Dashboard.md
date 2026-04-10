---
title: Dashboard
type: index
updated: YYYY-MM-DD
---

# Dashboard

---

## Today

- 📓 Daily note
- ✅ Todo

---

## Upcoming

| Date | Event |
|---|---|
| YYYY-MM-DD | Event name |

---

## Progress

```apb
[[group]] Sprint
Sprint Name: YYYY-MM-DD||YYYY-MM-DD
```

```apb
[[group]] Finance
Emergency Fund: 0/30000
```

---

## Life Pulse

| Area | Status |
|---|---|
| 💰 Finance | — |
| ❤️ Relationship | — |
| 🏥 Health | — |

---

## 🧱 Friction (Last 14 Days)

```dataviewjs
const cutoff = new Date();
cutoff.setDate(cutoff.getDate() - 14);
const cutoffStr = cutoff.toISOString().slice(0, 10);

const pages = dv.pages('"Daily/Notes"')
  .where(p => p.file.name >= cutoffStr)
  .sort(p => p.file.name, 'desc');

const rows = [];
for (const page of pages) {
  const content = await dv.io.load(page.file.path);
  const lines = content.split('\n');
  for (const line of lines) {
    if (line.includes('#friction')) {
      const clean = line.replace(/^[-*>\s]+/, '').replace(/#friction/g, '').trim();
      if (clean) rows.push([page.file.link, clean]);
    }
  }
}

if (rows.length === 0) {
  dv.paragraph("No friction logged in the last 14 days.");
} else {
  dv.table(["Date", "Item"], rows);
}
```

→ [[_Index/Friction Log]] for full history

---

## 🤝 Social

```dataviewjs
renderHeatmapCalendar(this.container, {
  year: new Date().getFullYear(),
  colors: {
    purple: ["#e0d7f5","#b8a9e8","#8f7cd6","#6650c4","#3d2b9e"]
  },
  entries: dv.pages('"Daily/Notes"')
    .where(p => p.social !== undefined && p.social > 0)
    .map(p => ({
      date: p.file.name,
      intensity: p.social,
      content: `[[${p.file.path}|📅]]`
    })).array()
})
```

---

## Work Projects

| Project | Status | Note |
|---|---|---|
| | | |

---

## Personal Projects

| Project | Status | Note |
|---|---|---|
| | | |
