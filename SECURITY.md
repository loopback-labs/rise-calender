# Security

This document outlines security considerations and best practices for the Rise application.

## OAuth 2.0 Security

### Credential Management

- **Never commit OAuth credentials** to version control
- Store credentials in `rise/Config/OAuthConfig.plist` (already in .gitignore)
- Use the provided example file as a template
- Rotate credentials regularly

### OAuth Flow Security

- Uses PKCE (Proof Key for Code Exchange) for enhanced security
- Implements state parameter validation
- Uses secure token storage via macOS Keychain
- Implements automatic token refresh

## Data Storage Security

### Keychain Integration

- All OAuth tokens stored in macOS Keychain
- Uses app-specific service identifier
- Tokens are encrypted at rest
- Automatic cleanup on app uninstall

### Local Data

- Calendar data cached locally for performance
- No sensitive data sent to external servers
- User preferences stored in UserDefaults (non-sensitive)

## Network Security

### API Communication

- All API calls use HTTPS
- Bearer token authentication
- Proper error handling for authentication failures
- No sensitive data in URLs or headers

### Meeting URLs

- Meeting URLs extracted from calendar events
- No validation or modification of meeting URLs
- Users responsible for meeting URL security

## Privacy

### Data Collection

- No analytics or tracking
- No user data sent to external services
- All processing happens locally

### Permissions

- Calendar access only (read-only)
- Network access for API calls
- Keychain access for token storage

## Best Practices for Users

1. **Keep credentials secure**: Don't share your OAuth config file
2. **Regular updates**: Keep the app updated for security patches
3. **Monitor access**: Review Google account permissions regularly
4. **Secure meetings**: Be cautious with meeting URLs and access

## Reporting Security Issues

If you discover a security vulnerability, please:

1. **Do not** create a public issue
2. Email security details to piyush.bhutoria@gmail.com
3. Include detailed steps to reproduce
4. Allow time for investigation and fix

## Security Checklist for Contributors

- [ ] No hardcoded credentials in code
- [ ] All network calls use HTTPS
- [ ] Input validation implemented
- [ ] Error messages don't leak sensitive information
- [ ] Dependencies are up to date
- [ ] Security tests included
- [ ] Documentation updated for security changes
