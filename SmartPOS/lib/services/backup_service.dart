import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../utils/constants.dart';
import 'database_service.dart';
import 'settings_service.dart';

class BackupService {
  // Use driveFileScope for proper file create/read/write access
  // driveAppdataScope can fail silently on some configurations
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [drive.DriveApi.driveFileScope],
  );
  
  final SettingsService _settingsService = SettingsService();

  static const String _backupFolderName = 'SmartPOS Backups';
  static const String _backupFileName = 'SmartPOS.db';

  Future<GoogleSignInAccount?> connectGoogleDrive() async {
    try {
      // Disconnect first to force a fresh auth with the correct scopes
      await _googleSignIn.signOut();
      final account = await _googleSignIn.signIn();
      if (account != null) {
        debugPrint('Google Drive connected: ${account.email}');
      }
      return account;
    } catch (e) {
      debugPrint('Error connecting Google Drive: $e');
      return null;
    }
  }

  Future<void> disconnectGoogleDrive() async {
    try {
      await _googleSignIn.signOut();
    } catch (e) {
      debugPrint('Error disconnecting Google Drive: $e');
    }
  }

  /// Find or create the SmartPOS Backups folder in Google Drive
  Future<String?> _getOrCreateBackupFolder(drive.DriveApi driveApi) async {
    try {
      // Search for existing folder
      final query = "name = '$_backupFolderName' and mimeType = 'application/vnd.google-apps.folder' and trashed = false";
      final fileList = await driveApi.files.list(q: query);
      
      if (fileList.files != null && fileList.files!.isNotEmpty) {
        return fileList.files!.first.id;
      }
      
      // Create new folder
      final folder = drive.File()
        ..name = _backupFolderName
        ..mimeType = 'application/vnd.google-apps.folder';
      
      final createdFolder = await driveApi.files.create(folder);
      debugPrint('Created backup folder: ${createdFolder.id}');
      return createdFolder.id;
    } catch (e) {
      debugPrint('Error creating backup folder: $e');
      return null;
    }
  }

  Future<bool> backupDatabase() async {
    try {
      debugPrint('Starting backup...');
      
      final account = _googleSignIn.currentUser;
      if (account == null) {
        debugPrint('Backup failed: No Google account signed in');
        return false;
      }
      
      final authClient = await _googleSignIn.authenticatedClient();
      if (authClient == null) {
        debugPrint('Backup failed: Could not get authenticated client');
        return false;
      }

      final driveApi = drive.DriveApi(authClient);

      // Get or create backup folder
      final folderId = await _getOrCreateBackupFolder(driveApi);
      if (folderId == null) {
        debugPrint('Backup failed: Could not create backup folder');
        return false;
      }

      // Get DB file path
      final dbFolder = await getDatabasesPath();
      final dbPath = join(dbFolder, AppConstants.databaseName);
      final dbFile = File(dbPath);
      
      if (!await dbFile.exists()) {
        debugPrint('Backup failed: Database file does not exist at $dbPath');
        return false;
      }

      debugPrint('Database file size: ${dbFile.lengthSync()} bytes');

      // Check if backup already exists in our folder
      final query = "name = '$_backupFileName' and '$folderId' in parents and trashed = false";
      final fileList = await driveApi.files.list(q: query);
      
      final driveFile = drive.File()..name = _backupFileName;

      final media = drive.Media(dbFile.openRead(), dbFile.lengthSync());

      if (fileList.files != null && fileList.files!.isNotEmpty) {
        // Update existing file
        final existingFileId = fileList.files!.first.id!;
        await driveApi.files.update(driveFile, existingFileId, uploadMedia: media);
        debugPrint('Backup updated successfully (file ID: $existingFileId)');
      } else {
        // Create new file in our folder
        driveFile.parents = [folderId];
        final created = await driveApi.files.create(driveFile, uploadMedia: media);
        debugPrint('Backup created successfully (file ID: ${created.id})');
      }

      await _settingsService.setLastBackupTime(DateTime.now());
      return true;
    } catch (e, stackTrace) {
      debugPrint('Backup Error: $e');
      debugPrint('Stack trace: $stackTrace');
      return false;
    }
  }

  Future<bool> restoreDatabase() async {
    try {
      debugPrint('Starting restore...');
      
      final authClient = await _googleSignIn.authenticatedClient();
      if (authClient == null) {
        debugPrint('Restore failed: Could not get authenticated client');
        return false;
      }

      final driveApi = drive.DriveApi(authClient);

      // Find backup folder
      final folderId = await _getOrCreateBackupFolder(driveApi);
      if (folderId == null) {
        debugPrint('Restore failed: Could not find backup folder');
        return false;
      }

      final query = "name = '$_backupFileName' and '$folderId' in parents and trashed = false";
      final fileList = await driveApi.files.list(q: query);

      if (fileList.files == null || fileList.files!.isEmpty) {
        debugPrint('Restore failed: No backup file found');
        return false; // No backup found
      }

      final fileId = fileList.files!.first.id!;
      debugPrint('Found backup file: $fileId');
      
      final drive.Media file = await driveApi.files.get(
        fileId, 
        downloadOptions: drive.DownloadOptions.fullMedia,
      ) as drive.Media;

      // Close current DB handle to avoid locked file errors
      final dbService = DatabaseService();
      await dbService.closeDatabase();

      // Write to local file over the old one
      final dbFolder = await getDatabasesPath();
      final dbPath = join(dbFolder, AppConstants.databaseName);
      final localFile = File(dbPath);

      final sink = localFile.openWrite();
      await file.stream.forEach((chunk) {
        sink.add(chunk);
      });
      await sink.close();

      // Re-initialize DB
      await dbService.database;

      debugPrint('Restore completed successfully');
      return true;
    } catch (e, stackTrace) {
      debugPrint('Restore Error: $e');
      debugPrint('Stack trace: $stackTrace');
      return false;
    }
  }
}
