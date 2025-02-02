---
layout: default
title: OMEMO Fingerprints
description: >
  Alex Gude's OMEMO fingerprints and QR codes for secure messaging.
sidebar_include: false
date: 2025-02-02
omemo_fingerprints:
  - device_name: "Linux Desktop"
    fingerprint: ""
    qr_code: "/files/omemo/linux-omemo-qr.png"
---

# {{ page.title }}

Below are my OMEMO fingerprints and their corresponding QR codes (where
available) for secure messaging as of <time datetime="{{ page.date |
date_to_xmlschema }}">{{ page.date | date: "%B %-d, %Y" }}</time>. These
fingerprints are used to verify the identity of my devices in end-to-end
encrypted communication.

This page serves as a record of my OMEMO fingerprints. Any future changes will
be noted here.

{% for device in page.omemo_fingerprints %}
## {{ device.device_name }}

**Fingerprint:** `{{ device.fingerprint }}`

  {% if device.qr_code %}
**QR Code:** ![{{ device.device_name }} OMEMO QR Code]({{ device.qr_code }})
  {% else %}
**QR Code:** *No QR code available for this device.*
  {% endif %}

{% endfor %}

