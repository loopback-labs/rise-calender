# OAuth Configuration

This directory contains configuration files for Google OAuth authentication.

## Configuration Methods

### Method 1: Environment Variables (Recommended)

Set these environment variables before running the app:

```bash
export GOOGLE_CLIENT_ID="your-client-id.apps.googleusercontent.com"
export GOOGLE_REDIRECT_SCHEME="com.googleusercontent.apps.your-client-id"
```

**Priority**: Environment variables are checked first and take precedence over the plist file.

### Method 2: Configuration File (Fallback)

1. Copy `OAuthConfig.example.plist` to `OAuthConfig.plist`
2. Replace the placeholder values with your actual Google OAuth credentials

**Note**: This method is only used if environment variables are not set.

## Getting Google OAuth Credentials

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select an existing one
3. Enable the Google Calendar API
4. Go to "Credentials" → "Create Credentials" → "OAuth 2.0 Client IDs"
5. Choose "macOS" as the application type
6. Set your bundle identifier (e.g., `com.yourdomain.rise`)
7. Copy the Client ID

## Environment Variable Setup

### For Xcode Development

1. In Xcode, go to Product → Scheme → Edit Scheme
2. Select "Run" on the left
3. Go to "Arguments" tab
4. Under "Environment Variables", add:
   - `GOOGLE_CLIENT_ID` = your client ID
   - `GOOGLE_REDIRECT_SCHEME` = your redirect scheme

### For Terminal/Command Line

```bash
# Set environment variables
export GOOGLE_CLIENT_ID="your-client-id.apps.googleusercontent.com"
export GOOGLE_REDIRECT_SCHEME="com.googleusercontent.apps.your-client-id"

# Run the app
open rise.xcodeproj
```

### For CI/CD

Add these as secrets in your CI/CD environment:

```yaml
# Example for GitHub Actions
env:
  GOOGLE_CLIENT_ID: ${{ secrets.GOOGLE_CLIENT_ID }}
  GOOGLE_REDIRECT_SCHEME: ${{ secrets.GOOGLE_REDIRECT_SCHEME }}
```

## Security Notes

- Never commit actual credentials to version control
- Use environment variables for production deployments
- Rotate credentials regularly
- The `OAuthConfig.plist` file is already in `.gitignore`
