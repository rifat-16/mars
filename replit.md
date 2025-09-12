# Mars Flutter App

## Overview

Mars is a Flutter mobile application designed to provide cross-platform functionality on Android and iOS. The app integrates Firebase services for backend functionality including user authentication, cloud data storage, and file storage capabilities. The application includes data visualization features through charts and uses a modern Material Design interface with custom icons and branding.

## User Preferences

Preferred communication style: Simple, everyday language.

## System Architecture

### Frontend Architecture
The application is built using Flutter framework, providing native performance across multiple platforms (Android, iOS, and Web). The UI follows Material Design principles with custom theming and branding elements including logo assets. The app uses Provider pattern for state management, ensuring predictable data flow and reactive UI updates.

### Authentication System
Firebase Authentication handles user login and registration workflows. The app implements PIN code authentication through a dedicated input field component, providing secure yet user-friendly access control.

### State Management
The application uses the Provider package for state management, following Flutter's recommended patterns for managing application state across widgets and screens.

### Data Visualization
Charts functionality is implemented using the charts_flutter package, allowing the app to display data in various chart formats for analytics or reporting purposes.

### Platform-Specific Configurations
- **Android**: Configured with proper package naming (com.mars.mars) and Firebase integration
- **iOS**: Native iOS project structure with proper asset management and launch screens
- **Web**: Progressive Web App capabilities with manifest configuration and service worker support

### UI/UX Components
- Material Design Icons Flutter for consistent iconography
- Custom logo assets for branding
- PIN code input fields for secure authentication
- Cupertino icons for iOS-style interface elements when needed

## External Dependencies

### Firebase Services
- **Firebase Core**: Foundation for all Firebase services
- **Firebase Authentication**: User authentication and account management
- **Cloud Firestore**: NoSQL document database for real-time data storage
- **Firebase Storage**: File and media storage service

### Third-Party Packages
- **charts_flutter**: Data visualization and charting capabilities
- **provider**: State management solution
- **pin_code_fields**: Secure PIN input components
- **material_design_icons_flutter**: Extended icon library

### Platform Services
- Firebase project configuration (mars-272dc) with proper API keys and project settings
- Google Services integration for Android platform
- iOS native integration through Xcode project configuration

### Development Tools
- Flutter SDK with Dart language support
- Firebase CLI for deployment and configuration management
- Flutter Lints for code quality and consistency