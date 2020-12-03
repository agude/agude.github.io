---
layout: post
title: "Interview Practice: Data Manipulation"
description: >
image: /files/switrs-dataset/tram_auto_crash_in_1957_frederiksplein_amsterdam.jpg
image_alt: >
categories: career_advice interview_prep
---

{% capture file_dir %}/files/switrs-dataset{% endcapture %}

{% include lead_image.html %}

I often get asked by newly-minted PhDs trying to get their first job:

> How can I prepare for data interviews? Do you have any examples of datasets
> to practice with that you can share?

I never had a good answer. I would tell them a lot about how interviews went,
but I never had something I could share that they could work with and practice
on.

But as of today, that's changing. In this post I put together a series of
practice questions like the kind you might see (or be expected to come up
with) in a hands-on data interview using the [curated and hosted
dataset of California Traffic accidents][switrs_dataset]. The dataset is
avaliable for download from both [Kaggle][kaggle] and [Zenodo][zenodo], and I
even have an [example notebook][example_notebook] for how to work with the
data entirely online within Kaggle.

[switrs_dataset]: {% post_url 2020-11-24-switrs_sqlite_hosted_dataset %}
[kaggle]: https://www.kaggle.com/alexgude/california-traffic-collision-data-from-switrs
[zenodo]: https://zenodo.org/record/4284843
[example_notebook]: https://www.kaggle.com/alexgude/starter-california-traffic-collisions-from-switrs

## Interview Format

## Questions

### How many collisions between two vehicles were there in 2017?

```sql
SELECT COUNT(1) AS collision_count
FROM collisions
WHERE collision_year = 2017
```

### How many solo motorcycle accidents are there per year?

```sql
SELECT collision_year, count(1) AS collision_count
FROM collisions
WHERE motorcycle_collision = Ture
  AND party_count = 1
GROUP BY collision_year
ORDER BY collision_year
```

### What percent of collisions involve males aged 16-25?

```sql
SELECT COUNT(DISTINCT case_id) 
FROM collisions AS c
LEFT JOIN parties AS p
ON c.case_id = p.case_id
WHERE p.sex = 'male'
AND p.age >= 16
AND p.age <= 25
```

### What make and model of car has the most collisions on weekdays? Weekends?
