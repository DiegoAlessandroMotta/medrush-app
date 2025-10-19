'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';

const RESOURCES = {"assets/AssetManifest.bin": "52b4a0fb292160250148a2c3cda2a0d5",
"assets/AssetManifest.bin.json": "eff974ff781578aa9c4432ba80207759",
"assets/AssetManifest.json": "d2bc94bc35f97d0e569b4a5cc31683d8",
"assets/assets/images/logo.png": "036a975153d22c7b37850d0d5a617848",
"assets/assets/images/logoicon.png": "9da7ef485a1c53fa4ac21077e4b1782d",
"assets/assets/images/logoletter.png": "47f6e9776344380f2d96b5387aa7bd01",
"assets/assets/images/logonoletter.png": "2b8c2218bae8613033a9602d0e02d8a9",
"assets/assets/images/siluetalogo.png": "524bcf023f6f7b4679d58ea253a116d1",
"assets/FontManifest.json": "b740a59a6b9ace361f84e9c31f28fce9",
"assets/fonts/MaterialIcons-Regular.otf": "2aeec9f890dc9fb1533e3f512768d1b5",
"assets/NOTICES": "d6ea952508ae65e4176938f6e5819ca0",
"assets/packages/fluttertoast/assets/toastify.css": "a85675050054f179444bc5ad70ffc635",
"assets/packages/fluttertoast/assets/toastify.js": "56e2c9cedd97f10e7e5f1cebd85d53e3",
"assets/packages/flutter_map/lib/assets/flutter_map_logo.png": "208d63cc917af9713fc9572bd5c09362",
"assets/packages/lucide_icons_flutter/assets/build_font/LucideVariable-w100.ttf": "5d5f12dc9e2d93e421626ce82745b3a5",
"assets/packages/lucide_icons_flutter/assets/build_font/LucideVariable-w200.ttf": "3c46ff7515368b68e570ce96901ccc24",
"assets/packages/lucide_icons_flutter/assets/build_font/LucideVariable-w300.ttf": "5ef7ed6d126034fa4d549208d1490814",
"assets/packages/lucide_icons_flutter/assets/build_font/LucideVariable-w400.ttf": "f2578f0d282fc7091553c613d78f36a3",
"assets/packages/lucide_icons_flutter/assets/build_font/LucideVariable-w500.ttf": "8242e3c2ccae9cedc14213f26454410d",
"assets/packages/lucide_icons_flutter/assets/build_font/LucideVariable-w600.ttf": "8909e18b2d34b952b6ef8b911c1f1cae",
"assets/packages/lucide_icons_flutter/assets/lucide.ttf": "d12b1a40489d6b50f0363df6f0d6d092",
"assets/shaders/ink_sparkle.frag": "ecc85a2e95f5e9f53123dcaf8cb9b6ce",
"canvaskit/canvaskit.js": "140ccb7d34d0a55065fbd422b843add6",
"canvaskit/canvaskit.js.symbols": "58832fbed59e00d2190aa295c4d70360",
"canvaskit/canvaskit.wasm": "07b9f5853202304d3b0749d9306573cc",
"canvaskit/chromium/canvaskit.js": "5e27aae346eee469027c80af0751d53d",
"canvaskit/chromium/canvaskit.js.symbols": "193deaca1a1424049326d4a91ad1d88d",
"canvaskit/chromium/canvaskit.wasm": "24c77e750a7fa6d474198905249ff506",
"canvaskit/skwasm.js": "1ef3ea3a0fec4569e5d531da25f34095",
"canvaskit/skwasm.js.symbols": "0088242d10d7e7d6d2649d1fe1bda7c1",
"canvaskit/skwasm.wasm": "264db41426307cfc7fa44b95a7772109",
"canvaskit/skwasm_heavy.js": "413f5b2b2d9345f37de148e2544f584f",
"canvaskit/skwasm_heavy.js.symbols": "3c01ec03b5de6d62c34e17014d1decd3",
"canvaskit/skwasm_heavy.wasm": "8034ad26ba2485dab2fd49bdd786837b",
"favicon.png": "dd4617664ef1ae500a2502689102afc9",
"flutter.js": "888483df48293866f9f41d3d9274a779",
"flutter_bootstrap.js": "65288e06eb9ba3356cff8e47d4cb2900",
"icons/Icon-192.png": "b19efcda4c1ed3070df80588747da1d0",
"icons/Icon-512.png": "53961beef7d31758919709bde3064015",
"icons/Icon-maskable-192.png": "b19efcda4c1ed3070df80588747da1d0",
"icons/Icon-maskable-512.png": "53961beef7d31758919709bde3064015",
"index.html": "ac2bd3f7efdf9901e4de1cd97f7c478a",
"/": "ac2bd3f7efdf9901e4de1cd97f7c478a",
"main.dart.js": "1d9c4a66888be9d0ec080a94f34997dd",
"manifest.json": "254e3c5f1ed571077401e6bae74579c9",
"version.json": "e78a02bb91c6ffbf97536b4d2b957491"};
// The application shell files that are downloaded before a service worker can
// start.
const CORE = ["main.dart.js",
"index.html",
"flutter_bootstrap.js",
"assets/AssetManifest.bin.json",
"assets/FontManifest.json"];

// During install, the TEMP cache is populated with the application shell files.
self.addEventListener("install", (event) => {
  self.skipWaiting();
  return event.waitUntil(
    caches.open(TEMP).then((cache) => {
      return cache.addAll(
        CORE.map((value) => new Request(value, {'cache': 'reload'})));
    })
  );
});
// During activate, the cache is populated with the temp files downloaded in
// install. If this service worker is upgrading from one with a saved
// MANIFEST, then use this to retain unchanged resource files.
self.addEventListener("activate", function(event) {
  return event.waitUntil(async function() {
    try {
      var contentCache = await caches.open(CACHE_NAME);
      var tempCache = await caches.open(TEMP);
      var manifestCache = await caches.open(MANIFEST);
      var manifest = await manifestCache.match('manifest');
      // When there is no prior manifest, clear the entire cache.
      if (!manifest) {
        await caches.delete(CACHE_NAME);
        contentCache = await caches.open(CACHE_NAME);
        for (var request of await tempCache.keys()) {
          var response = await tempCache.match(request);
          await contentCache.put(request, response);
        }
        await caches.delete(TEMP);
        // Save the manifest to make future upgrades efficient.
        await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
        // Claim client to enable caching on first launch
        self.clients.claim();
        return;
      }
      var oldManifest = await manifest.json();
      var origin = self.location.origin;
      for (var request of await contentCache.keys()) {
        var key = request.url.substring(origin.length + 1);
        if (key == "") {
          key = "/";
        }
        // If a resource from the old manifest is not in the new cache, or if
        // the MD5 sum has changed, delete it. Otherwise the resource is left
        // in the cache and can be reused by the new service worker.
        if (!RESOURCES[key] || RESOURCES[key] != oldManifest[key]) {
          await contentCache.delete(request);
        }
      }
      // Populate the cache with the app shell TEMP files, potentially overwriting
      // cache files preserved above.
      for (var request of await tempCache.keys()) {
        var response = await tempCache.match(request);
        await contentCache.put(request, response);
      }
      await caches.delete(TEMP);
      // Save the manifest to make future upgrades efficient.
      await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
      // Claim client to enable caching on first launch
      self.clients.claim();
      return;
    } catch (err) {
      // On an unhandled exception the state of the cache cannot be guaranteed.
      console.error('Failed to upgrade service worker: ' + err);
      await caches.delete(CACHE_NAME);
      await caches.delete(TEMP);
      await caches.delete(MANIFEST);
    }
  }());
});
// The fetch handler redirects requests for RESOURCE files to the service
// worker cache.
self.addEventListener("fetch", (event) => {
  if (event.request.method !== 'GET') {
    return;
  }
  var origin = self.location.origin;
  var key = event.request.url.substring(origin.length + 1);
  // Redirect URLs to the index.html
  if (key.indexOf('?v=') != -1) {
    key = key.split('?v=')[0];
  }
  if (event.request.url == origin || event.request.url.startsWith(origin + '/#') || key == '') {
    key = '/';
  }
  // If the URL is not the RESOURCE list then return to signal that the
  // browser should take over.
  if (!RESOURCES[key]) {
    return;
  }
  // If the URL is the index.html, perform an online-first request.
  if (key == '/') {
    return onlineFirst(event);
  }
  event.respondWith(caches.open(CACHE_NAME)
    .then((cache) =>  {
      return cache.match(event.request).then((response) => {
        // Either respond with the cached resource, or perform a fetch and
        // lazily populate the cache only if the resource was successfully fetched.
        return response || fetch(event.request).then((response) => {
          if (response && Boolean(response.ok)) {
            cache.put(event.request, response.clone());
          }
          return response;
        });
      })
    })
  );
});
self.addEventListener('message', (event) => {
  // SkipWaiting can be used to immediately activate a waiting service worker.
  // This will also require a page refresh triggered by the main worker.
  if (event.data === 'skipWaiting') {
    self.skipWaiting();
    return;
  }
  if (event.data === 'downloadOffline') {
    downloadOffline();
    return;
  }
});
// Download offline will check the RESOURCES for all files not in the cache
// and populate them.
async function downloadOffline() {
  var resources = [];
  var contentCache = await caches.open(CACHE_NAME);
  var currentContent = {};
  for (var request of await contentCache.keys()) {
    var key = request.url.substring(origin.length + 1);
    if (key == "") {
      key = "/";
    }
    currentContent[key] = true;
  }
  for (var resourceKey of Object.keys(RESOURCES)) {
    if (!currentContent[resourceKey]) {
      resources.push(resourceKey);
    }
  }
  return contentCache.addAll(resources);
}
// Attempt to download the resource online before falling back to
// the offline cache.
function onlineFirst(event) {
  return event.respondWith(
    fetch(event.request).then((response) => {
      return caches.open(CACHE_NAME).then((cache) => {
        cache.put(event.request, response.clone());
        return response;
      });
    }).catch((error) => {
      return caches.open(CACHE_NAME).then((cache) => {
        return cache.match(event.request).then((response) => {
          if (response != null) {
            return response;
          }
          throw error;
        });
      });
    })
  );
}
