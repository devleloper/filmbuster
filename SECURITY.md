# Security policy

## Supported versions

Filmbuster is maintained by one person. Security fixes go into `main` and
into the latest release only.

| Version | Supported |
| --- | --- |
| Latest release (1.0.x) | Yes |
| `main` | Yes |
| Older releases | No: update to the latest release |

## Reporting a vulnerability

Please report vulnerabilities privately through GitHub:

1. Open the repository's **Security** tab.
2. Choose **Report a vulnerability**
   (<https://github.com/devleloper/filmbuster/security/advisories/new>).
3. Describe the issue, the affected version or commit, the platform, and the
   steps to reproduce it.

Do not open a public issue, pull request or discussion for a vulnerability,
and do not include real tokens, keys or personal data in the report.

Reports are handled on a best-effort basis. You can expect an acknowledgement,
a decision on whether the report is accepted, and a fix or mitigation in a new
release for accepted reports. You will be credited in the advisory unless you
ask not to be.

## Scope

In scope: the code in this repository and the builds made from it.

Out of scope:

- Third-party services the app talks to (TMDB, the hosts of the open movies,
  a backend you run yourself). Report those to their owners.
- Values passed with `--dart-define`. They are compiled into the app and are
  readable by anyone who has the build, by design; never put secrets there.
