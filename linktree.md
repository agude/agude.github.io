---
layout: default
title: Alex Gude's Linktree
description: >
  Important links for Alex Gude.
sidebar_include: false
---

<div class="linktree-container">

  <!-- Twitter -->
  {% capture twitter_url %}https://twitter.com/{{ site.author.twitter }}{% endcapture %}
  {% capture twitter_text %}@{{ site.author.twitter }}{% endcapture %}
  {% capture twitter_icon %}{% include icon-twitter.svg %}{% endcapture %}
  {% include linktree_item.html
    link=twitter_url
    text=twitter_text
    icon=twitter_icon
    button_class="twitter-button"
  %}

  <!-- Mastodon -->
  {% capture mastodon_url %}https://fediscience.org/@{{ site.author.mastodon }}{% endcapture %}
  {% capture mastodon_text %}@{{ site.author.mastodon }}@fediscience.org{% endcapture %}
  {% capture mastodon_icon %}{% include icon-mastodon.svg %}{% endcapture %}
  {% include linktree_item.html
    link=mastodon_url
    text=mastodon_text
    icon=mastodon_icon
    button_class="mastodon-button"
  %}

  <!-- LinkedIn -->
  {% capture linkedin_url %}https://www.linkedin.com/in/{{ site.author.linkedin }}{% endcapture %}
  {% capture linkedin_text %}{{ site.author.name }}{% endcapture %}
  {% capture linkedin_icon %}{% include icon-linkedin.svg %}{% endcapture %}
  {% include linktree_item.html
    link=linkedin_url
    text=linkedin_text
    icon=linkedin_icon
    button_class="linkedin-button"
  %}

  <!-- Website -->
  {% capture website_icon %}{% include icon-globe.svg %}{% endcapture %}
  {% include linktree_item.html
    link="/"
    text="alexgude.com"
    icon=website_icon
    button_class="website-button"
  %}

  <!-- RSS -->
  {% capture rss_icon %}{% include icon-rss.svg %}{% endcapture %}
  {% include linktree_item.html
    link="/feed.xml"
    text="alexgude.com/feed.xml"
    icon=rss_icon
    button_class="rss-button"
  %}

</div>
