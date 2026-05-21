#!/bin/bash
# Exit immediately if a command exits with a non-zero status
set -e

echo "=================================================="
echo "      RUNNING RAILWAY PRE-DEPLOYMENT TASKS        "
echo "=================================================="

# 1. Diagnose Database Connection
echo "--> Diagnosing database connectivity..."
php -r '
try {
    // Manually load Laravel bootstrap/autoload to access env helper
    require __DIR__ . "/vendor/autoload.php";
    $app = require_once __DIR__ . "/bootstrap/app.php";
    $app->make(Illuminate\Contracts\Console\Kernel::class)->bootstrap();

    $host = env("DB_HOST", env("MYSQLHOST", "127.0.0.1"));
    $port = env("DB_PORT", env("MYSQLPORT", "3306"));
    $db = env("DB_DATABASE", env("MYSQLDATABASE"));
    $user = env("DB_USERNAME", env("MYSQLUSER"));
    $pass = env("DB_PASSWORD", env("MYSQLPASSWORD"));

    echo "Diagnostic Details:\n";
    echo "  - Host: " . $host . "\n";
    echo "  - Port: " . $port . "\n";
    echo "  - Database: " . $db . "\n";
    echo "  - Username: " . $user . "\n";
    
    if ($host === "127.0.0.1" || $host === "localhost") {
        echo "WARNING: You are trying to connect to localhost (127.0.0.1) on Railway.\n";
        echo "Please make sure you have created a MySQL service in Railway and linked it to this service,\n";
        echo "or manually set MYSQLHOST/DB_HOST to your Railway database address.\n";
    }

    echo "Attempting raw PDO connection...\n";
    $options = [
        PDO::ATTR_TIMEOUT => 5,
        PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION
    ];
    if (env("MYSQL_ATTR_SSL_CA")) {
        $options[PDO::MYSQL_ATTR_SSL_CA] = env("MYSQL_ATTR_SSL_CA");
    }
    $sslVerify = env("DB_SSL_VERIFY", true);
    if ($sslVerify === "false" || $sslVerify === false) {
        $options[PDO::MYSQL_ATTR_SSL_VERIFY_SERVER_CERT] = false;
    }
    
    $pdo = new PDO("mysql:host=$host;port=$port;dbname=$db", $user, $pass, $options);
    echo "SUCCESS: Raw database connection established!\n";
} catch (\Exception $e) {
    echo "ERROR: Database connection failed!\n";
    echo "Reason: " . $e->getMessage() . "\n";
}
'

# 2. Set storage permissions
echo "--> Setting storage permissions..."
chmod -R 775 storage bootstrap/cache || true

# 3. Create storage symlink
echo "--> Creating storage symlink..."
php artisan storage:link --force

# 4. Run migrations
echo "--> Running database migrations..."
php artisan migrate --force

# 5. Clear cached configuration to ensure environment variables are read dynamically
echo "--> Clearing configuration cache..."
php artisan config:clear
php artisan route:clear
php artisan view:clear

# 6. Re-cache config, routes, and views for production performance
echo "--> Caching config, routes, and views..."
php artisan config:cache
php artisan route:cache
php artisan view:cache

echo "=================================================="
echo "    PRE-DEPLOYMENT TASKS COMPLETED SUCCESSFULLY   "
echo "=================================================="
