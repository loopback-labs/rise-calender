# Contributing to Rise

Thank you for your interest in contributing to Rise! This document provides guidelines and information for contributors.

## Code of Conduct

This project and everyone participating in it is governed by our Code of Conduct. By participating, you are expected to uphold this code.

## How Can I Contribute?

### Reporting Bugs

- Use the GitHub issue tracker
- Include detailed steps to reproduce the bug
- Provide system information (macOS version, Xcode version)
- Include any error messages or logs

### Suggesting Enhancements

- Use the GitHub issue tracker
- Clearly describe the feature request
- Explain why this feature would be useful
- Consider implementation complexity

### Pull Requests

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes
4. Add tests if applicable
5. Commit your changes (`git commit -m 'Add amazing feature'`)
6. Push to the branch (`git push origin feature/amazing-feature`)
7. Open a Pull Request

## Development Setup

### Prerequisites

- macOS 14.0 or later
- Xcode 15.0 or later
- Google Cloud Console access (for OAuth setup)

### Setting Up OAuth

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select existing one
3. Enable Google Calendar API
4. Create OAuth 2.0 credentials

**Choose one of these methods:**

#### Environment Variables (Recommended)

```bash
export GOOGLE_CLIENT_ID="your-client-id.apps.googleusercontent.com"
export GOOGLE_REDIRECT_SCHEME="com.googleusercontent.apps.your-client-id"
```

#### Configuration File

1. Copy `rise/Config/OAuthConfig.example.plist` to `rise/Config/OAuthConfig.plist`
2. Replace placeholder values with your credentials

See [rise/Config/README.md](rise/Config/README.md) for detailed instructions.

### Building the Project

1. Clone the repository
2. Open `rise.xcodeproj` in Xcode
3. Configure OAuth credentials (see above)
4. Build and run

## Code Style

- Follow Swift style guidelines
- Use meaningful variable and function names
- Add comments for complex logic
- Keep functions focused and small
- Use SwiftUI best practices

## Testing

- Add unit tests for new functionality
- Test on different macOS versions if possible
- Ensure UI works in both light and dark modes
- Test with multiple Google accounts

## Security

- Never commit OAuth credentials
- Use Keychain for sensitive data storage
- Follow Apple's security guidelines
- Validate all user inputs

## Questions?

Feel free to open an issue for any questions about contributing!
