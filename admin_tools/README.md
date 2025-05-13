# YayoNay Admin Tools

This folder contains easy-to-use tools for managing your YayoNay app's content.

## Setup (One-time only)
1. Make sure you have Node.js installed on your computer
2. Copy your `serviceAccountKey.json` file to the parent directory
3. Open Terminal/Command Prompt
4. Navigate to this directory
5. Run `npm install firebase-admin`

## Using the Admin Tool

### To start the tool:
1. Open Terminal/Command Prompt
2. Navigate to this directory
3. Run: `node manage_categories.js`

### Available Options:
1. **Add new category**
   - Enter category name
   - Optionally add an image URL
   - Set display order (lower numbers appear first)

2. **Add subcategory**
   - Choose a parent category
   - Enter subcategory name
   - Optionally add an image URL
   - Set display order

3. **List all categories**
   - Shows all categories and subcategories
   - Useful for checking current structure

4. **Update category**
   - Choose a category to update
   - Update name, image, or order
   - Skip any field you don't want to change

5. **Update subcategory**
   - Choose a subcategory to update
   - Update name, image, or order
   - Skip any field you don't want to change

6. **Delete category**
   - Remove a category and all its subcategories
   - Requires confirmation

7. **Delete subcategory**
   - Remove a specific subcategory
   - Requires confirmation

8. **Exit**
   - Safely close the admin tool

### Tips:
- Always keep track of the order numbers you use
- Use descriptive names for categories and subcategories
- When in doubt, use the "List all" option to see the current structure
- Be careful with the delete options - they cannot be undone!

### Need Help?
If you encounter any issues:
1. Make sure your `serviceAccountKey.json` file is in the correct location
2. Check your internet connection
3. Contact the development team if problems persist 