import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:share_plus/share_plus.dart';
import '../theme/colors.dart';

class FileDownloadService {
  FileDownloadService._();
  static final FileDownloadService instance = FileDownloadService._();

  /// Sanitize file name by replacing forbidden characters
  String _sanitizeFileName(String name) {
    return name.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_').trim();
  }

  /// Get the app's local document directory for storing user-facing downloads
  Future<Directory> _getStorageDirectory() async {
    try {
      final docDir = await getApplicationDocumentsDirectory();
      final downloadsDir = Directory('${docDir.path}/downloads');
      if (!await downloadsDir.exists()) {
        await downloadsDir.create(recursive: true);
      }
      return downloadsDir;
    } catch (_) {
      return await getTemporaryDirectory();
    }
  }

  /// Save UTF-8 text (e.g. CSV file) to local device storage
  Future<File> saveTextFile({
    required String fileName,
    required String content,
  }) async {
    final dir = await _getStorageDirectory();
    final cleanName = _sanitizeFileName(fileName);
    final file = File('${dir.path}/$cleanName');
    return await file.writeAsString(content);
  }

  /// Save raw bytes (e.g. PDF, Excel XLSX) to local device storage
  Future<File> saveBinaryFile({
    required String fileName,
    required List<int> bytes,
  }) async {
    final dir = await _getStorageDirectory();
    final cleanName = _sanitizeFileName(fileName);
    final file = File('${dir.path}/$cleanName');
    return await file.writeAsBytes(bytes);
  }

  /// Open the file with the default system application (e.g. Sheets, Excel, PDF viewer)
  Future<OpenResult> openFile(String filePath) async {
    return await OpenFilex.open(filePath);
  }

  /// Share the file using the native operating system share sheet (WhatsApp, Email, Files, Drive)
  Future<ShareResult> shareFile({
    required String filePath,
    String? text,
    String? subject,
  }) async {
    return await Share.shareXFiles(
      [XFile(filePath)],
      text: text,
      subject: subject,
    );
  }

  /// Present a standardized completion modal bottom sheet allowing the user to Open or Share the file
  void showDownloadCompleteSheet(
    BuildContext context, {
    required String filePath,
    required String fileName,
    required String fileTypeLabel,
  }) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (bottomSheetCtx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                const Icon(
                  Icons.check_circle_outline,
                  color: AppColors.success,
                  size: 56,
                ),
                const SizedBox(height: 12),
                Text(
                  '$fileTypeLabel Downloaded',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  fileName,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.share_outlined, size: 20),
                        label: const Text('Share / Save'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () {
                          Navigator.pop(bottomSheetCtx);
                          shareFile(
                            filePath: filePath,
                            subject: fileName,
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.open_in_new, size: 20),
                        label: const Text('Open File'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () async {
                          Navigator.pop(bottomSheetCtx);
                          final result = await openFile(filePath);
                          if (result.type != ResultType.done && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Could not open file automatically. Using share menu instead...',
                                ),
                              ),
                            );
                            await shareFile(
                              filePath: filePath,
                              subject: fileName,
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

