TWEEN ANDROID ZIP PICKER PATCH

This targeted patch fixes Android's ZIP selection issue. The native document
picker may expose ZIP archives with inconsistent MIME metadata. The importer
now allows selecting any file, then validates the .zip extension and ZIP
signature in Dart before unpacking.

Apply without replacing your entire project:
1. Make a backup of your current Tween Mini App Store folder.
2. Extract this ZIP directly into:
   C:\FlutterProjects\tween_mini_app_store\tween_mini_app_store
   Choose overwrite/replace for the listed files.
3. In PowerShell, run:

   cd C:\FlutterProjects\tween_mini_app_store\tween_mini_app_store
   flutter pub get
   cd example
   flutter pub get
   flutter clean
   flutter run -d 192.168.100.27:40999

The root pubspec is updated to file_picker ^10.3.10, removing the old plugin
whose Android build hard-coded compileSdk 34. The example app compileSdk is
set to 36. Do not replace unrelated project files.
