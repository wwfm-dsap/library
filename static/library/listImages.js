const fs = require('fs');
const path = require('path');
const express = require('express');

const app = express();
const directoryPath = path.join(__dirname, '_theme-explorer/flag');

app.get('/images', (req, res) => {
  fs.readdir(directoryPath, (err, files) => {
    if (err) {
      return res.status(500).send('Unable to scan directory');
    }
    const images = files.filter(file => file.match(/\.(jpg|jpeg|png|gif|webp)$/i));
    res.json(images);
  });
});

app.use(express.static(__dirname));
app.listen(3000, () => console.log('Server running on http://localhost:3000'));
