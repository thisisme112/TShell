# Security Policy

TShell handles SSH credentials, private keys, terminal sessions, and SFTP file data. Please report security problems privately so maintainers have time to investigate and publish a fix before details are shared publicly.

## Supported Versions

Security fixes are currently provided for the latest commit on the default branch and the latest published release.

## Reporting a Vulnerability

Please email security reports to the project maintainers or use GitHub's private vulnerability reporting if it is enabled for this repository.

Include as much detail as possible:

- Affected TShell version or commit SHA.
- Operating system and architecture.
- Steps to reproduce the issue.
- Impact assessment and any known workarounds.
- Logs, screenshots, or proof-of-concept material when safe to share.

Do not include real production credentials, private keys, hostnames, or customer data in reports.

## Handling Expectations

- Maintainers will acknowledge actionable reports when they are received.
- Confirmed vulnerabilities will be prioritized according to impact and exploitability.
- Fixes may be released as patches, configuration guidance, or both.
- Public disclosure should wait until a fix or mitigation is available.

## Security Best Practices for Users

- Protect local devices that run TShell with disk encryption and strong account passwords.
- Use SSH keys with passphrases where possible.
- Rotate passwords or keys if you suspect local device compromise.
- Review remote commands and SFTP edits before applying changes to production systems.
