# Rise - Multi-Calendar Management App

A native macOS application for managing multiple Google Calendar accounts with intelligent meeting auto-join capabilities.

## 🚀 Features

### 📅 Multi-Calendar Support

- **Multiple Google Account Integration**: Connect and manage multiple Google Calendar accounts simultaneously
- **Unified Calendar View**: View events from all connected accounts in a single, cohesive interface
- **Account Color Coding**: Each account is assigned a unique color for easy visual distinction
- **Account Management**: Add, remove, and manage Google accounts with persistent storage

### 🎯 Smart Meeting Auto-Join

- **Automatic Meeting Detection**: Automatically detects upcoming meetings within the next hour
- **Selective Auto-Join**: Enable/disable auto-join functionality per account
- **Background Scheduler**: Intelligent background service that monitors for upcoming meetings
- **Meeting Link Detection**: Automatically extracts and uses meeting URLs from calendar events

### 📊 Flexible Calendar Views

- **Month View**: Traditional grid layout showing full month with event previews
- **Week View - List**: Clean list format showing events organized by day
- **Week View - Grid**: Time-based grid layout for detailed scheduling
- **Responsive Design**: All views adapt to window size changes
- **Smooth Scrolling**: Proper scroll support for all calendar views

### 🎨 Modern UI/UX

- **Native macOS Design**: Built with SwiftUI for native macOS experience
- **Consistent Toolbar**: All controls moved to toolbar for Finder-like consistency
- **Window Size Management**: Intelligent window resizing based on selected view
- **Responsive Layout**: UI adapts smoothly to different window sizes
- **Dark/Light Mode Support**: Automatic theme adaptation

### 🔧 Advanced Features

- **Persistent State**: Remembers view preferences, selected dates, and account settings
- **Secure Storage**: Uses macOS Keychain for secure OAuth token storage
- **Error Handling**: Comprehensive error handling with user-friendly messages
- **Background Refresh**: Automatic calendar data refresh with loading indicators

## 🛠 Technical Architecture

### Core Components

- **AppViewModel**: Central state management and business logic
- **GoogleOAuthService**: Handles Google OAuth authentication flow
- **GoogleCalendarService**: Manages calendar data fetching and synchronization
- **AutoJoinScheduler**: Background service for meeting detection and auto-join
- **KeychainStorage**: Secure storage for OAuth tokens

### View Architecture

- **ContentView**: Main application interface with navigation split view
- **CalendarMonthView**: Month grid layout with event previews
- **CalendarWeekView**: List-based week view with scrolling support
- **CalendarTimeGridWeekView**: Time-based grid layout for detailed scheduling
- **CalendarDayView**: Focused single-day view
- **MainCalendarContent**: Orchestrates the active calendar content and interactions
- **CalendarSidebar**: Account and calendar controls
- **EventDetailPopover**: Detailed event information display

### Data Models

- **CalendarEvent**: Represents calendar events with all metadata
- **GoogleAccount**: Manages account information and preferences
- **OAuthTokens**: Handles authentication token management

## 📱 User Interface

### Main Interface

- **Sidebar**: Account management and settings
- **Toolbar**: Navigation controls, view selection, and refresh
- **Main Area**: Calendar display with multiple view options

### Calendar Views

1. **Month View**
   - Grid layout showing full month
   - Event previews with color coding
   - "+X more" indicators for overflow
   - Responsive grid that adapts to window size

2. **Day View**
   - Focused single-day schedule
   - Precise time positioning

3. **Week List View**
   - Clean list format organized by day
   - Event details with time and location
   - Smooth scrolling support
   - Empty state handling

4. **Week Grid View**
   - Time-based grid layout
   - Hour-by-hour scheduling view
   - Event positioning by actual time
   - Detailed event information

### Controls and Navigation

- **View Mode Selector**: Switch between Month and Week views
- **Week Style Selector**: Toggle between List and Grid for week view
- **Date Navigation**: Previous/Next and Today buttons
- **Refresh Button**: Manual calendar data refresh

## 🔐 Security & Privacy

- **OAuth 2.0 Authentication**: Secure Google account authentication
- **Keychain Integration**: Secure token storage using macOS Keychain
- **Local Data Storage**: All sensitive data stored locally
- **No Data Collection**: No user data sent to external servers

## 🚀 Getting Started

### Prerequisites

- macOS 14.0 or later
- Xcode 15.0 or later (for development)
- Google account(s) with calendar access

### Installation

1. Clone the repository
2. Set up Google OAuth credentials (see below)
3. Open `rise.xcodeproj` in Xcode
4. Build and run the application
5. Add your Google accounts through the interface

### Setting Up Google OAuth

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select an existing one
3. Enable the Google Calendar API
4. Create OAuth 2.0 credentials:
   - Application type: macOS
   - Bundle ID: `com.yourdomain.rise` (or your preferred bundle ID)
5. Copy the Client ID from the credentials

Environment variables take precedence over the plist file. Choose one of these configuration methods:

#### Method 1: Environment Variables (Recommended)

Set environment variables before running the app:

**Option A: Manual Setup**

```bash
export GOOGLE_CLIENT_ID="your-client-id.apps.googleusercontent.com"
export GOOGLE_REDIRECT_SCHEME="com.googleusercontent.apps.your-client-id"
```

**Option B: Use Setup Script**

```bash
./scripts/setup-env.sh
```

#### Method 2: Configuration File

1. Copy `rise/Config/OAuthConfig.example.plist` to `rise/Config/OAuthConfig.plist`
2. Replace `YOUR_GOOGLE_CLIENT_ID` with your actual Client ID in both fields

For detailed setup instructions, see [rise/Config/README.md](rise/Config/README.md).

### Build and Install (Script)

From the repository root, you can build and install the app to `/Applications` using the helper script:

```bash
bash install.sh
```

This will run an Xcode Release build and copy `rise.app` into `/Applications`, then launch it.

### Usage

1. **Add Google Account**: Click "Add Google Account" in the sidebar
2. **Authorize Access**: Complete OAuth flow in your browser
3. **Configure Auto-Join**: Toggle auto-join for each account as needed
4. **Navigate Calendar**: Use toolbar controls to switch views and navigate dates
5. **View Events**: Click on events to see detailed information

## 🎯 Key Features Summary

### ✅ Implemented Features

- [x] Multi-Google account integration
- [x] OAuth 2.0 authentication
- [x] Calendar data synchronization
- [x] Multiple calendar views (Month, Week List, Week Grid)
- [x] Responsive UI design
- [x] Window size management
- [x] Auto-join meeting detection
- [x] Secure token storage
- [x] Persistent user preferences
- [x] Error handling and user feedback
- [x] Background data refresh
- [x] Event detail viewing
- [x] Account color coding
- [x] Smooth scrolling support
- [x] Native macOS integration

### 🤖 Auto-Join Behavior

- Joins meetings only for events you have accepted
- Checks for upcoming events every 60 seconds
- Launches meeting links within ±1 minute of the event start time
- Meeting link detection prefers Google Calendar's conference data; falls back to URL recognition for Google Meet, Zoom, Microsoft Teams, Webex, and BlueJeans

### 🔧 Technical Highlights

- **SwiftUI**: Modern declarative UI framework
- **Combine**: Reactive programming for state management
- **Keychain Services + UserDefaults**: Secure credential storage and local persistence
- **ASWebAuthenticationSession + PKCE**: OAuth 2.0 authentication flow
- **URLSession**: Network communication
- **Background timers (AutoJoinScheduler)**: Intelligent scheduling for auto-join

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guide](CONTRIBUTING.md) for details on how to submit pull requests, report issues, and contribute to the project.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 📋 Code of Conduct

This project adheres to the Contributor Covenant Code of Conduct. Please read [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md) for details.

---

**Rise** - Elevate your calendar management experience on macOS.
