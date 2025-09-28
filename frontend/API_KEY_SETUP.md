# 🔐 API Key Setup Guide

## Quick Fix for GitHub Push Protection

GitHub detected API keys in your code and blocked the push. Here's how to fix it:

### 1. Set Environment Variable (Recommended)

**For Xcode development:**
1. Open your project in Xcode
2. Go to Product → Scheme → Edit Scheme
3. Select "Run" → "Arguments" → "Environment Variables"
4. Add: `OPENAI_API_KEY` = `your_actual_api_key_here`

**For terminal/command line:**
```bash
export OPENAI_API_KEY="your_actual_api_key_here"
```

### 2. Alternative: Direct Configuration

If you prefer to hardcode (NOT recommended for production):

1. Open `Grounded/CrisisManager.swift`
2. Find line 51: `private let openAIAPIKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"] ?? "YOUR_OPENAI_API_KEY_HERE"`
3. Replace `"YOUR_OPENAI_API_KEY_HERE"` with your actual key

### 3. For Python Scripts

**For generate_audio.py:**
```bash
export OPENAI_API_KEY="your_actual_api_key_here"
python generate_audio.py
```

### 4. Verify Setup

The app will now use environment variables instead of hardcoded keys. Check the console logs to confirm it's working.

## 🔒 Security Notes

- ✅ **Never commit API keys** to version control
- ✅ **Use environment variables** for sensitive data
- ✅ **Add .env files** to .gitignore
- ✅ **Use different keys** for development/production

## 🚀 Ready to Push

After setting up environment variables, you can safely push to GitHub:

```bash
git add .
git commit -m "Remove hardcoded API keys, use environment variables"
git push origin main
```
