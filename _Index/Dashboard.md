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

## 🤝 Social

```dataviewjs
renderHeatmapCalendar(this.container, {
  year: new Date().getFullYear(),
  colors: {
    purple: ["#e0d7f5","#b8a9e8","#8f7cd6","#6650c4","#3d2b9e"]
  },
  entries: dv.pages('"Daily/Life/Notes"')
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
