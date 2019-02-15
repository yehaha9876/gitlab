# Working with the bundled Prometheus monitoring service

## Overview

As part of its High Availability stack, GitLab includes a bundled version of [Prometheus](https://prometheus.io) that can be managed through `/etc/gitlab/gitlab.rb`.

Prometheus can use [Consul](consul.md) to discover all of the various components in the HA cluster. **[PREMIUM ONLY]**

## Operations


### Enable Consul service discovery

Configure Prometheus to discover all of the exporters via Consul.

   ```
   prometheus['scrape_configs'] = [
     TODO
   ]
   ```
