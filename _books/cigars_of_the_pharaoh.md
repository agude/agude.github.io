---
date: 2025-07-27
title: Cigars of the Pharaoh
book_authors: Hergé
series: The Adventures of Tintin
book_number: 4
rating: 3
image: /books/covers/cigars_of_the_pharaoh.jpg
---

<cite class="book-title">{{ page.title }}</cite>, by <span
class="author-name">{{ page.book_authors }}</span>, is the forth book in the
<span class="book-series">{{ page.series }}</span>. It follows Tintin as he
explores Egypt and Indian and uncovers an opium smuggling ring.

{% capture this_book %}<cite class="book-title">{{ page.title }}</cite>{% endcapture %}
{% capture the_author %}<span class="author-name">{{ page.book_authors }}</span>{% endcapture %}
{% capture the_authors %}<span class="author-name">{{ page.book_authors }}</span>'s{% endcapture %}
{% capture author_last_name_text %}{{ page.book_authors | split: " " | last }}{% endcapture %}
{% capture the_authors_lastname %}<span class="author-name">{{ page.book_authors | split: " " | last }}</span>{% endcapture %}
{% capture the_authors_lastname_possessive %}<span class="author-name">{{ page.book_authors | split: " " | last }}</span>'s{% endcapture %}
{% capture the_author_link %}{% author_link page.book_authors %}{% endcapture %}
{% capture the_authors_link %}{% author_link page.book_authors possessive %}{% endcapture %}
{% capture the_authors_lastname_link %}{% author_link page.book_authors link_text=author_last_name_text %}{% endcapture %}
{% capture the_authors_lastname_possessive_link %}{% author_link page.book_authors link_text=author_last_name_text possessive %}{% endcapture %}
{% capture this_series %}{% series_text page.series %}{% endcapture %}

{% capture tt1 %}{% book_link "Tintin in the Land of the Soviets" %}{% endcapture %}
{% capture tt2 %}{% book_link "Tintin in the Congo" %}{% endcapture %}
{% capture tt3 %}{% book_link "Tintin in America" %}{% endcapture %}
{% capture tt5 %}{% book_link "The Blue Lotus" %}{% endcapture %}
{% capture tt6 %}{% book_link "The Broken Ear" %}{% endcapture %}
{% capture tt11 %}{% book_link "The Secret of the Unicorn" %}{% endcapture %}
{% capture tt12 %}{% book_link "Red Rackham's Treasure" %}{% endcapture %}
{% capture tt16 %}{% book_link "Destination Moon" %}{% endcapture %}
{% capture tt17 %}{% book_link "Explorers on the Moon" %}{% endcapture %}

{% capture doyles %}{% author_link "Arthur Conan Doyle" possessive %}{% endcapture %} 
{% capture final_problem %}{% book_link "The Final Problem" %}{% endcapture %} 

{{ this_book }} is a transitional work in {{ this_series }} in many ways. Like
early works---{{ tt1 }}, {{ tt2 }}, and even {{ tt3 }}---this book is
essentially a travel comic. Tintin travels to a new country and finds himself
mixed up in some adventure. An like the early works, Tintin still operates
under the laws of cartoons, but it's toned down. He doesn't knock out a
buffalo with a rubber tree slingshot like in {{ tt2 }}, but he does jump a 15
foot wall by bouncing on a fat mans stomach and talk to elephants with a
trumpet.

In other ways, {{ this_book }} is closer to more modern works in the series:
it has a plot---the opium smuggling ring---the extends through the whole book
and even into {{ tt5 }}, making it the first two-part story like {{ tt11 }}
and {{ tt12 }}, or {{ tt16 }} and {{ tt17 }}.

The story meanders from adventure to adventure, and the dialogue is
uninspired. The Thomson and Thompson don't have a big enough party, and the
lack of Captain Haddock means Tintin has no one to play off of. The art is
still great though, and with far more variety of setting than {{ tt2 }}. There
are some beautiful panels, especially the half page one showing Tintin as he
escapes the middle-eastern city pursued by the army. The mountain car chase at
the end reminds me of both the mountains {{ the_author }} drew in {{ tt16 }},
and also {{ doyles }} {{ final_problem }} as the villain plunges to his
apparent death.

A book mostly interesting as a hint at what the series would become. On to {{
tt5 }} next.
