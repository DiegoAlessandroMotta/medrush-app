<?php

return [

  'paths' => ['api/*', 'sanctum/csrf-cookie', 'uploads/*'],

  'allowed_methods' => ['*'],

  'allowed_origins' => ['*'],

  // Permitir localhost en cualquier puerto (Flutter web desde dev)
  'allowed_origins_patterns' => [
    '#^https?://localhost(:\d+)?$#',
    '#^https?://127\.0\.0\.1(:\d+)?$#',
  ],

  'allowed_headers' => ['*'],

  'exposed_headers' => [],

  'max_age' => 60 * 60,

  'supports_credentials' => false,

];
