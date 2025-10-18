<?php

return [

  'paths' => ['api/*', 'sanctum/csrf-cookie', 'uploads/*'],

  'allowed_methods' => ['*'],

  'allowed_origins' => ['*'],

  'allowed_origins_patterns' => [],

  'allowed_headers' => ['*'],

  'exposed_headers' => [],

  // 'allowed_methods' => ['GET', 'OPTIONS'],

  'max_age' => 60 * 60,

  'supports_credentials' => false,

];
