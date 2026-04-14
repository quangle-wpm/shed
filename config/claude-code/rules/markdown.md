---
paths:
  - "**/*.md"
  - "**/*.mdx"
---

Keep each paragraph, list item, blockquote, and callout body as a single continuous line. MD013 is disabled — never break for line length. Breaks remain meaningful between paragraphs (blank line), list items, headings, code blocks, tables, frontmatter, and `<br>` (trailing `  ` or `\`). Prettier uses `proseWrap: "preserve"`, so your wrapping is cemented: single-line paragraphs yield clean word-level git diffs on re-edit; pre-wrapped ones produce noisy line-level diffs.
