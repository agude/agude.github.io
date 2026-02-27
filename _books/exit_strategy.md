---
date: 2025-05-23 15:04:25 -0700
title: Exit Strategy
book_authors: Martha Wells
series: The Murderbot Diaries
book_number: 4
rating: 5
image: /books/covers/exit_strategy.jpg
wikidata_qid: Q63177967
isbn: 978-1-250-19185-4
date_published: 2018-10-02
same_as_urls:
  - "https://www.wikidata.org/wiki/Q63177967"
  - "https://openlibrary.org/works/OL19763338W"
  - "https://www.isfdb.org/cgi-bin/title.cgi?2421678"
  - "https://www.librarything.com/work/20558348"
---

{% book_link page.title %}, by {% author_link page.book_authors link=false %},
is the fourth book in {% series_text page.series link=false %}. It wraps up
the GrayCris storyline as Murderbot returns to save its friends.

{% capture this_book %}{% book_link page.title %}{% endcapture %}
{% capture author_last_name_text %}{{ page.book_authors | split: " " | last }}{% endcapture %}
{% capture the_authors_lastname %}{% author_link page.book_authors link=false link_text=author_last_name_text %}{% endcapture %}
{% capture this_series %}{% series_text page.series %}{% endcapture %}

{% capture mb1 %}{% book_link "All Systems Red" %}{% endcapture %}
{% capture mb3 %}{% book_link "Rogue Protocol" %}{% endcapture %}
{% capture mb4_5 %}{% book_link "Home: Habitat, Range, Niche, Territory" %}{% endcapture %}

{% capture smiths %}{% author_link "L. Neil Smith" possessive %}{% endcapture %}
{% capture probability_broach %}{% book_link "The Probability Broach" %}{% endcapture %}

{% capture surface %}{% book_link "Surface Detail" %}{% endcapture %}
{% capture fall %}{% book_link "The Fall of Hyperion" %}{% endcapture %}

{% capture tchaikovskys %}{% author_link "Adrian Tchaikovsky" possessive %}{% endcapture %}
{% capture shards %}{% book_link "Shards of Earth" %}{% endcapture %}
{% capture architecture %}{% series_text "The Final Architecture" %}{% endcapture %}

{{ this_book }} is the climax of the first four books in {{ this_series }}. It
concludes the GrayCris storyline that began in {{ mb1 }}, when Murderbot saved
Dr. Ayda Mensah and her team and was set free.

Murderbot learns that Mensah has been kidnapped and imprisoned by GrayCris at
their corporate headquarters. It quickly realizes that its exploration of the
alien-artifact mining station spooked the company and forced them to take
desperate action. Murderbot returns to the Corporation Rim, determined to save
its humans. Along the way, it reunites with and rescues its old team,
confronts a combat SecUnit, and grapples with its own death wish---learning that
sometimes survival means running. There's a lot of satisfying action as
Murderbot saves its friends again and again.

The theme of Murderbot's relationship with humans and humanity continues from
{{ mb3 }}. It has conflicted emotions after learning that SecUnits used to be
more human and had closer relationships with their clients. It once again
starts to run away, but at the last minute decides to stay. And it's finally
starting to accept that its need to protect people is a core part of who it
is---not just leftover programming.

The detailed view of the "libertarian paradise" that is the Corporation Rim
reminded me of {{ smiths }} (horrible) {{ probability_broach }}, which paints
an idealized version of what a libertarian world would look like---so extreme it
almost reads as satire. {{ the_authors_lastname }}'s version feels closer to
reality. The hacking-as-combat parts, where code has a "physical" presence in
the world, reminded me of similar scenes in {{ surface }} and {{ fall }}.

Next up is the short story {{ mb4_5 }}, then I'm starting {{ tchaikovskys }}
{{ architecture }} with {{ shards }}.
