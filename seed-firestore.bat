@echo off
echo Seeding Firestore data via REST API...
echo.

REM Get Firebase project ID
set PROJECT_ID=dompetalumni

echo Creating settings document...
curl -X PATCH ^
  "https://firestore.googleapis.com/v1/projects/%PROJECT_ID%/databases/(default)/documents/settings/app_config" ^
  -H "Content-Type: application/json" ^
  -d "{\"fields\":{\"payment_methods\":{\"arrayValue\":{\"values\":[{\"mapValue\":{\"fields\":{\"type\":{\"stringValue\":\"bank\"},\"provider\":{\"stringValue\":\"BNI\"},\"account_number\":{\"stringValue\":\"1428471525\"},\"account_name\":{\"stringValue\":\"Adrian Alfajri\"},\"qr_code_url\":{\"nullValue\":null}}}},{\"mapValue\":{\"fields\":{\"type\":{\"stringValue\":\"bank\"},\"provider\":{\"stringValue\":\"BCA\"},\"account_number\":{\"stringValue\":\"3000968357\"},\"account_name\":{\"stringValue\":\"Adrian Alfajri\"},\"qr_code_url\":{\"nullValue\":null}}}},{\"mapValue\":{\"fields\":{\"type\":{\"stringValue\":\"ewallet\"},\"provider\":{\"stringValue\":\"OVO\"},\"account_number\":{\"stringValue\":\"081377707700\"},\"account_name\":{\"stringValue\":\"Adrian Alfajri\"},\"qr_code_url\":{\"nullValue\":null}}}},{\"mapValue\":{\"fields\":{\"type\":{\"stringValue\":\"ewallet\"},\"provider\":{\"stringValue\":\"Gopay\"},\"account_number\":{\"stringValue\":\"081377707700\"},\"account_name\":{\"stringValue\":\"Adrian Alfajri\"},\"qr_code_url\":{\"nullValue\":null}}}}]}},\"system_config\":{\"mapValue\":{\"fields\":{\"per_person_allocation\":{\"integerValue\":\"250000\"},\"deadline_offset_days\":{\"integerValue\":\"3\"},\"minimum_contribution\":{\"integerValue\":\"10000\"},\"auto_open_next_target\":{\"booleanValue\":true}}}},\"admin_config\":{\"mapValue\":{\"fields\":{\"whatsapp_number\":{\"stringValue\":\"+6281377707700\"},\"admin_email\":{\"stringValue\":\"adrianalfajri@gmail.com\"}}}},\"updated_by\":{\"stringValue\":\"seed_script\"}}}"

echo.
echo Creating general_fund document...
curl -X PATCH ^
  "https://firestore.googleapis.com/v1/projects/%PROJECT_ID%/databases/(default)/documents/general_fund/current" ^
  -H "Content-Type: application/json" ^
  -d "{\"fields\":{\"balance\":{\"integerValue\":\"0\"},\"total_income\":{\"integerValue\":\"0\"},\"total_expense\":{\"integerValue\":\"0\"},\"transaction_count\":{\"integerValue\":\"0\"}}}"

echo.
echo Done! Refresh your app.
pause
