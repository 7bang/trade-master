import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:ui' as ui;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// 공유 서비스
///
/// 위젯을 이미지로 캡처하고 공유하는 기능을 제공합니다.
class ShareService {
  // 싱글톤 패턴
  static final ShareService _instance = ShareService._internal();
  factory ShareService() => _instance;
  ShareService._internal();

  /// 위젯을 이미지로 캡처하여 공유
  ///
  /// [widgetKey] - 캡처할 위젯의 GlobalKey
  /// [fileName] - 저장할 파일명
  /// [text] - 공유 시 함께 전달할 텍스트 (선택사항)
  Future<bool> shareWidget({
    required GlobalKey widgetKey,
    required String fileName,
    String? text,
  }) async {
    try {
      // 위젯 캡처
      final imageBytes = await _captureWidget(widgetKey);
      if (imageBytes == null) {
        return false;
      }

      // 임시 파일로 저장
      final file = await _saveToTempFile(imageBytes, fileName);

      // 공유
      await Share.shareXFiles(
        [XFile(file.path)],
        text: text,
      );

      // 공유 후 임시 파일 삭제 (약간의 지연 후)
      Future.delayed(const Duration(seconds: 5), () {
        if (file.existsSync()) {
          file.deleteSync();
        }
      });

      return true;
    } catch (e) {
      debugPrint('ShareService.shareWidget error: $e');
      return false;
    }
  }

  /// 위젯을 이미지로 캡처
  Future<Uint8List?> _captureWidget(GlobalKey widgetKey) async {
    try {
      // RenderRepaintBoundary 가져오기
      final RenderRepaintBoundary boundary =
          widgetKey.currentContext!.findRenderObject() as RenderRepaintBoundary;

      // 이미지로 변환 (고해상도)
      final ui.Image image = await boundary.toImage(
        pixelRatio: 3.0, // 고해상도
      );

      // PNG 바이트로 변환
      final ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);

      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint('ShareService._captureWidget error: $e');
      return null;
    }
  }

  /// 임시 파일로 저장
  Future<File> _saveToTempFile(Uint8List bytes, String fileName) async {
    // 임시 디렉토리 가져오기
    final tempDir = await getTemporaryDirectory();

    // 파일 경로 생성
    final file = File('${tempDir.path}/$fileName.png');

    // 파일 쓰기
    await file.writeAsBytes(bytes);

    return file;
  }

  /// 여러 위젯을 캡처하여 한 번에 공유 (추후 확장 가능)
  Future<bool> shareMultipleWidgets({
    required List<GlobalKey> widgetKeys,
    required List<String> fileNames,
    String? text,
  }) async {
    try {
      if (widgetKeys.length != fileNames.length) {
        throw Exception('widgetKeys and fileNames must have the same length');
      }

      final List<XFile> files = [];

      for (int i = 0; i < widgetKeys.length; i++) {
        final imageBytes = await _captureWidget(widgetKeys[i]);
        if (imageBytes != null) {
          final file = await _saveToTempFile(imageBytes, fileNames[i]);
          files.add(XFile(file.path));
        }
      }

      if (files.isEmpty) {
        return false;
      }

      await Share.shareXFiles(files, text: text);

      // 공유 후 임시 파일 삭제
      Future.delayed(const Duration(seconds: 5), () {
        for (final xFile in files) {
          final file = File(xFile.path);
          if (file.existsSync()) {
            file.deleteSync();
          }
        }
      });

      return true;
    } catch (e) {
      debugPrint('ShareService.shareMultipleWidgets error: $e');
      return false;
    }
  }
}
