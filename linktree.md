---
layout: default
title: Alex Gude's Linktree
description: >
  Important links for Alex Gude.
sidebar_include: true
---
<div class="linktree-links-grid">

  <!-- Twitter -->
  <div class="linktree-element">
  <a rel="me" class="social-button twitter-button" href="https://twitter.com/{{ site.author.twitter }}">
  {% include icon-twitter.svg %}
  <br>
  @alex_gude@twitter.com
  </a>
  </div>

  <div class="linktree-element">
  <!-- Mastodon -->
  <a rel="me" class="social-button mastodon-button" href="https://fediscience.org/@{{ site.author.mastodon }}">
    {% include icon-mastodon.svg %}
  </a>
  </div>

  <div class="linktree-element">
  <!-- LinkedIn -->
  <a rel="me" class="social-button linkedin-button" href="https://www.linkedin.com/in/{{ site.author.linkedin}}/">
    {% include icon-linkedin.svg %}
  </a>
  </div>

  <div class="linktree-element">
  <!-- RSS -->
  <a class="social-button rss-button" href="/feed.xml">
    {% include icon-rss.svg %}
  </a>
  </div>

</div>
