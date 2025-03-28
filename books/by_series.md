---
title: "Book Reviews: By Series"
short_title: Series
layout: page
permalink: /books/by-series/
book_topbar_include: true
description: "Alexander Gude's (short) book reviews."
---

Below you'll find short reviews of the books I've read, sorted by series.

{% include books_topbar.html %}

{% assign sorted_books = site.books | sort: "book_number" %}
{% include book_listing.html books=sorted_books %}
