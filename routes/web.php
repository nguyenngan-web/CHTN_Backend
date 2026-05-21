<?php

use Illuminate\Support\Facades\Route;

/*
|--------------------------------------------------------------------------
| Web Routes
|--------------------------------------------------------------------------
|
| Here is where you can register web routes for your application. These
| routes are loaded by the RouteServiceProvider within a group which
| contains the "web" middleware group. Now create something great!
|
*/


Route::get('/', function () {
    return view('welcome');
});

Route::get('/test-db', function () {
    try {
        \DB::connection()->getPdo();
        $dbName = \DB::connection()->getDatabaseName();
        return response()->json([
            'status' => 'success',
            'message' => 'Kết nối Database thành công!',
            'database' => $dbName
        ]);
    } catch (\Exception $e) {
        return response()->json([
            'status' => 'error',
            'message' => 'Không thể kết nối Database!',
            'error' => $e->getMessage()
        ], 500);
    }
});
