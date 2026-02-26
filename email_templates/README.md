# Email Templates Setup Guide

## Logo Setup

Both email templates now use your PNG logo instead of CSS-drawn graphics.

### Steps to Upload Your Logo:

1. **Create a Storage Bucket in Supabase:**
   - Go to your Supabase Dashboard
   - Navigate to Storage
   - Create a new public bucket called `assets`
   - Make it public (Settings → Public bucket: ON)

2. **Upload Your Logo:**
   - Upload your `openlist-logo.png` to the `assets` bucket
   - The logo should be square (recommended: 512x512px or 1024x1024px)
   - PNG format with transparent background works best

3. **Get the Public URL:**
   - After upload, click on the file
   - Copy the public URL
   - It will look like: `https://your-project-id.supabase.co/storage/v1/object/public/assets/openlist-logo.png`

4. **Update the Email Templates:**
   - Replace `https://your-supabase-project.supabase.co/storage/v1/object/public/assets/openlist-logo.png`
   - With your actual Supabase Storage URL in both:
     - `email_templates/verification_email.html`
     - `email_templates/password_reset_email.html`

### Alternative: Use a CDN

If you prefer, you can host the logo on:
- Cloudinary
- imgix
- AWS S3
- Any public CDN

Just replace the `src` attribute in the `<img>` tag with your CDN URL.

## Uploading Templates to Supabase

1. Go to Supabase Dashboard → Authentication → Email Templates
2. For **Confirm signup** template:
   - Copy the entire content of `verification_email.html`
   - Paste into the template editor
3. For **Reset password** template:
   - Copy the entire content of `password_reset_email.html`
   - Paste into the template editor
4. Save both templates

## Testing

Send a test email from Supabase to verify:
- Logo displays correctly
- All styling works
- Links are functional
- Responsive design works on mobile

## Notes

- The logo container has a white background with shadow
- Logo is set to `object-fit: contain` to maintain aspect ratio
- Works perfectly with transparent PNG logos
- Email clients support: Gmail, Outlook, Apple Mail, Yahoo, etc.
