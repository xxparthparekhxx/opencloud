import 'package:flutter/material.dart';

class FileTypeIcon extends StatelessWidget {
  final String extension;
  const FileTypeIcon({Key? key, required this.extension}) : super(key: key);

  IconData getIconByExtension(String extension) {
    switch (extension.toLowerCase()) {
      case "mp4":
      case "mov":
      case "avi":
      case "mkv":
      case "avchd":
      case "flv":
      case "wmv":
      case "webm":
      case "m4v":
        return Icons.movie;

      case "mp3":
      case "wav":
      case "wma":
      case "aac":
      case "flac":
      case "ogg":
      case "m4a":
        return Icons.music_note;

      case "jpg":
      case "jpeg":
      case "png":
      case "gif":
      case "bmp":
      case "tiff":
      case "webp":
      case "psd":
      case "raw":
      case "heif":
      case "indd":
      case "svg":
      case "ai":
      case "eps":
      case "pdf":
        return Icons.image;

      case "doc":
      case "docx":
      case "odt":
      case "rtf":
      case "tex":
      case "txt":
      case "wpd":
      case "wps":
        return Icons.description;

      case "ppt":
      case "pptx":
      case "pps":
      case "ppsx":
      case "odp":
        return Icons.slideshow;

      case "xls":
      case "xlsx":
      case "ods":
      case "csv":
        return Icons.table_chart;

      case "html":
      case "htm":
      case "php":
      case "css":
      case "js":
      case "jsx":
      case "ts":
      case "tsx":
      case "json":
      case "c":
      case "cpp":
      case "class":
      case "cs":
      case "h":
      case "java":
      case "sh":
      case "swift":
      case "vb":
      case "xml":
        return Icons.code;

      case "zip":
      case "7z":
      case "rar":
      case "tar":
      case "gz":
      case "arj":
      case "pkg":
      case "rpm":
      case "z":
      case "deb":
      case "dmg":
      case "iso":
      case "jar":
      case "xpi":
      case "apk":
        return Icons.archive;

      default:
        return Icons.insert_drive_file;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Icon(getIconByExtension(extension));
  }
}
