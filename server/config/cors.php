<?php

return [

  'paths' => ['api/*', 'sanctum/csrf-cookie', 'uploads/*'],

  'allowed_methods' => ['*'],

  'allowed_origins' => [
    'https://app.medrush.cc',
    'http://localhost',
    'http://localhost:8080',
    'http://localhost:5000',
    'http://localhost:3000',
    'http://127.0.0.1',
  ],

  // Permitir localhost en cualquier puerto (Flutter web desde dev)
  'allowed_origins_patterns' => [
    '#^https?://localhost(:\d+)?$#',
    '#^https?://127\.0\.0\.1(:\d+)?$#',
    '#^https?://app\.medrush\.cc$#',
  ],

  'allowed_headers' => ['*'],

  'exposed_headers' => [],

  'max_age' => 60 * 60,

  'supports_credentials' => true,

];
