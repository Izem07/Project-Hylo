const express = require('express');
const { createProxyMiddleware } = require('http-proxy-middleware');

const app = express();
const PORT = 9090;

// Target can be overridden at startup via NAVIDROME_URL env var.
// e.g.  NAVIDROME_URL=https://music.tail1234.ts.net node server.js
const TARGET = process.env.NAVIDROME_URL || 'http://100.68.222.8:4533';

// CORS — allow the Flutter web dev server (any origin for local dev)
app.use((req, res, next) => {
  res.header('Access-Control-Allow-Origin', '*');
  res.header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.header('Access-Control-Allow-Headers', '*');
  if (req.method === 'OPTIONS') return res.sendStatus(200);
  next();
});

// Proxy all /rest/* calls to Navidrome
app.use(
  '/rest',
  createProxyMiddleware({
    target: TARGET,
    changeOrigin: true,
    secure: true, // verify SSL — set to false only if cert is self-signed
    on: {
      error: (err, req, res) => {
        console.error('[proxy error]', err.message);
        res.status(502).json({ error: 'Proxy error', message: err.message });
      },
    },
  })
);

app.get('/', (req, res) =>
  res.send(`Hylo CORS proxy running → ${TARGET}`)
);

app.listen(PORT, () => {
  console.log(`\n✅ Hylo CORS proxy  http://localhost:${PORT}`);
  console.log(`   Forwarding /rest/* → ${TARGET}`);
  console.log(`   Override target:  NAVIDROME_URL=https://your.ts.net node server.js\n`);
});
