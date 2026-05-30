@echo off
cd d %~dp0
flutter run -d web-server --web-port 5000
pause