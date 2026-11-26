import 'package:flutter/material.dart';
import 'book_viewmodel.dart';
import 'login_page.dart';
import 'data_buku_page.dart';

class MainMenu extends StatefulWidget {
  const MainMenu({super.key});

  @override
  State<MainMenu> createState() => _MainMenuState();
}

class _MainMenuState extends State<MainMenu> {
  // Indeks halaman yang sedang aktif (0 = Data Buku, 1 = Profil)
  int _currentIndex = 0;

  // Simpan BookViewModel di MainMenu agar state tetap terjaga saat pindah tab
  final BookViewModel _bookViewModel = BookViewModel();
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      DataBukuPage(viewModel: _bookViewModel),
      const ProfilPage(),
    ];
  }

  @override
  void dispose() {
    _bookViewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (int index) {
          setState(() {
            _currentIndex = index; // Mengubah halaman saat menu diklik
          });
        },
        indicatorColor: const Color.fromARGB(255, 159, 203, 239),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.book),
            label: 'Data Buku',
          ),
          NavigationDestination(
            icon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}

// Fungsi untuk memunculkan kotak dialog konfirmasi logout
void _showLogoutConfirmation(BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Konfirmasi Keluar'),
        content: const Text('Apakah Anda yakin ingin keluar dari akun ini?'),
        actions: [
          // Tombol Batal
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Menutup dialog
            },
            style: TextButton.styleFrom(foregroundColor: Colors.blue),
            child: const Text('Batal'),
          ),
          // Tombol Ya / Keluar
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginPage()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red, // Warna merah untuk aksi keluar
              foregroundColor: Colors.white,
            ),
            child: const Text('Keluar'),
          ),
        ],
      );
    },
  );
}

// Halaman 2: Profil Pengguna
class ProfilPage extends StatelessWidget {
  const ProfilPage({super.key});

  @override
  Widget build(BuildContext context) {
    final String userEmail = LoginPage.currentUserEmail;
    return Scaffold(
      appBar: AppBar(title: const Text('Profil Pengguna')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircleAvatar(
              radius: 50,
              backgroundColor: Colors.blue,
              child: Icon(Icons.person, size: 50, color: Colors.white),
            ),
            const SizedBox(height: 16),
            const Text(
              'Admin Katalog',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Text(
              userEmail,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                _showLogoutConfirmation(context);
              },
              icon: const Icon(Icons.logout),
              label: const Text('Logout'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}