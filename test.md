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
| _Data 4_       | Data 5   | Data 6          |
| **Data 7**     | Data 8   | Data 9          |
|================|==========|=================|
| Footer row     | Data 10  | Data 11         |
|----------------|----------|-----------------|

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

Two footnotes, but[^4] on different words.[^5]


[^2]: First footnote.[^3]

[^3]: Nested footnote.

[^4]: First word.

[^5]: second word.

---

## Formatted Units Test

Testing the `units.html` include with various units defined in `_data/units.yml` and fallback behavior.

### Standard Units

- Temperature (Fahrenheit): {% units number="98.6" unit="F" %}

- Temperature (Celsius): {% units number="37" unit="C" %}

- Mass (Grams): {% units number="500" unit="g" %}

- Mass (Kilograms): {% units number="2.5" unit="kg" %}

- Length (Meters): {% units number="10" unit="m" %}

- Length (Centimeters): {% units number="175" unit="cm" %}

- Length (Millimeters): {% units number="35" unit="mm" %}

- Length (Inches): {% units number="6" unit="in" %}

- Length (Feet): {% units number="5.9" unit="ft" %}

### Different Numbers

- Zero: {% units number="0" unit="C" %}

- Negative: {% units number="-10" unit="C" %}

- Large Number: {% units number="1234567.89" unit="m" %}

### Fallback Test (Unit Not in Data File)

This unit 'XYZ' is not defined in `_data/units.yml`. In development mode, a
warning comment should appear in the HTML source. The output should fallback
to using 'XYZ' as both symbol and title.

- Undefined Unit: {% units number="42" unit="XYZ" %}

### In Footnotes

This sentence tests units within a footnote definition.[^unit_test]

[^unit_test]:
    The footnote definition contains a temperature: {% units
    number="22" unit="C" %} and a length: {% units number="1.8"
    unit="m" %}. It should render correctly within the footnote list.

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

## TV Show and Movie Titles

### TV

- <cite class="tv-show-title">Hard Time</cite>
- <cite class="tv-show-title">The Wire</cite>

### Movie

- <cite class="movie-title">Batman Begins</cite>
- <cite class="movie-title">Pacific Rim</cite>

---

## Games

### Video Games

- <cite class="video-game-title">Chrono Trigger</cite>
- <cite class="video-game-title">Disco Elysium</cite>
- <cite class="video-game-title">Final Fantasy VI</cite>

### Tabletop Games

- <cite class="table-top-game-title">Shadowrun</cite>
- <cite class="table-top-game-title">Warhammer 40,000</cite>

---

## Author Link

### Author That Exists

- {% author_link "Arthur C. Clarke" %}
- {% author_link "Arthur C. Clarke" possessive %}
- {% author_link "Arthur C. Clarke" link_text="Clarke" %}
- {% author_link "Arthur C. Clarke" possessive link_text="Clarke" %}

### Author That Doesn't Exists

- {% author_link "Nonexistent Author" %}
- {% author_link "Nonexistent Author" possessive %}
- {% author_link "Nonexistent Author" link_text="N. Author" %}
- {% author_link "Nonexistent Author" possessive link_text="N. Author" %}

---

## Book Link

### Book That Exists

- {% book_link "Childhood's End" %}
- {% book_link "Childhood's End" link_text="End" %}

### Book That Doesn't Exists

- {% book_link "Nonexistent Book" %}
- {% book_link "Nonexistent Book" link_text="This Book Doesn't Exist" %}

---

## Series Link

### Series That Exists

- {% series_link "Culture" %}

### Series That Doesn't Exist

- {% series_link "Nonexistent Series" %}

---

## Series Text Tag

### Add 'the' and 'series'

- {% series_text "Culture" %}
- {% series_text "Nonexistent" %}

### Add 'series'

- {% series_text "The Last Policeman" %}
- {% series_text "The Nonexistent" %}

### Add 'the'

- {% series_text "Hyperion Cantos" %}
- {% series_text "Nonexistent Series" %}

---

## Star Ratings

{% assign four=4 %}
{% assign five="5" %}
- {% rating_stars 1 %}
- {% rating_stars '2' %}
- {% rating_stars "3" %}
- {% rating_stars four %}
- {% rating_stars five %}

---

## Custom Book Review Test Section

<div class="book-page">
  <h1 class="page-title"><cite class="book-title">Test Book Title</cite></h1>

  <div class="written-by">
    By {% author_link "Vernor Vinge" %}
  </div>

  <div class="book-series-line">
    Book 2 of {% series_text "Test Series" %}
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
  {% rating_stars 5 %}

  This is a sample review of the book, demonstrating the inclusion of
  custom metadata, images, and dynamic content. The story revolves around a
  fascinating premise and is exceptionally well-written.
</article>
