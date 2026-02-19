<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Http;

class ReverbHealthController extends Controller
{
  public function __invoke(): JsonResponse
  {
    $options = config('reverb.apps.apps')[0]['options'] ?? [];

    $host = $options['host'] ?? env('REVERB_HOST', '127.0.0.1');
    if (in_array($host, ['0.0.0.0', '::', '', '127.0.0.1'], true)) {
      $host = env('REVERB_INTERNAL_HOST', 'reverb');
    }

    $port = $options['port'] ?? env('REVERB_PORT', 9000);
    $scheme = $options['scheme'] ?? env('REVERB_SCHEME', 'http');

    $url = sprintf('%s://%s:%s/up', $scheme, $host, $port);

    try {
      $response = Http::timeout(2)->get($url);

      if ($response->successful()) {
        return response()->json([
          'ok' => true,
          'message' => 'Reverb is up',
          'reverb' => $response->json(),
          'timestamp' => now()->toIso8601String(),
        ], 200);
      }

      return response()->json([
        'ok' => false,
        'message' => 'HTTP ' . $response->status(),
        'timestamp' => now()->toIso8601String(),
      ], 503);
    } catch (\Throwable $e) {
      return response()->json([
        'ok' => false,
        'message' => $e->getMessage(),
        'timestamp' => now()->toIso8601String(),
      ], 503);
    }
  }
}
