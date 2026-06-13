---
layout: resume
sidebar_include: true
title: "Resume"
seo_title: "Alexander Gude - Resume"
description: >
  Alexander Gude's Resume. Alex is a machine learning engineer.
job_title: "Senior Staff Machine Learning Engineer"
career_start_year: 2015

statement: >
  Machine learning engineer with YEARS_PLACEHOLDER years of experience in
  fraud detection and financial risk at Cash App and Intuit. Built the ACH
  fraud program that reduced fraud volumes by over 200x and the transaction
  categorization system that drives loan sizing, deposit eligibility, and
  compliance for millions of customers.

experience:
  - company: "Cash App"
    location: "Remote"
    positions:
      - title: "Senior Staff (L7) Machine Learning Engineer, Modeler"
        dates: "2023--Present"
      - title: "Staff (L6) Machine Learning Engineer, Modeler"
        dates: "2020--2023"
    bullets:
      - >
        Sized the opportunity and built the anti-fraud controls for instant
        bank account opening, the primary launch blocker. Worked with
        compliance and external banking partners to get the program green-lit.
        Instant bank accounts delivered a 90% increase in paycheck deposits
        and a 55% increase in revenue from paycheck deposits.
      - >
        Built the ACH fraud detection program from the ground up: developed
        high-recall monitoring metrics, scaled a human review pipeline to
        thousands of reviews per week, and deployed targeted rules and machine
        learning models. Reduced fraud volumes by 12x in the first 18 months,
        and with continual improvements over 200x across five years.
      - >
        Briefed the IRS, state tax administrators, and banking partners on the
        anti-fraud program, securing continued confidence in Cash App's
        deposit controls, without which tax refund deposits, 18% of all
        inflows, could have been redirected away from Cash App accounts.
      - >
        Built and own the ACH transaction categorization system for Cash App
        Banking. Deployed the first ML model, then integrated generative AI,
        the first GenAI deployment at Cash App, reducing uncategorized
        transactions by an additional 3x. The system drives lending decisions,
        deposit eligibility, fraud risk scoring, and compliance workflows for
        millions of customers. Work submitted as a patent.
      - >
        Analyzed deposit limit policies and demonstrated that per-transaction
        caps were blocking legitimate customers at a rate exceeding 97%,
        driving a cross-functional initiative to restructure limits that
        unblocked over $100M in annual deposit volume.
      - >
        Built an LLM-powered fraud investigation tool that exceeded human
        reviewer precision. Automated compliance document generation from
        code and metrics. Championed AI adoption across the risk
        organization, presenting at Block's inaugural AI Summit, building
        over 20 agent skills for daily fraud analysis, and coaching
        engineers across multiple teams on integrating LLMs.

  - company: "Intuit"
    location: "Mountain View, CA"
    positions:
      - title: "Staff Data Scientist"
        dates: "2017--2020"
      - title: "Senior Data Science Manager"
        dates: "2018--2019"
    bullets:
      - >
        Led 8 data scientists in building machine learning models to detect
        and stop fraud.
      - >
        Drove adoption of engineering best practices by the team, including
        peer review, automated correctness checking, CI/CD pipelines for
        code and model deployment, and test coverage metrics, reducing P0
        production bugs from 2 in the first year to 0.
      - >
        Deployed the first in-product, real-time account takeover prevention
        model at Intuit---launched in production in TurboTax and alerted
        security to a possible breach within the first week of running.
        Back-testing showed it would have detected 95% of last year's stolen
        tax return downloads.
      - >
        Drove migration of machine learning models from Intuit's on-prem data
        center to AWS platform without interruption of services, saving $1.5M
        per year in operation costs.
      - >
        Improved the legacy TurboTax Online account takeover model, leading to
        a 90% reduction in wrongly challenged users, stopping 10X as many
        fraudsters, and shortening feature processing time from 2 hours to
        under a second.

  - company: "Lab41, an In-Q-Tel Lab"
    location: "Menlo Park, CA"
    positions:
      - title: "Data Scientist"
        dates: "2015--2017"
    bullets:
      - >
        Led a team of 3 engineers to build a vehicle re-identification system
        using deep learning within 6 months, enabling clients to
        automatically detect the same vehicle across multiple security
        camera feeds. Handed over the system to the customer's internal
        development team and provided training.
      - >
        Built a system using TensorFlow that embedded images and text into a
        joint vector space, trained on unlabeled open-source image data.
        Enabled customers to perform content-based image retrieval on a
        corpus of 100M untagged images. Published at BMVC 2017.
      - >
        Designed and implemented a recommender system evaluation framework in
        Python and Spark and leveraged it to develop a Python-snippet
        recommender using word embeddings.

skills:
  languages: 'Python, SQL, Scala, shell script, C++, <span class="latex">L<sup>a</sup>T<sub>e</sub>X</span>'
  tools: "PyTorch, scikit-learn, XGBoost, Snowflake, dbt, NumPy, Pandas, Matplotlib, git, Linux, vim"

education:
  - company: "University of Minnesota"
    location: "Minneapolis, MN"
    positions:
      - title: "PhD, High Energy Particle Physics"
        dates: "2009--2015"

  - company: "University of California, Berkeley"
    location: "Berkeley, CA"
    positions:
      - title: "BA, Physics (Honors), College of Letters and Sciences"
        dates: "2004--2008"
---

# Alexander Gude

{% subtitle page.job_title %}

## Statement

{% assign years_experience = "now" | date: "%Y" | minus: page.career_start_year %}
{{ page.statement | replace: "YEARS_PLACEHOLDER", years_experience }}

## Experience

{% for job in page.experience %}
{% assign pos = job.positions %}
{% if pos.size == 2 %}
{% resume_experience
  company=job.company
  location=job.location
  position=pos[0].title
  dates=pos[0].dates
  position_2=pos[1].title
  dates_2=pos[1].dates
%}
{% else %}
{% resume_experience
  company=job.company
  location=job.location
  position=pos[0].title
  dates=pos[0].dates
%}
{% endif %}

{% for bullet in job.bullets %}

- {{ bullet }}
  {% endfor %}
  {% endfor %}

## Skills

{% resume_skills
  languages=page.skills.languages
  tools=page.skills.tools
%}

## Education

{% for school in page.education %}
{% assign pos = school.positions %}
{% resume_experience
  company=school.company
  location=school.location
  position=pos[0].title
  dates=pos[0].dates
%}
{% endfor %}
