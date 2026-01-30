// ignore_for_file: avoid_print
import 'dart:io';

void main() async {
  final pubspecFile = File('pubspec.yaml');
  if (!await pubspecFile.exists()) {
    print('Error: pubspec.yaml not found');
    exit(1);
  }

  final lines = await pubspecFile.readAsLines();
  final newLines = <String>[];
  bool versionUpdated = false;

  for (final line in lines) {
    if (line.trim().startsWith('version:') && !versionUpdated) {
      final parts = line.split(':')[1].trim().split('+');
      final versionParts = parts[0].split('.');
      
      // Bump patch
      final major = int.parse(versionParts[0]);
      final minor = int.parse(versionParts[1]);
      int patch = int.parse(versionParts[2]) + 1;
      
      // Bump build number
      int buildNumber = parts.length > 1 ? int.parse(parts[1]) + 1 : 1;

      final newVersion = '$major.$minor.$patch+$buildNumber';
      newLines.add('version: $newVersion');
      print('Bumped version to $newVersion');
      versionUpdated = true;
    } else {
      newLines.add(line);
    }
  }

  await pubspecFile.writeAsString('${newLines.join('\n')}\n');
}
