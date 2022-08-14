import 'package:flutter/material.dart';

class BottomNav extends StatelessWidget {
  final int currentIndex;
  final void Function(int) onTap;
  const BottomNav({Key? key, required this.currentIndex, required this.onTap})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: onTap,
        items: [
          BottomNavigationBarItem(
              icon: GestureDetector(
                  child: const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Icon(Icons.folder_copy),
                  ),
                  onTap: () => Navigator.popUntil(context, (route) {
                        if (route.settings.name == null) {
                          return false;
                        } else {
                          return true;
                        }
                      })),
              label: "Files"),
          const BottomNavigationBarItem(
              icon: Icon(Icons.cloud_upload), label: "uploads"),
        ]);
  }
}
