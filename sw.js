// Offline-first service worker for Setareh warehouse PWA.
const CACHE = 'setareh-stage2-1';
const APP_SHELL = [
  './',
  './index.html',
  './manifest.json',
  './cloud-config.js',
  './icon-192.png',
  './icon-512.png'
];

self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open(CACHE)
      .then((cache) => cache.addAll(APP_SHELL))
      .then(() => self.skipWaiting())
  );
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys()
      .then((keys) => Promise.all(
        keys.filter((key) => key.startsWith('setareh-') && key !== CACHE)
          .map((key) => caches.delete(key))
      ))
      .then(() => self.clients.claim())
  );
});

self.addEventListener('fetch', (event) => {
  const request = event.request;
  if (request.method !== 'GET') return;

  const url = new URL(request.url);
  if (url.origin !== self.location.origin) return;

  const isShell = APP_SHELL.some(
    (path) => new URL(path, self.location.href).pathname === url.pathname
  );

  if (isShell) {
    event.respondWith((async () => {
      const cache = await caches.open(CACHE);
      const cached = await cache.match(request) || await cache.match('./index.html');
      const update = fetch(request).then((response) => {
        if (response && response.ok) cache.put(request, response.clone());
        return response;
      }).catch(() => null);

      if (cached) {
        event.waitUntil(update);
        return cached;
      }

      const fresh = await update;
      return fresh || new Response(
        'برنامه در حالت آفلاین در دسترس نیست. یک بار با اینترنت بازش کنید.',
        { status: 503, headers: { 'Content-Type': 'text/plain; charset=utf-8' } }
      );
    })());
    return;
  }

  event.respondWith(
    fetch(request).then((response) => {
      if (response && response.ok) {
        const copy = response.clone();
        event.waitUntil(caches.open(CACHE).then((cache) => cache.put(request, copy)));
      }
      return response;
    }).catch(async () => {
      const cached = await caches.match(request);
      if (cached) return cached;
      if (request.mode === 'navigate') {
        return (await caches.match('./index.html')) ||
          new Response('آفلاین هستید.', { status: 503 });
      }
      return new Response('', { status: 504 });
    })
  );
});
