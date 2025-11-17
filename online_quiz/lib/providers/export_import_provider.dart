import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import '../services/export_import_service.dart';
import '../models/export_import_log.dart';

// Provider for export/import functionality
final exportImportProvider = StateNotifierProvider<ExportImportNotifier, ExportImportState>((ref) {
  return ExportImportNotifier();
});

// State class for export/import operations
class ExportImportState {
  final bool isExporting;
  final bool isImporting;
  final String? errorMessage;
  final String? successMessage;

  const ExportImportState({
    this.isExporting = false,
    this.isImporting = false,
    this.errorMessage,
    this.successMessage,
  });

  ExportImportState copyWith({
    bool? isExporting,
    bool? isImporting,
    String? errorMessage,
    String? successMessage,
  }) {
    return ExportImportState(
      isExporting: isExporting ?? this.isExporting,
      isImporting: isImporting ?? this.isImporting,
      errorMessage: errorMessage,
      successMessage: successMessage,
    );
  }
}

// Notifier class for handling export/import operations
class ExportImportNotifier extends StateNotifier<ExportImportState> {
  ExportImportNotifier() : super(const ExportImportState());

  final ExportImportService _exportImportService = ExportImportService();

  // Request storage permission
  Future<bool> _requestStoragePermission() async {
    if (Platform.isAndroid) {
      // Check Android version and request appropriate permissions
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      final sdkInt = androidInfo.version.sdkInt;
      
      if (sdkInt >= 30) {
        // Android 11+ (API 30+) - Request MANAGE_EXTERNAL_STORAGE
        final status = await Permission.manageExternalStorage.request();
        if (status.isGranted) {
          return true;
        }
        // If manage external storage is denied, try storage permission
        final storageStatus = await Permission.storage.request();
        return storageStatus.isGranted;
      } else if (sdkInt >= 23) {
        // Android 6+ (API 23+) - Request WRITE_EXTERNAL_STORAGE
        final status = await Permission.storage.request();
        return status.isGranted;
      } else {
        // Below Android 6 - permissions are granted at install time
        return true;
      }
    }
    return true; // iOS doesn't need explicit storage permission for app documents
  }

  // Get the appropriate download directory
  Future<Directory?> _getDownloadDirectory() async {
    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      final sdkInt = androidInfo.version.sdkInt;
      
      if (sdkInt >= 30) {
        // Android 11+ - Use app-specific external storage or Downloads
        try {
          // Try to use Downloads directory if we have MANAGE_EXTERNAL_STORAGE permission
          final hasManagePermission = await Permission.manageExternalStorage.isGranted;
          if (hasManagePermission) {
            Directory? directory = Directory('/storage/emulated/0/Download');
            if (await directory.exists()) {
              return directory;
            }
          }
        } catch (e) {
          // Ignore and fall back
        }
        
        // Fallback to app-specific external storage
        final externalDir = await getExternalStorageDirectory();
        if (externalDir != null) {
          // Create a Downloads subfolder in app-specific storage
          final downloadDir = Directory('${externalDir.path}/Downloads');
          if (!await downloadDir.exists()) {
            await downloadDir.create(recursive: true);
          }
          return downloadDir;
        }
      } else {
        // Android 10 and below - Use Downloads directory
        Directory? directory = Directory('/storage/emulated/0/Download');
        if (await directory.exists()) {
          return directory;
        }
        // Fallback to external storage directory
        return await getExternalStorageDirectory();
      }
    } else if (Platform.isIOS) {
      return await getApplicationDocumentsDirectory();
    } else {
      return await getDownloadsDirectory();
    }
    
    return null;
  }

  // Export student quiz results to Excel
  Future<String?> exportStudentResultsToExcel({
    required List<Map<String, dynamic>> results,
    required String quizTitle,
    required String courseName,
    required int userId,
  }) async {
    String fileName = 'quiz_results_${DateTime.now().millisecondsSinceEpoch}.xlsx';
    
    try {
      state = state.copyWith(isExporting: true, errorMessage: null, successMessage: null);

      // Create a new Excel document
      final Workbook workbook = Workbook();
      final Worksheet worksheet = workbook.worksheets[0];

      // Set worksheet name
      worksheet.name = 'Quiz Results';

      // Add title and course information
      worksheet.getRangeByName('A1').setText('Quiz Results Report');
      worksheet.getRangeByName('A1').cellStyle.fontSize = 16;
      worksheet.getRangeByName('A1').cellStyle.bold = true;
      
      worksheet.getRangeByName('A2').setText('Quiz: $quizTitle');
      worksheet.getRangeByName('A2').cellStyle.fontSize = 12;
      worksheet.getRangeByName('A2').cellStyle.bold = true;
      
      worksheet.getRangeByName('A3').setText('Course: $courseName');
      worksheet.getRangeByName('A3').cellStyle.fontSize = 12;
      worksheet.getRangeByName('A3').cellStyle.bold = true;
      
      worksheet.getRangeByName('A4').setText('Generated on: ${DateTime.now().toString().split('.')[0]}');
      worksheet.getRangeByName('A4').cellStyle.fontSize = 10;

      // Add headers starting from row 6
      const int headerRow = 6;
      final List<String> headers = ['Student Name', 'Student ID', 'Section', 'Score', 'Total Points', 'Percentage', 'Status'];
      
      for (int i = 0; i < headers.length; i++) {
        final Range headerCell = worksheet.getRangeByIndex(headerRow, i + 1);
        headerCell.setText(headers[i]);
        headerCell.cellStyle.bold = true;
        headerCell.cellStyle.backColor = '#4CAF50';
        headerCell.cellStyle.fontColor = '#FFFFFF';
        headerCell.cellStyle.hAlign = HAlignType.center;
      }

      // Add student data
      for (int i = 0; i < results.length; i++) {
        final result = results[i];
        final int dataRow = headerRow + 1 + i;
        
        // Calculate percentage and status
        final double totalPoints = result['totalPoints'] ?? 0.0;
        final double score = result['score'] ?? 0.0;
        final double percentage = totalPoints > 0 ? (score / totalPoints) * 100 : 0.0;
        final String status = percentage >= 75 ? 'Passed' : 'Failed';
        
        worksheet.getRangeByIndex(dataRow, 1).setText(result['studentName'] ?? '');
        worksheet.getRangeByIndex(dataRow, 2).setText(result['studentId'] ?? '');
        worksheet.getRangeByIndex(dataRow, 3).setText(result['section'] ?? 'N/A');
        worksheet.getRangeByIndex(dataRow, 4).setNumber(score);
        worksheet.getRangeByIndex(dataRow, 5).setNumber(totalPoints);
        worksheet.getRangeByIndex(dataRow, 6).setText('${percentage.toStringAsFixed(1)}%');
        worksheet.getRangeByIndex(dataRow, 7).setText(status);
        
        // Color code the status
        final Range statusCell = worksheet.getRangeByIndex(dataRow, 7);
        if (status == 'Passed') {
          statusCell.cellStyle.backColor = '#E8F5E8';
          statusCell.cellStyle.fontColor = '#2E7D32';
        } else {
          statusCell.cellStyle.backColor = '#FFEBEE';
          statusCell.cellStyle.fontColor = '#C62828';
        }
      }

      // Auto-fit columns
      for (int i = 1; i <= headers.length; i++) {
        worksheet.autoFitColumn(i);
      }

      // Add borders to the data range
      final Range dataRange = worksheet.getRangeByName('A$headerRow:G${headerRow + results.length}');
      dataRange.cellStyle.borders.all.lineStyle = LineStyle.thin;

      // Save the file
      final List<int> bytes = workbook.saveAsStream();
      workbook.dispose();

      // Request storage permission
      final hasPermission = await _requestStoragePermission();
      if (!hasPermission) {
        throw Exception('Storage permission denied');
      }

      // Get the downloads directory
      final directory = await _getDownloadDirectory();

      if (directory != null) {
        fileName = 'quiz_results_${DateTime.now().millisecondsSinceEpoch}.xlsx';
        final String filePath = '${directory.path}/$fileName';
        final File file = File(filePath);
        await file.writeAsBytes(bytes);

        // Log successful export to Supabase
        try {
          await _exportImportService.logExportOperation(
            userId: userId,
            fileName: fileName,
          );
        } catch (logError) {
          // Don't fail the export if logging fails, just print error
          debugPrint('Failed to log export operation: $logError');
        }

        // Create user-friendly success message
        String locationMessage;
        if (Platform.isAndroid) {
          final androidInfo = await DeviceInfoPlugin().androidInfo;
          final sdkInt = androidInfo.version.sdkInt;
          final hasManagePermission = await Permission.manageExternalStorage.isGranted;
          
          if (sdkInt >= 30 && !hasManagePermission) {
            locationMessage = 'App Downloads folder';
          } else {
            locationMessage = 'Downloads folder';
          }
        } else if (Platform.isIOS) {
          locationMessage = 'Documents folder';
        } else {
          locationMessage = 'Downloads folder';
        }
        
        state = state.copyWith(
          isExporting: false,
          successMessage: 'Excel file exported successfully!\nSaved to: $locationMessage\nFile: $fileName',
        );

        return filePath;
      } else {
        throw Exception('Could not access storage directory');
      }
    } catch (e) {
      // Log failed export to Supabase
      try {
        await _exportImportService.logFailedExportOperation(
          userId: userId,
          fileName: fileName,
          errorMessage: e.toString(),
        );
      } catch (logError) {
        // Don't fail the export if logging fails, just print error
        debugPrint('Failed to log failed export: $logError');
      }
      
      state = state.copyWith(
        isExporting: false,
        errorMessage: 'Failed to export Excel file: ${e.toString()}',
      );
      return null;
    }
  }

  // Export simplified student scores (Name, Section, Score only)
  Future<String?> exportSimplifiedResultsToExcel({
    required List<Map<String, dynamic>> results,
    required String quizTitle,
    required String courseName,
    required int userId,
  }) async {
    String fileName = 'quiz_scores_${DateTime.now().millisecondsSinceEpoch}.xlsx';
    
    try {
      state = state.copyWith(isExporting: true, errorMessage: null, successMessage: null);

      // Filter only results with attempts (scores)
      final scoresOnly = results.where((r) => r['hasAttempt'] == true).toList();

      // Create a new Excel document
      final Workbook workbook = Workbook();
      final Worksheet worksheet = workbook.worksheets[0];

      // Set worksheet name
      worksheet.name = 'Quiz Scores';

      // Add title and course information
      worksheet.getRangeByName('A1').setText('Quiz Scores Report');
      worksheet.getRangeByName('A1').cellStyle.fontSize = 16;
      worksheet.getRangeByName('A1').cellStyle.bold = true;
      
      worksheet.getRangeByName('A2').setText('Quiz: $quizTitle');
      worksheet.getRangeByName('A2').cellStyle.fontSize = 12;
      worksheet.getRangeByName('A2').cellStyle.bold = true;
      
      worksheet.getRangeByName('A3').setText('Course: $courseName');
      worksheet.getRangeByName('A3').cellStyle.fontSize = 12;
      worksheet.getRangeByName('A3').cellStyle.bold = true;
      
      worksheet.getRangeByName('A4').setText('Generated on: ${DateTime.now().toString().split('.')[0]}');
      worksheet.getRangeByName('A4').cellStyle.fontSize = 10;

      // Add headers starting from row 6
      const int headerRow = 6;
      final List<String> headers = ['Student Name', 'Section', 'Score'];
      
      for (int i = 0; i < headers.length; i++) {
        final Range headerCell = worksheet.getRangeByIndex(headerRow, i + 1);
        headerCell.setText(headers[i]);
        headerCell.cellStyle.bold = true;
        headerCell.cellStyle.backColor = '#2196F3';
        headerCell.cellStyle.fontColor = '#FFFFFF';
        headerCell.cellStyle.hAlign = HAlignType.center;
      }

      // Add student data
      for (int i = 0; i < scoresOnly.length; i++) {
        final result = scoresOnly[i];
        final int dataRow = headerRow + 1 + i;
        
        worksheet.getRangeByIndex(dataRow, 1).setText(result['studentName'] ?? '');
        worksheet.getRangeByIndex(dataRow, 2).setText(result['section'] ?? 'N/A');
        worksheet.getRangeByIndex(dataRow, 3).setNumber(result['score'] ?? 0.0);
      }

      // Auto-fit columns
      for (int i = 1; i <= headers.length; i++) {
        worksheet.autoFitColumn(i);
      }

      // Add borders to the data range
      final Range dataRange = worksheet.getRangeByName('A$headerRow:C${headerRow + scoresOnly.length}');
      dataRange.cellStyle.borders.all.lineStyle = LineStyle.thin;

      // Save the file
      final List<int> bytes = workbook.saveAsStream();
      workbook.dispose();

      // Request storage permission
      final hasPermission = await _requestStoragePermission();
      if (!hasPermission) {
        throw Exception('Storage permission denied');
      }

      // Get the downloads directory
      final directory = await _getDownloadDirectory();

      if (directory != null) {
        fileName = 'quiz_scores_${DateTime.now().millisecondsSinceEpoch}.xlsx';
        final String filePath = '${directory.path}/$fileName';
        final File file = File(filePath);
        await file.writeAsBytes(bytes);

        // Log successful export to Supabase
        try {
          await _exportImportService.logExportOperation(
            userId: userId,
            fileName: fileName,
          );
        } catch (logError) {
          // Don't fail the export if logging fails, just print error
          debugPrint('Failed to log export operation: $logError');
        }

        // Create user-friendly success message
        String locationMessage;
        if (Platform.isAndroid) {
          final androidInfo = await DeviceInfoPlugin().androidInfo;
          final sdkInt = androidInfo.version.sdkInt;
          final hasManagePermission = await Permission.manageExternalStorage.isGranted;
          
          if (sdkInt >= 30 && !hasManagePermission) {
            locationMessage = 'App Downloads folder';
          } else {
            locationMessage = 'Downloads folder';
          }
        } else if (Platform.isIOS) {
          locationMessage = 'Documents folder';
        } else {
          locationMessage = 'Downloads folder';
        }
        
        state = state.copyWith(
          isExporting: false,
          successMessage: 'Excel file exported successfully!\nSaved to: $locationMessage\nFile: $fileName',
        );

        return filePath;
      } else {
        throw Exception('Could not access storage directory');
      }
    } catch (e) {
      // Log failed export to Supabase
      try {
        await _exportImportService.logFailedExportOperation(
          userId: userId,
          fileName: fileName,
          errorMessage: e.toString(),
        );
      } catch (logError) {
        // Don't fail the export if logging fails, just print error
        debugPrint('Failed to log failed export: $logError');
      }
      
      state = state.copyWith(
        isExporting: false,
        errorMessage: 'Failed to export Excel file: ${e.toString()}',
      );
      return null;
    }
  }

  // Clear messages
  void clearMessages() {
    state = state.copyWith(errorMessage: null, successMessage: null);
  }

  // Get export/import history for a user
  Future<List<ExportImportLog>> getExportImportHistory({
    required int userId,
    LogType? type,
    LogStatus? status,
    int limit = 50,
  }) async {
    try {
      return await _exportImportService.getExportImportHistory(
        userId: userId,
        type: type,
        status: status,
        limit: limit,
      );
    } catch (e) {
      throw Exception('Failed to get export/import history: ${e.toString()}');
    }
  }

  // Get export history for a user
  Future<List<ExportImportLog>> getExportHistory({
    required int userId,
    int limit = 50,
  }) async {
    try {
      return await _exportImportService.getExportHistory(
        userId: userId,
        limit: limit,
      );
    } catch (e) {
      throw Exception('Failed to get export history: ${e.toString()}');
    }
  }

  // Get import history for a user
  Future<List<ExportImportLog>> getImportHistory({
    required int userId,
    int limit = 50,
  }) async {
    try {
      return await _exportImportService.getImportHistory(
        userId: userId,
        limit: limit,
      );
    } catch (e) {
      throw Exception('Failed to get import history: ${e.toString()}');
    }
  }

  // Get recent export/import logs
  Future<List<ExportImportLog>> getRecentLogs({
    required int userId,
  }) async {
    try {
      return await _exportImportService.getRecentLogs(userId: userId);
    } catch (e) {
      throw Exception('Failed to get recent logs: ${e.toString()}');
    }
  }

  // Get export/import statistics
  Future<Map<String, dynamic>> getExportImportStatistics({
    required int userId,
  }) async {
    try {
      return await _exportImportService.getExportImportStatistics(userId: userId);
    } catch (e) {
      throw Exception('Failed to get statistics: ${e.toString()}');
    }
  }

  // Delete a log entry
  Future<void> deleteLog(int logId) async {
    try {
      await _exportImportService.deleteLog(logId);
    } catch (e) {
      throw Exception('Failed to delete log: ${e.toString()}');
    }
  }

  // Delete old logs
  Future<int> deleteOldLogs({
    required int userId,
    int olderThanDays = 90,
  }) async {
    try {
      return await _exportImportService.deleteOldLogs(
        userId: userId,
        olderThanDays: olderThanDays,
      );
    } catch (e) {
      throw Exception('Failed to delete old logs: ${e.toString()}');
    }
  }
}

// StudentQuizResult class is defined in quiz_student_results_screen.dart
// It contains: Student student, User user, Enrollment enrollment, Attempt? attempt, Quiz quiz
// with methods: getPercentage() and getTotalPoints()