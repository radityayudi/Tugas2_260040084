import 'package:flutter/material.dart';
import 'main_menu.dart';
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
static String currentUserEmail = "admin@buku.com"; //menyimpan sementara 
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // 1. Kunci untuk mengenali form dan menjalankan validasi
  final _formKey = GlobalKey<FormState>();

  // 2. Controller untuk mengambil teks yang diketik pengguna
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // Akun demo untuk dites sesuai ketentuan tugas
  static const String _demoEmail = "aaa@buku.com";//menyimpan tetap
  static const String _demoPassword = "12345";

  @override
  void dispose() {
    // Bersihkan controller saat halaman ditutup agar tidak membebani memori
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _prosesLogin() {
    // Jalankan validasi semua field di dalam form
    if (_formKey.currentState!.validate()) {
      // Cek apakah email & password sesuai akun demo
      if (_emailController.text == _demoEmail &&
          _passwordController.text == _demoPassword) {
        
        LoginPage.currentUserEmail = _emailController.text;
        // Jika benar, tampilkan pesan sukses (nanti kita arahkan ke Menu Utama)
        if (_emailController.text == _demoEmail &&
          _passwordController.text == _demoPassword) {
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Login Berhasil! Selamat datang di Katalog Buku.'),
            backgroundColor: Colors.green,
          ),
        );
        
        
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainMenu()),
        );

      }
      } else {
        // Jika salah, tampilkan pesan error
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Email atau Password salah! (Coba: $_demoEmail / 12345)'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login - Katalog Buku'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          // SingleChildScrollView agar tidak error/overflow saat keyboard HP muncul
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Icon atau Judul Aplikasi
                  const Icon(Icons.book_sharp, size: 80, color: Colors.blue),
                  const SizedBox(height: 16),
                  const Text(
                    'Selamat Datang!',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const Text(
                    'Silakan login untuk mengelola katalog buku',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 32),

                  // Input Email dengan Validasi
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      hintText: 'contoh@email.com',
                      prefixIcon: Icon(Icons.email),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Email tidak boleh kosong!';
                      }
                      // Pengecekan format email sederhana menggunakan simbol '@' dan '.'
                      if (!value.contains('@') || !value.contains('.')) {
                        return 'Format email tidak valid (harus ada @ dan .)';
                      }
                      return null; // Null berarti validasi lolos
                    },
                  ),
                  const SizedBox(height: 16),

                  // Input Password dengan Validasi
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true, // Menyembunyikan teks sandi (titik-titik)
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      hintText: 'Masukkan password',
                      prefixIcon: Icon(Icons.lock),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Password tidak boleh kosong!';
                      }
                      if (value.length < 5) {
                        return 'Password minimal 5 karakter!';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // Tombol Login
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _prosesLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text(
                        'MASUK',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  // Info Akun Demo untuk memudahkan pengujian
                  const Text(
                    'Info Akun Demo:\nEmail: $_demoEmail | Password: 12345',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}