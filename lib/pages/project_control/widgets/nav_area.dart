import 'package:opencloud/utils/importer.dart';

class NavArea extends StatefulWidget {
  const NavArea({Key? key}) : super(key: key);

  @override
  State<NavArea> createState() => _NavAreaState();
}

class _NavAreaState extends State<NavArea> {
  int _currentIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  final List<Widget> _children = [
    const ListOfProjects(),
    const Uploads(),
  ];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _children,
      ),
      bottomNavigationBar:
          BottomNav(currentIndex: _currentIndex, onTap: _onItemTapped),
    );
  }
}
