/* eslint-disable no-console */
const fs = require('fs');
const path = require('path');
const admin = require('firebase-admin');

const serviceAccountPath =
  process.env.GOOGLE_APPLICATION_CREDENTIALS ||
  path.resolve(__dirname, '../serviceAccountKey.json');

if (!fs.existsSync(serviceAccountPath)) {
  console.error(
    'Missing service account key. Set GOOGLE_APPLICATION_CREDENTIALS or place serviceAccountKey.json at project root.',
  );
  process.exit(1);
}

const dataPath = path.resolve(__dirname, '../data/foods.json');
if (!fs.existsSync(dataPath)) {
  console.error('Missing data file: data/foods.json');
  process.exit(1);
}

const raw = fs.readFileSync(dataPath, 'utf8');
const foods = JSON.parse(raw);

if (!Array.isArray(foods)) {
  console.error('foods.json must be an array of objects.');
  process.exit(1);
}

admin.initializeApp({
  credential: admin.credential.cert(require(serviceAccountPath)),
});

const db = admin.firestore();

function normalizeFood(doc) {
  return {
    title: String(doc.title || '').trim(),
    subtitle: String(doc.subtitle || '').trim(),
    category: String(doc.category || '').trim(),
    description: String(doc.description || '').trim(),
    imageUrl: String(doc.imageUrl || '').trim(),
    time: String(doc.time || '').trim(),
    price: Number(doc.price || 0),
    rating: Number(doc.rating || 0),
    calories: Number(doc.calories || 0),
    ingredients: Array.isArray(doc.ingredients) ? doc.ingredients : [],
    foodType: Array.isArray(doc.foodType) ? doc.foodType : [],
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  };
}

async function run() {
  const batch = db.batch();
  let count = 0;

  for (const doc of foods) {
    const data = normalizeFood(doc);
    if (!data.title) continue;
    const ref = db.collection('foods').doc();
    batch.set(ref, data, { merge: true });
    count += 1;
    if (count % 400 === 0) {
      await batch.commit();
    }
  }

  if (count % 400 !== 0) {
    await batch.commit();
  }

  console.log(`Imported ${count} food items.`);
}

run().catch((err) => {
  console.error(err);
  process.exit(1);
});
