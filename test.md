---
layout: default
title: Test Papge
description: >
  Test page to render all elements of my website.
sidebar_include: false
---

{% if jekyll.environment != "production" %}
{% comment %}Only generate this page when in dev.{% endcomment %}

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

[Link](/)

[_Italic Link_](/)

[**Bold Link**](/)

[**_Bold and Italic Link_**](/)

[~~Strikethrough Link~~](/)

[~~_Italic Strikethrough Link_~~](/)

[~~**Bold Strikethrough Link**~~](/)

[~~**_Bold and Italic Strikethrough Link_**~~](/)

---

## Images

![Alex Gude head shot](/files/headshot-small.jpg)

---

## Blockquotes

> This is a blockquote.
> It can span multiple lines.

> They can be really really really really really really really really really
> really really really really really long.

---

## Tables

| Left Justified | Centered | Right Justified |
|:---------------|:--------:|----------------:|
| Data 1         | Data 2   | Data 3          |
| Data 4         | Data 5   | Data 6          |
| Data 7         | Data 8   | Data 9          |

---

## Horizontal Rule

---

---

## Task Lists

- [x] Task 1
- [ ] Task 2
- [ ] Task 3

---

## Emphasis

- _Italic_
- **Bold**
- **_Bold and Italic_**
- ~~Strikethrough~~
- ~~_Italic Strikethrough_~~
- ~~**Bold Strikethrough**~~
- ~~**_Bold and Italic Strikethrough_**~~

---

## Escaping Characters

To display special characters, use a backslash:
\- \* \_ \` \[ \] \( \)

---

## Footnotes

This is a sentence with a footnote.[^1]

[^1]: This is the footnote text.

This is a sentence with **two footnotes**, one of which is reused!![^1][^long]

[^long]:
    This is a long long long footnote that wraps across multiple lines in both
    the HTML and Markdown.

This is a footnote within a footnote.[^2]


[^2]: First footnote.[^3]

[^3]: Nested footnote.

---

## Front Page Feed

{% include front_page_feed.html %}

---

## Custom Resume Markup Test Section

<div class="resume" markdown="1">

# Resume Person's Name

<div class="subtitle">Subtitle for Resume</div>

## Statement

I am highly accomplished, I can use templates to calculate dates: {{ "now" |
date: "%Y" | minus: 2015 }}.

## Experience Test

{% include resume_experience.html
  company="Company with Two Positions"
  location="Anywhere, USA"
  position="Test Position"
  dates="2022--Present"
  position_2="Another Position"
  dates_2="2020--2022"
%}

- Things that were done
- More things

{% include resume_experience.html
  company="Company with One Positions"
  location="Anywhere, USA"
  position="Test Position"
  dates="2015--2020"
%}

{% include resume_experience.html
  company="Company with Dateless Positions"
  location="Anywhere, USA"
  position="Test Position"
  dates="2015--2020"
  position_2="Another Position"
%}

## Resume Skills Test

{% include resume_skills.html
  languages='Python, Ruby, JavaScript'
  tools="Docker, Kubernetes, Jenkins, Terraform"
%}

## Education Test

{% include resume_experience.html
  company="University with Date"
  location="Anywhere, USA"
  position="PhD, Website Testing"
  dates="2010--2015"
%}

{% include resume_experience.html
  company="University without Date"
  location="Anywhere, USA"
  position="PhD, Website Testing"
%}

</div> <!-- Close the resume div -->

---

## Author Link

### Author That Exists

- {% include author_link.html name="Arthur C. Clarke" %}
- {% include author_link.html name="Arthur C. Clarke" possessive=true %}
- {% include author_link.html name="Arthur C. Clarke" link_text="Clarke" %}
- {% include author_link.html name="Arthur C. Clarke" possessive=true link_text="Clarke" %}

### Author That Doesn't Exists

- {% include author_link.html name="Nonexistent Author" %}
- {% include author_link.html name="Nonexistent Author" possessive=true %}
- {% include author_link.html name="Nonexistent Author" link_text="N. Author" %}
- {% include author_link.html name="Nonexistent Author" possessive=true link_text="N. Author" %}

---

## Book Link

### Book That Exists

- {% include book_link.html title="Childhood's End" %}
- {% include book_link.html title="Childhood's End" link_text="End" %}

### Book That Doesn't Exists

- {% include book_link.html title="Nonexistent Book" %}
- {% include book_link.html title="Nonexistent Book" link_text="This Book Doesn't Exist" %}

---

## Series Link

### Series That Exists

- {% include series_link.html series="Culture" %}

### Series That Doesn't Exist

- {% include series_link.html series="Nonexistent Series" %}

---

## Custom Book Review Test Section

<div class="book-page">
  <h1 class="page-title"><cite class="book-title">Test Book Title</cite></h1>

  <div class="written-by">
    By {% include author_link.html name="Vernor Vinge" %}
  </div>

  <div class="book-series-line">
    Book 2 of {% include get_series_text.html series="Test Series" %}
  </div>
</div>

<div class="floating-book-cover">
  <img class="book-cover-lead"
    src="/books/covers/a_fire_upon_the_deep.jpg"
    alt="Book cover of Test Book Title."
  >
</div>

<article class="page">
  <h2 class="book-review-headline">Review</h2>
  {% include book_rating.html rating=5 %}

  This is a sample review of the book, demonstrating the inclusion of
  custom metadata, images, and dynamic content. The story revolves around a
  fascinating premise and is exceptionally well-written.
</article>

{% endif %}
