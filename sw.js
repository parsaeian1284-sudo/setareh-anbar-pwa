// Setareh PWA service worker: app shell + runtime cache for same-origin and CDN assets.
const CACHE = 'setareh-offline-34';
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
  const sameOrigin = url.origin === self.location.origin;
  const isShell = sameOrigin && APP_SHELL.some(
    (path) => new URL(path, self.location.href).pathname === url.pathname
  );

  // App shell: return cached copy immediately and refresh it in the background.
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
        'برای اولین بار برنامه را با اینترنت باز کنید تا فایل‌های لازم ذخیره شوند.',
        { status: 503, headers: { 'Content-Type': 'text/plain; charset=utf-8' } }
      );
    })());
    return;
  }

  // Cache successful same-origin resources and CDN scripts/styles after first online use.
  // This supports offline access to the app shell and previously loaded libraries.
  event.respondWith((async () => {
    const cache = await caches.open(CACHE);
    try {
      const response = await fetch(request);
      if (response && (response.ok || response.type === 'opaque')) {
        event.waitUntil(cache.put(request, response.clone()));
      }
      return response;
    } catch (error) {
      const cached = await cache.match(request);
      if (cached) return cached;
      if (request.mode === 'navigate') {
        return (await cache.match('./index.html')) ||
          new Response('آفلاین هستید؛ این صفحه قبلاً ذخیره نشده است.', { status: 503 });
      }
      return new Response('', { status: 504 });
    }
  })());
});
