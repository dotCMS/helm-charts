# Contributing to DotCMS Helm Charts

Thank you for your interest in contributing to the DotCMS Helm Charts repository! This document provides guidelines and instructions for contributing.

GitHub pull requests are the preferred method to contribute code to dotCMS Helm Charts. Before any pull requests can be accepted, an automated tool will ask you to agree to the dotCMS Contributor's Agreement.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Development Setup](#development-setup)
- [Making Changes](#making-changes)
- [Testing](#testing)
- [Pull Request Process](#pull-request-process)
- [Chart Guidelines](#chart-guidelines)
- [Documentation](#documentation)
- [Getting Help](#getting-help)

## Prerequisites

Before you begin, ensure you have the following tools installed:

- Docker Desktop with Kubernetes enabled
- kubectl
- Helm (v3.x)
- mkcert (for local development)

For detailed installation instructions, refer to the [Local Development Setup](./charts/dotcms/README.md) guide.

## Development Setup

1. Fork the repository and clone your fork:
   ```bash
   git clone git@github.com:YOUR_USERNAME/helm-charts.git
   cd helm-charts
   ```

2. Add the upstream repository as a remote:
   ```bash
   git remote add upstream git@github.com:dotCMS/helm-charts.git
   ```

3. Create a new branch for your changes:
   ```bash
   git checkout -b feature/your-feature-name
   ```

## Making Changes

1. Follow the Helm chart best practices when making changes.
2. Update documentation as needed.
3. Update the chart version according to semantic versioning:
   - Bug fixes and minor changes: patch version (1.0.x)
   - New features (backward compatible): minor version (1.x.0)
   - Breaking changes: major version (x.0.0)

## Testing

Before submitting a pull request, ensure your changes pass all tests:

1. Lint your changes:
   ```bash
   helm lint charts/*
   ```

2. Run chart-testing:
   ```bash
   ct lint --config ct.yaml
   ```

3. Test the chart installation locally:
   ```bash
   helm install test-release ./charts/dotcms --namespace dotcms-dev --create-namespace
   ```

## Pull Request Process

1. Update the README.md and relevant documentation with details of changes.
2. Ensure all tests pass and the chart version is updated appropriately.
3. Submit a pull request to the `main` branch.
4. The PR must receive approval from at least one maintainer.
5. Once approved, a maintainer will merge your changes.
6. Sign the automated [dotCMS Contributor's Agreement](https://gist.github.com/wezell/85ef45298c48494b90d92755b583acb3) if prompted.

## Chart Guidelines

When contributing to the charts:

1. Follow the existing chart structure and naming conventions.
2. Use the provided helper templates in `_helpers.tpl` when applicable.
3. Include appropriate NOTES.txt with usage instructions.
4. Document all values in values.yaml with clear descriptions.
5. Ensure charts are as configurable as possible while maintaining secure defaults.

## Documentation

- Update the chart's README.md with any new features or changes.
- Document all new values in values.yaml with clear descriptions.
- Include examples for complex configurations.
- Update the NOTES.txt if the deployment process changes.

## Security

- Never commit sensitive information (keys, passwords, certificates).
- Use Kubernetes Secrets for sensitive data.
- Follow security best practices for container images and Kubernetes resources.
- Report security vulnerabilities to the maintainers privately.

## Getting Help

If you need help with your contribution, you can:

| Source          | Location                                                              |
| --------------- | --------------------------------------------------------------------- |
| Documentation   | [Documentation](https://www.dotcms.com/docs/latest/table-of-contents) |
| Forums/Listserv | [via Google Groups](https://groups.google.com/forum/#!forum/dotCMS)   |
| Twitter         | @dotCMS                                                               |
| Main Site       | [dotCMS.com](https://www.dotcms.com/)                                 |

Additionally:
1. Check existing issues and documentation
2. Create a new issue for questions or problems
3. Reach out to the maintainers

## Code of Conduct

Please note that this project is released with a [Code of Conduct](./CODE_OF_CONDUCT.md). By participating in this project, you agree to abide by its terms.

## License

By contributing to this repository, you agree that your contributions will be licensed under the same license as the project (see [LICENSE](./LICENSE) file).