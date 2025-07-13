---
date: 2025-07-09
title: Explorers on the Moon
book_authors: Hergé
series: The Adventures of Tintin
book_number: 17
rating: 5
image: /books/covers/explorers_on_the_moon.jpg
---

<cite class="book-title">{{ page.title }}</cite>, by <span
class="author-name">{{ page.book_authors }}</span>, is the seventeenth book in
the <span class="book-series">{{ page.series }}</span>. It's the second part
of a two-book story arc where Tintin, Haddock, and Calculus land on the moon.

{% capture this_book %}<cite class="book-title">{{ page.title }}</cite>{% endcapture %}
{% capture the_author %}<span class="author-name">{{ page.book_authors }}</span>{% endcapture %}
{% capture the_authors %}<span class="author-name">{{ page.book_authors }}</span>'s{% endcapture %}
{% capture the_authors_lastname %}<span class="author-name">{{ page.book_authors | split: " " | last }}</span>{% endcapture %}
{% capture the_author_link %}{% author_link page.book_authors %}{% endcapture %}
{% capture the_authors_link %}{% author_link page.book_authors possessive %}{% endcapture %}
{% capture this_series %}{% series_text page.series %}{% endcapture %}

{% capture tt2 %}{% book_link "Tintin in the Congo" %}{% endcapture %}
{% capture tt4 %}{% book_link "Cigars of the Pharaoh" %}{% endcapture %}
{% capture tt8 %}{% book_link "King Ottokar's Sceptre" %}{% endcapture %}
{% capture tt16 %}{% book_link "Destination Moon" %}{% endcapture %}

{{ this_book }} is the second half of the story that started in {{ tt16 }}. It
improves upon the previous book in almost every way: it is a little less
verbose, there is more slapstick, and there are surprising twists that are
artfully wrapped up. The plot also moves along a little faster.

The artwork remains the highlight, with stark, accurate drawings of the
lunar landscape. {{ the_author }} also fills the pages with a lot of cool
machines, like the space suits, tank, and of course the rocket. Overall a
massive improvement over the sparse, sound-stage like setting drawn in {{ tt2
}}.

The plot of {{ this_book }} moves a little faster, and there are multiple
problems <!-- What's the right word for little digressions that come up and
have to be solved?-->, culminating with the discovery of the stowaway Jorgen
aided by the traitor Wolff. Jorge was first seen in {{ tt8 }}, which suggests
that the unnamed enemy from the previous book was working for the nation of
Borduria. Following {{ the_authors }} focus on realism in this storyline, the
plot is resolved in dark and realistic manner compared to other Tintin
stories: Jorge is killed in a struggle with the reformed Wolff, who later
commits suicide by exiting  the airlock into space to give the rest of the
crew enough oxygen to make it back to Earth.

{{ tt16 }} and {{ this_book }} are a pinnacle of {{ this_series }} series,
showcasing {{ the_authors }} talent at both story-telling and drawing. I let
the kids pick the next book to read, and they agreed on {{ tt4 }}; expect that
review soon!
