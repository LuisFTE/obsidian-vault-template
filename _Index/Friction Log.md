---
title: Friction Log
type: index
tags: [index, friction, productivity]
---

# 🧱 Friction Log

Things you avoided, procrastinated on, or felt resistance toward — tagged `#friction` in daily notes.

Use this to spot patterns: what keeps showing up? What's worth addressing vs. letting go?

---

## All Friction Items

```dataviewjs
const pages = dv.pages('"Daily/Life/Notes"').sort(p => p.file.name, 'desc');
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
  dv.paragraph("No friction items found yet. Tag things with #friction in your daily notes.");
} else {
  dv.table(["Date", "Item"], rows);
}
```
