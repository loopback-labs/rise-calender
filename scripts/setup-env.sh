#!/bin/bash

# Rise OAuth Environment Setup Script
# This script helps you set up environment variables for Google OAuth

echo "🚀 Rise OAuth Environment Setup"
echo "================================"
echo ""

# Check if environment variables are already set
if [ -n "$GOOGLE_CLIENT_ID" ] && [ -n "$GOOGLE_REDIRECT_SCHEME" ]; then
    echo "✅ Environment variables are already set:"
    echo "   GOOGLE_CLIENT_ID: $GOOGLE_CLIENT_ID"
    echo "   GOOGLE_REDIRECT_SCHEME: $GOOGLE_REDIRECT_SCHEME"
    echo ""
    echo "You can now run the app!"
    exit 0
fi

echo "Please enter your Google OAuth credentials:"
echo ""

# Get Client ID
read -p "Enter your Google Client ID: " client_id

if [ -z "$client_id" ]; then
    echo "❌ Client ID is required"
    exit 1
fi

# Generate redirect scheme from client ID
redirect_scheme="com.googleusercontent.apps.${client_id}"

echo ""
echo "Generated redirect scheme: $redirect_scheme"
echo ""

# Export environment variables
export GOOGLE_CLIENT_ID="$client_id"
export GOOGLE_REDIRECT_SCHEME="$redirect_scheme"

echo "✅ Environment variables set:"
echo "   GOOGLE_CLIENT_ID: $GOOGLE_CLIENT_ID"
echo "   GOOGLE_REDIRECT_SCHEME: $GOOGLE_REDIRECT_SCHEME"
echo ""

# Add to shell profile if requested
read -p "Add to your shell profile for persistence? (y/n): " add_to_profile

if [[ $add_to_profile =~ ^[Yy]$ ]]; then
    profile_file=""
    if [[ "$SHELL" == *"zsh"* ]]; then
        profile_file="$HOME/.zshrc"
    elif [[ "$SHELL" == *"bash"* ]]; then
        profile_file="$HOME/.bashrc"
    fi
    
    if [ -n "$profile_file" ]; then
        echo "" >> "$profile_file"
        echo "# Rise OAuth Configuration" >> "$profile_file"
        echo "export GOOGLE_CLIENT_ID=\"$client_id\"" >> "$profile_file"
        echo "export GOOGLE_REDIRECT_SCHEME=\"$redirect_scheme\"" >> "$profile_file"
        echo "✅ Added to $profile_file"
        echo "   Restart your terminal or run 'source $profile_file' to apply"
    else
        echo "⚠️  Could not determine shell profile file"
    fi
fi

echo ""
echo "🎉 Setup complete! You can now run the Rise app."
echo "   The environment variables will be available in this terminal session."
