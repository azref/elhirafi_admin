1) افتح PowerShell
   اضغط Win + X ثم اختر Terminal (أو PowerShell).

2) انسخ الأمر التالي كاملًا والصقه ثم Enter
   powershell


cd $HOME\Downloads
$f = Get-ChildItem *firebase-adminsdk*.json | Sort-Object LastWriteTime -Descending | Select-Object -First 1
[Convert]::ToBase64String([IO.File]::ReadAllBytes($f.FullName)) | Set-Clipboard
لن يظهر شيء — النص الطويل انتقل إلى الحافظة تلقائيًا.

3) ابنِ اللوحة
   powershell


cd D:\MyProject\elhirafi_admin
$fcm = Get-Clipboard
flutter build web --release --dart-define=FCM_JSON_BASE64="$fcm"
4) انشر
   powershell


firebase deploy --only hosting