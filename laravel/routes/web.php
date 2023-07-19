<?php

use Illuminate\Support\Facades\Route;
use Illuminate\Support\Facades\DB;

/*
|--------------------------------------------------------------------------
| Web Routes
|--------------------------------------------------------------------------
|
| Here is where you can register web routes for your application. These
| routes are loaded by the RouteServiceProvider and all of them will
| be assigned to the "web" middleware group. Make something great!
|
*/

Route::get('/', function () {
    // using the database directly, sue me
    DB::table('cats')->insert([
        'url' => 'https://cataas.com/cat/says/' . urlencode(date('Y-m-d H:i:s')),
    ]);

    $cats = App\Models\Cat::all()->sortByDesc('url');
    return view('welcome', ['cats' => $cats]);
});
