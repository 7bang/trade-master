import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
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

      // 웹: 임시 폴더가 없으므로 메모리 데이터로 공유
      // (브라우저가 파일 공유를 지원하지 않으면 share_plus가 다운로드로 대체)
      if (kIsWeb) {
        await Share.shareXFiles([_webXFile(imageBytes, fileName)], text: text);
        return true;
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

  XFile _webXFile(Uint8List bytes, String fileName) => XFile.fromData(
        bytes,
        name: '$fileName.png',
        mimeType: 'image/png',
      );

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
}
