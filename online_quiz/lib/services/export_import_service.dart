import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/export_import_log.dart';

class ExportImportService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Create a new export/import log entry
  /// Used when starting an export/import operation
  Future<ExportImportLog> createLog({
    required int userId,
    required LogType type,
    required String fileName,
    LogStatus status = LogStatus.pending,
  }) async {
    try {
      final response = await _supabase
          .from('ExportImportLog')
          .insert({
            'UserId': userId,
            'Type': type.value,
            'FileName': fileName,
            'Status': status.value,
            'CreatedAt': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      return ExportImportLog.fromJson(response);
    } on PostgrestException catch (e) {
      throw Exception('Failed to create log: ${e.message}');
    } catch (e) {
      throw Exception('Failed to create log: ${e.toString()}');
    }
  }

  /// Update an existing log entry
  /// Used to update status, completion time, or error message
  Future<ExportImportLog> updateLog({
    required int logId,
    LogStatus? status,
    DateTime? completedAt,
    String? errorMessage,
  }) async {
    try {
      final Map<String, dynamic> updateData = {};

      if (status != null) {
        updateData['Status'] = status.value;
      }
      if (completedAt != null) {
        updateData['CompletedAt'] = completedAt.toIso8601String();
      }
      if (errorMessage != null) {
        updateData['ErrorMessage'] = errorMessage;
      }

      final response = await _supabase
          .from('ExportImportLog')
          .update(updateData)
          .eq('LogId', logId)
          .select()
          .single();

      return ExportImportLog.fromJson(response);
    } on PostgrestException catch (e) {
      throw Exception('Failed to update log: ${e.message}');
    } catch (e) {
      throw Exception('Failed to update log: ${e.toString()}');
    }
  }

  /// Log a completed export operation
  /// Convenience method that creates a log with completed status
  Future<ExportImportLog> logExportOperation({
    required int userId,
    required String fileName,
  }) async {
    try {
      final response = await _supabase
          .from('ExportImportLog')
          .insert({
            'UserId': userId,
            'Type': LogType.export.value,
            'FileName': fileName,
            'Status': LogStatus.completed.value,
            'CreatedAt': DateTime.now().toIso8601String(),
            'CompletedAt': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      return ExportImportLog.fromJson(response);
    } on PostgrestException catch (e) {
      throw Exception('Failed to log export operation: ${e.message}');
    } catch (e) {
      throw Exception('Failed to log export operation: ${e.toString()}');
    }
  }

  /// Log a failed export operation
  Future<ExportImportLog> logFailedExportOperation({
    required int userId,
    required String fileName,
    required String errorMessage,
  }) async {
    try {
      final response = await _supabase
          .from('ExportImportLog')
          .insert({
            'UserId': userId,
            'Type': LogType.export.value,
            'FileName': fileName,
            'Status': LogStatus.failed.value,
            'CreatedAt': DateTime.now().toIso8601String(),
            'CompletedAt': DateTime.now().toIso8601String(),
            'ErrorMessage': errorMessage,
          })
          .select()
          .single();

      return ExportImportLog.fromJson(response);
    } on PostgrestException catch (e) {
      throw Exception('Failed to log failed export: ${e.message}');
    } catch (e) {
      throw Exception('Failed to log failed export: ${e.toString()}');
    }
  }

  /// Log a completed import operation
  /// Convenience method that creates a log with completed status
  Future<ExportImportLog> logImportOperation({
    required int userId,
    required String fileName,
  }) async {
    try {
      final response = await _supabase
          .from('ExportImportLog')
          .insert({
            'UserId': userId,
            'Type': LogType.import.value,
            'FileName': fileName,
            'Status': LogStatus.completed.value,
            'CreatedAt': DateTime.now().toIso8601String(),
            'CompletedAt': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      return ExportImportLog.fromJson(response);
    } on PostgrestException catch (e) {
      throw Exception('Failed to log import operation: ${e.message}');
    } catch (e) {
      throw Exception('Failed to log import operation: ${e.toString()}');
    }
  }

  /// Log a failed import operation
  Future<ExportImportLog> logFailedImportOperation({
    required int userId,
    required String fileName,
    required String errorMessage,
  }) async {
    try {
      final response = await _supabase
          .from('ExportImportLog')
          .insert({
            'UserId': userId,
            'Type': LogType.import.value,
            'FileName': fileName,
            'Status': LogStatus.failed.value,
            'CreatedAt': DateTime.now().toIso8601String(),
            'CompletedAt': DateTime.now().toIso8601String(),
            'ErrorMessage': errorMessage,
          })
          .select()
          .single();

      return ExportImportLog.fromJson(response);
    } on PostgrestException catch (e) {
      throw Exception('Failed to log failed import: ${e.message}');
    } catch (e) {
      throw Exception('Failed to log failed import: ${e.toString()}');
    }
  }

  /// Get export/import history for a specific user
  /// Returns logs ordered by creation date (newest first)
  Future<List<ExportImportLog>> getExportImportHistory({
    required int userId,
    LogType? type,
    LogStatus? status,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      var query = _supabase
          .from('ExportImportLog')
          .select()
          .eq('UserId', userId);

      // Apply optional filters
      if (type != null) {
        query = query.eq('Type', type.value);
      }
      if (status != null) {
        query = query.eq('Status', status.value);
      }

      final response = await query
          .order('CreatedAt', ascending: false)
          .range(offset, offset + limit - 1);

      return (response as List)
          .map((json) => ExportImportLog.fromJson(json))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Failed to get export/import history: ${e.message}');
    } catch (e) {
      throw Exception('Failed to get export/import history: ${e.toString()}');
    }
  }

  /// Get all export logs for a user
  Future<List<ExportImportLog>> getExportHistory({
    required int userId,
    int limit = 50,
  }) async {
    return getExportImportHistory(
      userId: userId,
      type: LogType.export,
      limit: limit,
    );
  }

  /// Get all import logs for a user
  Future<List<ExportImportLog>> getImportHistory({
    required int userId,
    int limit = 50,
  }) async {
    return getExportImportHistory(
      userId: userId,
      type: LogType.import,
      limit: limit,
    );
  }

  /// Get recent export/import logs (last 10)
  Future<List<ExportImportLog>> getRecentLogs({
    required int userId,
  }) async {
    return getExportImportHistory(
      userId: userId,
      limit: 10,
    );
  }

  /// Get statistics about export/import operations for a user
  Future<Map<String, dynamic>> getExportImportStatistics({
    required int userId,
  }) async {
    try {
      // Get all logs for the user
      final logs = await getExportImportHistory(userId: userId, limit: 1000);

      // Calculate statistics
      final totalOperations = logs.length;
      final exportCount = logs.where((log) => log.type == LogType.export).length;
      final importCount = logs.where((log) => log.type == LogType.import).length;
      final completedCount = logs.where((log) => log.status == LogStatus.completed).length;
      final failedCount = logs.where((log) => log.status == LogStatus.failed).length;
      final pendingCount = logs.where((log) => log.status == LogStatus.pending).length;
      final inProgressCount = logs.where((log) => log.status == LogStatus.inProgress).length;

      // Get most recent operation
      final mostRecent = logs.isNotEmpty ? logs.first : null;

      return {
        'totalOperations': totalOperations,
        'exportCount': exportCount,
        'importCount': importCount,
        'completedCount': completedCount,
        'failedCount': failedCount,
        'pendingCount': pendingCount,
        'inProgressCount': inProgressCount,
        'successRate': totalOperations > 0 
            ? (completedCount / totalOperations * 100).toStringAsFixed(1)
            : '0.0',
        'mostRecentOperation': mostRecent != null
            ? {
                'type': mostRecent.type.value,
                'fileName': mostRecent.fileName,
                'status': mostRecent.status.value,
                'createdAt': mostRecent.createdAt.toIso8601String(),
              }
            : null,
      };
    } catch (e) {
      throw Exception('Failed to get statistics: ${e.toString()}');
    }
  }

  /// Delete a log entry (soft delete by updating status)
  Future<void> deleteLog(int logId) async {
    try {
      await _supabase
          .from('ExportImportLog')
          .delete()
          .eq('LogId', logId);
    } on PostgrestException catch (e) {
      throw Exception('Failed to delete log: ${e.message}');
    } catch (e) {
      throw Exception('Failed to delete log: ${e.toString()}');
    }
  }

  /// Delete old logs (older than specified days)
  Future<int> deleteOldLogs({
    required int userId,
    int olderThanDays = 90,
  }) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: olderThanDays));
      
      final response = await _supabase
          .from('ExportImportLog')
          .delete()
          .eq('UserId', userId)
          .lt('CreatedAt', cutoffDate.toIso8601String())
          .select();

      return (response as List).length;
    } on PostgrestException catch (e) {
      throw Exception('Failed to delete old logs: ${e.message}');
    } catch (e) {
      throw Exception('Failed to delete old logs: ${e.toString()}');
    }
  }
}
