@echo off
echo ========================================
echo   CREATE ADMIN USER - Firebase Auth
echo ========================================
echo.

REM Admin credentials
set ADMIN_EMAIL=adrianalfajri@gmail.com
set ADMIN_PASSWORD=adri210404

echo Creating admin user...
echo Email: %ADMIN_EMAIL%
echo.

REM Note: This requires Firebase CLI to be logged in
firebase auth:export temp-users.json --project dompetalumni 2>nul

REM Create user JSON
echo [{"localId":"temp-admin","email":"%ADMIN_EMAIL%","emailVerified":true,"passwordHash":"password","salt":"salt","createdAt":"1","lastLoginAt":"1"}] > new-admin.json

echo.
echo ========================================
echo   MANUAL SETUP REQUIRED
echo ========================================
echo.
echo Firebase CLI cannot create users directly.
echo Please create admin account manually:
echo.
echo 1. Open: https://console.firebase.google.com/project/dompetalumni/authentication/users
echo 2. Click "Add user"
echo 3. Enter:
echo    Email: %ADMIN_EMAIL%
echo    Password: %ADMIN_PASSWORD%
echo 4. Click "Add user"
echo.
echo Then test login at: http://localhost:8000/admin/login
echo.
pause
