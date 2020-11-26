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
