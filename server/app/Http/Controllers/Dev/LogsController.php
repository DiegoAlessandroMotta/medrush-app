<?php

namespace App\Http\Controllers\Dev;

use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Routing\Controller;
use Illuminate\Support\Facades\File;

class LogsController extends Controller
{
    /**
     * Muestra los últimos logs de Laravel
     * SOLO PARA DESARROLLO - BORRAR EN PRODUCCIÓN
     */
    public function show(Request $request): JsonResponse
    {
        $lines = $request->query('lines', 200); // Número de líneas a mostrar
        $logPath = storage_path('logs/laravel.log');

        if (!File::exists($logPath)) {
            return response()->json([
                'error' => 'Log file not found',
                'path' => $logPath,
            ], 404);
        }

        // Leer las últimas N líneas del archivo
        $logContent = File::get($logPath);
        $logLines = explode("\n", $logContent);
        $lastLines = array_slice($logLines, -$lines);

        return response()->json([
            'total_lines' => count($logLines),
            'showing_lines' => count($lastLines),
            'logs' => implode("\n", $lastLines),
            'file_size' => File::size($logPath),
            'last_modified' => date('Y-m-d H:i:s', File::lastModified($logPath)),
        ]);
    }

    /**
     * Limpia el archivo de logs
     */
    public function clear(): JsonResponse
    {
        $logPath = storage_path('logs/laravel.log');

        if (!File::exists($logPath)) {
            return response()->json([
                'error' => 'Log file not found',
            ], 404);
        }

        File::put($logPath, '');

        return response()->json([
            'message' => 'Logs cleared successfully',
        ]);
    }
}
