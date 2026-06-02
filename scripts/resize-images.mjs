import fs from 'fs';
import path from 'path';
import sharp from 'sharp';

const srcDir = './images/src';
const fullsDir = './images/fulls';
const thumbsDir = './images/thumbs';
const rawDir = './images/raw';

async function processImages() {
  console.log('--- Photo Resizing Automation ---');

  // Ensure directories exist
  try {
    if (!fs.existsSync(srcDir)) fs.mkdirSync(srcDir, { recursive: true });
    if (!fs.existsSync(fullsDir)) fs.mkdirSync(fullsDir, { recursive: true });
    if (!fs.existsSync(thumbsDir)) fs.mkdirSync(thumbsDir, { recursive: true });
    if (!fs.existsSync(rawDir)) fs.mkdirSync(rawDir, { recursive: true });
  } catch (err) {
    console.error('Error creating directories:', err);
    process.exit(1);
  }

  let files;
  try {
    files = fs.readdirSync(srcDir);
  } catch (err) {
    console.error('Error reading source directory:', err);
    process.exit(1);
  }

  const imageExtensions = ['.jpg', '.jpeg', '.png', '.webp', '.tiff'];
  const images = files.filter(file => {
    const ext = path.extname(file).toLowerCase();
    return imageExtensions.includes(ext);
  });

  if (images.length === 0) {
    console.log('No new images found in images/src/ to process.');
    return;
  }

  console.log(`Found ${images.length} new image(s) to process.`);

  for (const file of images) {
    const srcPath = path.join(srcDir, file);
    const fullPath = path.join(fullsDir, file);
    const thumbPath = path.join(thumbsDir, file);
    const rawPath = path.join(rawDir, file);

    console.log(`Processing: ${file}`);

    try {
      // 1. Generate full-resolution display image (width 1920, preserve EXIF)
      await sharp(srcPath)
        .resize({
          width: 1920,
          withoutEnlargement: true,
          fit: 'inside'
        })
        .withMetadata() // Crucial for client-side EXIF reader
        .toFile(fullPath);
      console.log(`  -> Saved full image to ${fullPath}`);

      // 2. Generate thumbnail image (width 512, preserve EXIF)
      await sharp(srcPath)
        .resize({
          width: 512,
          withoutEnlargement: true,
          fit: 'inside'
        })
        .withMetadata() // Crucial for client-side EXIF reader
        .toFile(thumbPath);
      console.log(`  -> Saved thumbnail to ${thumbPath}`);

      // 3. Archive the original high-resolution photo
      fs.renameSync(srcPath, rawPath);
      console.log(`  -> Archived original to ${rawPath}`);
    } catch (err) {
      console.error(`  [ERROR] Failed to process ${file}:`, err);
    }
  }

  console.log('---------------------------------');
  console.log('Photo processing complete!');
}

processImages().catch(err => {
  console.error('Fatal error during photo processing:', err);
  process.exit(1);
});
