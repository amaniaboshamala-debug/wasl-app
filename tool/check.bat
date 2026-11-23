@echo off
chcp 65001 >nul
REM وَصْل: فحص كامل قبل أي رفع أو تسليم
REM التشغيل: من مجلد المشروع اكتبي  tool\check.bat
cd /d "%~dp0\.."

echo.
echo === 1/3 تحميل الحزم ===
call flutter pub get || goto :fail

echo.
echo === 2/3 فحص الكود (analyze) ===
call flutter analyze || goto :fail

echo.
echo === 3/3 التستات ===
call flutter test || goto :fail

echo.
echo ✅ كل شي تمام
exit /b 0

:fail
echo.
echo ❌ في مشكلة، شوفي الرسالة اللي فوق وابعتيها لـ Claude
exit /b 1
