const CACHE_NAME = 'sosafernando-v1';
const ASSETS = [
  '/',
  '/index.html',
  '/cv.html',
  '/cv-gerencia.html',
  '/assets/css/main.css',
  '/assets/js/functions-min.js',
  '/assets/img/logo.png',
  '/assets/img/introduction-visual.png',
  '/assets/img/about-visual.png',
  '/assets/img/contact-visual.png',
  '/assets/img/kubernetes.png',
  '/assets/img/blockchain.png',
  '/manifest.json'
];

// Install — cache critical assets
self.addEventListener('install', function(e) {
  e.waitUntil(
    caches.open(CACHE_NAME).then(function(cache) {
      return cache.addAll(ASSETS);
    })
  );
  self.skipWaiting();
});

// Activate — clean old caches
self.addEventListener('activate', function(e) {
  e.waitUntil(
    caches.keys().then(function(keys) {
      return Promise.all(
        keys.filter(function(k) { return k !== CACHE_NAME; }).map(function(k) { return caches.delete(k); })
      );
    })
  );
  self.clients.claim();
});

// Fetch — network first, fallback to cache
self.addEventListener('fetch', function(e) {
  e.respondWith(
    fetch(e.request).then(function(response) {
      var clone = response.clone();
      caches.open(CACHE_NAME).then(function(cache) { cache.put(e.request, clone); });
      return response;
    }).catch(function() {
      return caches.match(e.request);
    })
  );
});
