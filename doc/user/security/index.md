# GitLab Secure **[ULTIMATE]**

Check your application for security vulnerabilities that may lead to unauthorized access,
data leaks, and denial of services.

## Overview

GitLab can perform static and dynamic tests on the
code of your application, looking for known flaws and report them in the merge request
so you can fix them before merging. Security teams can use dashboards to get a
high-level view on projects and groups, and start remediation processes when needed.

The following documentation relates to the DevOps **Secure** stage:

| Security report                                        | Description                                                            |
|:-------------------------------------------------------|:-----------------------------------------------------------------------|
| [Container Scanning](container_scanning.md)            | Use Clair to scan docker images for known vulnerabilities.             |
| [Dependency Scanning](dependency_scanning.md)          | Analyze your dependencies for known vulnerabilities.                   |
| [Dynamic Application Security Testing (DAST)](dast.md) | Analyze running web applications for known vulnerabilities.            |
| [License Management](license_management.md)            | Search your project's dependencies for their licenses.                 |
| [Security Dashboard](security_dashboard.md)            | View vulnerabilities in all the projects in a group and its subgroups. |
| [Static Application Security Testing (SAST)](sast.md)  | Analyze source code for known vulnerabilities.                         |

## Interacting with security reports **[ULTIMATE]**

> Introduced in [GitLab Ultimate][products] 10.8.

CAUTION: **Warning:**
This feature is currently [Alpha](https://about.gitlab.com/handbook/product/#alpha-beta-ga) and while you can start using it, it may receive important changes in the future.

Each security vulnerability in the report is actionable. Clicking on an entry,
a detailed information will pop up with two different possible options:

- **Dismiss vulnerability** - Dismissing a vulnerability will place a
  <s>strikethrough</s> styling on it.
- **Create issue** - The new issue will have the title and description
  pre-populated with the information of the vulnerability report.

![Interacting with security reports](img/interactive_reports.png)

You can also revert your dismissal or see the linked issue after the action has
been taken.

