---
layout: default
title: Alex Gude's Linktree
description: >
  Important links for Alex Gude.
sidebar_include: false
---

<div class="linktree-container">

  {% comment %} Twitter {% endcomment %}
  {% capture twitter_url %}https://twitter.com/{{ site.author.twitter }}{% endcapture %}
  {% capture twitter_text %}@{{ site.author.twitter }}{% endcapture %}
  {% capture twitter_icon %}{% include icon-twitter.svg %}{% endcapture %}
  {% include linktree_item.html
    link=twitter_url
    text=twitter_text
    icon=twitter_icon
    button_class="twitter-button"
  %}

  {% comment %} Mastodon {% endcomment %}
  {% capture mastodon_url %}https://fediscience.org/@{{ site.author.mastodon }}{% endcapture %}
  {% capture mastodon_text %}@{{ site.author.mastodon }}{% endcapture %}
  {% capture mastodon_icon %}{% include icon-mastodon.svg %}{% endcapture %}
  {% include linktree_item.html
    link=mastodon_url
    text=mastodon_text
    icon=mastodon_icon
    button_class="mastodon-button"
  %}

  {% comment %} Github {% endcomment %}
  {% capture github_url %}https://github.com/{{ site.author.github }}{% endcapture %}
  {% capture github_text %}{{ site.author.github }}{% endcapture %}
  {% capture github_icon %}{% include icon-github.svg %}{% endcapture %}
  {% include linktree_item.html
    link=github_url
    text=github_text
    icon=github_icon
    button_class="github-button"
  %}

  {% comment %} LinkedIn {% endcomment %}
  {% capture linkedin_url %}https://www.linkedin.com/in/{{ site.author.linkedin }}{% endcapture %}
  {% capture linkedin_text %}{{ site.author.name }}{% endcapture %}
  {% capture linkedin_icon %}{% include icon-linkedin.svg %}{% endcapture %}
  {% include linktree_item.html
    link=linkedin_url
    text=linkedin_text
    icon=linkedin_icon
    button_class="linkedin-button"
  %}

  {% comment %} Website {% endcomment %}
  {% capture website_icon %}{% include icon-globe.svg %}{% endcapture %}
  {% include linktree_item.html
    link="/"
    text="alexgude.com"
    icon=website_icon
    button_class="website-button"
  %}

  {% comment %} RSS {% endcomment %}
  {% capture rss_icon %}{% include icon-rss.svg %}{% endcapture %}
  {% include linktree_item.html
    link="/feed.xml"
    text="alexgude.com/feed.xml"
    icon=rss_icon
    button_class="rss-button"
  %}

</div>
