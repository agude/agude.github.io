---
layout: default
title: Test Papge
description: >
  Test page to render all elements of my website.
sidebar_include: false
---

# Markdown Test Page

This is a test page to demonstrate all standard Markdown elements.

---

## Headings

# Heading Level 1
## Heading Level 2
### Heading Level 3
#### Heading Level 4
##### Heading Level 5
###### Heading Level 6

---

## Paragraphs

This is a simple paragraph.
This is another paragraph with **bold text**, *italic text*, and ***bold italic text***.

---

## Lists

### Unordered List

- Item 1
  - Subitem 1.1
  - Subitem 1.2
- Item 2
- Item 3

### Ordered List

1. First item
2. Second item
   1. Subitem 2.1
   2. Subitem 2.2
3. Third item

---

## Links

[Home](/)

---

## Images

![Alex Gude head shot](/files/headshot-small.jpg)

---

## Blockquotes

> This is a blockquote.
> It can span multiple lines.

---

## Tables

| Column 1 | Column 2 | Column 3 |
|----------|----------|----------|
| Data 1   | Data 2   | Data 3   |
| Data 4   | Data 5   | Data 6   |
| Data 7   | Data 8   | Data 9   |

---

## Horizontal Rule

---

## Task Lists

- [x] Task 1
- [ ] Task 2
- [ ] Task 3

---

## Emphasis

- **Bold**
- *Italic*
- ***Bold and Italic***
- ~~Strikethrough~~

---

## Escaping Characters

To display special characters, use a backslash:
\- \* \_ \` \[ \] \( \)

---

## Footnotes

This is a sentence with a footnote.[^1]

[^1]: This is the footnote text.

---

## HTML in Markdown

You can include raw HTML in Markdown:

<div style="color: blue; font-weight: bold;">This is raw HTML in Markdown</div>

---

## Custom Resume Markup Test Section

<div class="resume" markdown="1">

### Resume Subtitle

<div class="subtitle">Blogger, Balloon enthusiast</div>

### Resume Include Test

{% include resume_experience.html
company="Test Company"
location="Anywhere, USA"
position="Test Position"
dates="2022--Present"
position_2="Another Position"
dates_2="2020--2022"
%}

### Resume Skills Test

{% include resume_skills.html
languages='Python, Ruby, JavaScript'
tools="Docker, Kubernetes, Jenkins, Terraform"
%}

### Dynamic Date Test

This statement includes a dynamic year calculation:

I has been {{ "now" | date: "%Y" | minus: 1999 }} years since 1999.

</div> <!-- Close the resume div -->

---
