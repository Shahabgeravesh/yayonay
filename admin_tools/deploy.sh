#!/bin/bash

echo "🚀 Deploying YayoNay Admin Panel..."

# Ensure we're in the right directory
cd "$(dirname "$0")"

# Deploy to Firebase
echo "📤 Deploying to Firebase..."
firebase deploy --only hosting

echo "✅ Deployment complete!"
echo "🌎 Your app is live at: https://yayonay-e7f58.web.app" 