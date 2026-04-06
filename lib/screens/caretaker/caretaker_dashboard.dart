import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../models/user_model.dart';

class CaretakerDashboard extends StatefulWidget {
  const CaretakerDashboard({super.key});

  @override
  State<CaretakerDashboard> createState() => _CaretakerDashboardState();
}

class _CaretakerDashboardState extends State<CaretakerDashboard>
    with TickerProviderStateMixin {
  List<AppUser> blindUsers = [];
  bool isLoading = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _loadBlindUsers();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadBlindUsers() async {
    setState(() => isLoading = true);
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      try {
        final users = await FirestoreService().getBlindUsersForCaretaker(currentUser.uid);
        print('Loaded ${users.length} blind users'); // Debug
        setState(() {
          blindUsers = users;
          isLoading = false;
        });
        _animationController.forward();
      } catch (e) {
        print('Error loading blind users: $e'); // Debug
        setState(() => isLoading = false);
      }
    }
  }

  void _showRegisterBlindPersonDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.blue.shade50, Colors.white],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.person_add,
                  size: 48,
                  color: Colors.blue,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Register Blind Person',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(height: 24),
                _buildTextField(nameCtrl, 'Full Name', Icons.person),
                const SizedBox(height: 16),
                _buildTextField(emailCtrl, 'Email', Icons.email),
                const SizedBox(height: 16),
                _buildTextField(passCtrl, 'Password', Icons.lock, obscure: true),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('Cancel', style: TextStyle(fontSize: 16)),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : ElevatedButton(
                              onPressed: () => _registerBlindPerson(context, setState, nameCtrl, emailCtrl, passCtrl),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text('Register', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {bool obscure = false}) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.blue),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.blue.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.blue, width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }

  Future<void> _registerBlindPerson(
    BuildContext context,
    StateSetter setState,
    TextEditingController nameCtrl,
    TextEditingController emailCtrl,
    TextEditingController passCtrl,
  ) async {
    if (nameCtrl.text.trim().isEmpty ||
        emailCtrl.text.trim().isEmpty ||
        passCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    setState(() => isLoading = true);
    try {
      final currentUser = FirebaseAuth.instance.currentUser!;
      await FirestoreService().registerBlindPerson(
        nameCtrl.text.trim(),
        emailCtrl.text.trim(),
        passCtrl.text.trim(),
        currentUser.uid,
      );
      
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Blind person registered successfully'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      _loadBlindUsers();
    } on FirebaseAuthException catch (e) {
      String message = 'Registration failed';
      if (e.code == 'email-already-in-use') {
        message = 'Email already registered';
      } else if (e.code == 'weak-password') {
        message = 'Password is too weak';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade400, Colors.blue.shade50],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Custom App Bar
              Container(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 25,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.medical_services, color: Colors.blue, size: 30),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Caretaker Dashboard',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Manage blind persons',
                            style: TextStyle(color: Colors.white70, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.logout, color: Colors.white, size: 28),
                      onPressed: () => AuthService().logout(),
                    ),
                  ],
                ),
              ),
              // Main Content
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: isLoading
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(color: Colors.blue),
                              SizedBox(height: 16),
                              Text('Loading blind persons...', style: TextStyle(color: Colors.grey)),
                            ],
                          ),
                        )
                      : FadeTransition(
                          opacity: _fadeAnimation,
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Register Button
                                Container(
                                  width: double.infinity,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [Colors.orange.shade400, Colors.orange.shade600],
                                    ),
                                    borderRadius: BorderRadius.circular(15),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.orange.withOpacity(0.3),
                                        blurRadius: 10,
                                        offset: const Offset(0, 5),
                                      ),
                                    ],
                                  ),
                                  child: ElevatedButton(
                                    onPressed: () => _showRegisterBlindPersonDialog(context),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      shadowColor: Colors.transparent,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                    ),
                                    child: const Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.person_add, color: Colors.white, size: 24),
                                        SizedBox(width: 12),
                                        Text(
                                          'Register New Blind Person',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 32),
                                // Patients Section
                                Row(
                                  children: [
                                    const Icon(Icons.people, color: Colors.blue, size: 28),
                                    const SizedBox(width: 12),
                                    Text(
                                      'Your Blind Persons (${blindUsers.length})',
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                // Patients List
                                Expanded(
                                  child: blindUsers.isEmpty
                                      ? Center(
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.people_outline,
                                                size: 80,
                                                color: Colors.grey.shade300,
                                              ),
                                              const SizedBox(height: 16),
                                              Text(
                                                'No blind persons registered yet',
                                                style: TextStyle(
                                                  fontSize: 18,
                                                  color: Colors.grey.shade500,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                'Tap the button above to register your first blind person',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.grey.shade400,
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                            ],
                                          ),
                                        )
                                      : ListView.builder(
                                          itemCount: blindUsers.length,
                                          itemBuilder: (context, index) {
                                            final user = blindUsers[index];
                                            return TweenAnimationBuilder(
                                              duration: Duration(milliseconds: 300 + (index * 100)),
                                              tween: Tween<double>(begin: 0, end: 1),
                                              builder: (context, double value, child) {
                                                return Transform.translate(
                                                  offset: Offset(0, 50 * (1 - value)),
                                                  child: Opacity(
                                                    opacity: value,
                                                    child: Container(
                                                      margin: const EdgeInsets.only(bottom: 16),
                                                      decoration: BoxDecoration(
                                                        color: Colors.white,
                                                        borderRadius: BorderRadius.circular(16),
                                                        boxShadow: [
                                                          BoxShadow(
                                                            color: Colors.grey.withOpacity(0.1),
                                                            blurRadius: 10,
                                                            offset: const Offset(0, 5),
                                                          ),
                                                        ],
                                                        border: Border.all(
                                                          color: Colors.grey.shade100,
                                                          width: 1,
                                                        ),
                                                      ),
                                                      child: ListTile(
                                                        contentPadding: const EdgeInsets.all(16),
                                                        leading: Hero(
                                                          tag: 'avatar_${user.uid}',
                                                          child: Container(
                                                            width: 50,
                                                            height: 50,
                                                            decoration: BoxDecoration(
                                                              gradient: LinearGradient(
                                                                colors: [Colors.green.shade400, Colors.green.shade600],
                                                              ),
                                                              borderRadius: BorderRadius.circular(25),
                                                            ),
                                                            child: const Icon(
                                                              Icons.person,
                                                              color: Colors.white,
                                                              size: 24,
                                                            ),
                                                          ),
                                                        ),
                                                        title: Text(
                                                          user.name.isNotEmpty ? user.name : 'Unknown User',
                                                          style: const TextStyle(
                                                            fontWeight: FontWeight.bold,
                                                            fontSize: 16,
                                                            color: Colors.black87,
                                                          ),
                                                        ),
                                                        subtitle: Column(
                                                          crossAxisAlignment: CrossAxisAlignment.start,
                                                          children: [
                                                            const SizedBox(height: 4),
                                                            Text(
                                                              user.email,
                                                              style: TextStyle(
                                                                color: Colors.grey.shade600,
                                                                fontSize: 14,
                                                              ),
                                                            ),
                                                            const SizedBox(height: 4),
                                                            Container(
                                                              padding: const EdgeInsets.symmetric(
                                                                horizontal: 8,
                                                                vertical: 2,
                                                              ),
                                                              decoration: BoxDecoration(
                                                                color: Colors.green.shade50,
                                                                borderRadius: BorderRadius.circular(12),
                                                              ),
                                                              child: Text(
                                                                'Active Blind Person',
                                                                style: TextStyle(
                                                                  color: Colors.green.shade700,
                                                                  fontSize: 12,
                                                                  fontWeight: FontWeight.w500,
                                                                ),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                        trailing: Container(
                                                          width: 40,
                                                          height: 40,
                                                          decoration: BoxDecoration(
                                                            color: Colors.blue.shade50,
                                                            borderRadius: BorderRadius.circular(20),
                                                          ),
                                                          child: Icon(
                                                            Icons.arrow_forward_ios,
                                                            color: Colors.blue.shade400,
                                                            size: 16,
                                                          ),
                                                        ),
                                                        onTap: () {
                                                          ScaffoldMessenger.of(context).showSnackBar(
                                                            SnackBar(
                                                              content: Text('Selected ${user.name}'),
                                                              backgroundColor: Colors.blue,
                                                              behavior: SnackBarBehavior.floating,
                                                              shape: RoundedRectangleBorder(
                                                                borderRadius: BorderRadius.circular(10),
                                                              ),
                                                            ),
                                                          );
                                                        },
                                                      ),
                                                    ),
                                                  ),
                                                );
                                              },
                                            );
                                          },
                                        ),
                                ),
                              ],
                            ),
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
