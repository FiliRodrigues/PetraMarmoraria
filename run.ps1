$url  = "https://prxkfifwuygtlynozdqx.supabase.co"
$key  = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InByeGtmaWZ3dXlndGx5bm96ZHF4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzk4MzU0OTcsImV4cCI6MjA5NTQxMTQ5N30.eOjvkz6-ZR_dNMqRko-tnYrxKHbf-9dEf9guM2eOwrg"

Set-Location "$PSScriptRoot\petra_erp"
flutter run -d chrome "--dart-define=SUPABASE_URL=$url" "--dart-define=SUPABASE_ANON_KEY=$key"
