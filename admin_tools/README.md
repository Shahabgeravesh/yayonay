# YayoNay Admin Panel

A comprehensive web-based admin interface for managing the YayoNay application.

## Features

- Category and subcategory management
- User statistics and management
- Content moderation tools
- Database maintenance utilities
- Backup and restore functionality
- Real-time updates

## Setup

1. Clone the repository
```bash
git clone <repository-url>
cd admin_tools
```

2. Set up Firebase configuration
```bash
# Copy the template configuration file
cp config.template.js config.js

# Edit config.js with your Firebase credentials
# Get these from your Firebase Console
```

3. Install Firebase CLI
```bash
npm install -g firebase-tools
```

4. Login to Firebase
```bash
firebase login
```

5. Initialize Firebase
```bash
firebase init
```
Select the following options:
- Choose "Hosting"
- Select your Firebase project
- Use "." as your public directory
- Configure as a single-page app
- Don't overwrite existing files

6. Deploy
```bash
firebase deploy
```

## Security

- The admin panel requires Firebase Authentication
- Only authorized administrators can access the panel
- All database operations are protected by Firebase Security Rules
- Sensitive configuration is not included in version control

## Development

To run locally:
```bash
# Install local server (if needed)
npm install -g http-server

# Start local server
http-server
```

## Contributing

1. Create a new branch for your feature
2. Make your changes
3. Test thoroughly
4. Submit a pull request

## Important Notes

- Never commit `config.js` with real Firebase credentials
- Always use environment variables for sensitive data
- Keep Firebase security rules up to date
- Regularly backup your database

## License

[Your License] 