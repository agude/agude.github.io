---
layout: default
title: Twitter Disavow
description: >
  Alex Gude deleted @alex_gude on Twitter (and his three bots) on 2024-11-10.
sidebar_include: false
main_twitter_handle: alex_gude
twitter_bot_handles:
  - RaspberryPion
  - RaspberryKaon
  - RaspberryRho
---

# {{ page.title }}

I have deleted my Twitter account, `@{{ page.main_twitter_handle }}`, on <time
datetime="2024-11-10T00:48:30+00:00">November 10<sup>th</sup>, 2024</time>.

I also deleted my bot accounts:

{%- for handle in page.twitter_bot_handles -%}
    {%- if forloop.last and forloop.length > 1 %}
        and
    {% endif -%}
    `@{{ handle }}`
    {%- if forloop.last == false -%}, {% endif -%}
{%- endfor -%}.

This page serves as a record to clarify that any future usage of these handles
is not associated with me.
