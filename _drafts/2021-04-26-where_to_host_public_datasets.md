---
layout: post
title: "Where to Host Public Datasets?"
description: >
  When I released the SWITRS dataset, I had to find a place to host a 5 Gig
  dataset. Here is what I learned.
image: /files/switrs-dataset/tram_auto_crash_in_1957_frederiksplein_amsterdam.jpg
image_alt: >
categories: 
  - california-traffic-data 
  - data-science
---

{% capture file_dir %}/files/switrs-dataset{% endcapture %}

I spent a lot of time cleaning up the [California Statewide Integrated Traffic
Records System (SWITRS)][switrs] dataset for use in my own projects. I even
wrote a [helpful script][s2s] to do so automatically. I thought that would
make it easy for others to use the data, but no. They still had to request the
data, download it, and then run the scripts. Worse, some of the old data was
no longer available.

[switrs]: http://iswitrs.chp.ca.gov/Reports/jsp/userLogin.jsp
[s2s]: {% post_url 2016-11-01-switrs_to_sqlite %}
[sqlite]: https://en.wikipedia.org/wiki/SQLite

I decided to [create a clean dataset and host it][hosted_dataset_post] so that
people could start using it immediately. Unfortunately, the data was pretty
large, so finding a site to host it was not easy. In the end I choose two
places: [**Kaggle**][db_link] and [**Zenodo**][zen_link]. In this post I'll
share the lessons I learned, the benefits of each site, and why I think using
both is the right thing to do.

[hosted_dataset_post]: {% post_url 2020-11-24-switrs_sqlite_hosted_dataset %}
[db_link]: https://www.kaggle.com/alexgude/california-traffic-collision-data-from-switrs
[zen_link]: https://zenodo.org/record/4284843

## Kaggle

Kaggle is a great place to host a dataset. It allows users to download the
file _or_ work with the data directly in Kaggle's hosted notebooks. The author
can even set up a [demo notebook][demo_nb] to demonstrate how to work with the
data. Kaggle will even help you set up a [DOI][doi] for your data. Mine is:
[10.34740/kaggle/dsv/1671261][my_doi]

[demo_nb]: https://www.kaggle.com/alexgude/starter-california-traffic-collisions-from-switrs
[doi]: https://en.wikipedia.org/wiki/Digital_object_identifier
[my_doi]: https://www.doi.org/10.34740/kaggle/dsv/1671261

Kaggle supports really deep data documentation. You can write an introduction
for each table and each column. Additionally, Kaggle will automatically
generate histograms of each column and some summary statistics.

Kaggle is more than just hosting; it is a community. Other people can
share their work, set up challenges using the data, and ask questions in the forum, and

Kaggle does have some significant downsides though. First, users must create
an account to download the data. Second, Kaggle is a for-profit company that
is famous for dropping support for their products. I don't trust them to host
the data long term.

### Pros

- Free for you and me
- Community
  - Forums
  - Challenges
- Great docs
- Built in compute
  - Demo notebook
- DOI
- Versioning
- Activity feed

### Cons

- Google is infamous for [shutting stuff down][killedbygoogle]
- Account required

[killedbygoogle]: https://killedbygoogle.com/

## Zenodo

### Pros

- Hosted by CERN, which [knows a little something about keeping websites
up][first_site]
- Lets you point DOI elsewhere
- DOI
- Tracks citations
- MD5
- Activity feed

[first_site]: http://info.cern.ch/

### Cons

- No one uses it
- Upload finicky
