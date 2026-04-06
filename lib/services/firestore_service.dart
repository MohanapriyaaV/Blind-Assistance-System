import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> saveUser(AppUser user) async {
    await _db.collection('users').doc(user.uid).set(user.toMap());
  }

  Future<AppUser?> getUser(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return AppUser.fromMap(doc.data()!);
  }

  Future<UserCredential> registerBlindPerson(String name, String email, String password, String caretakerId) async {
    final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    
    final blindUserId = userCredential.user!.uid;
    
    // Create blind user
    final user = AppUser(
      uid: blindUserId,
      email: email,
      name: name,
      role: 'blind',
      caretakerId: caretakerId,
    );
    
    await saveUser(user);
    
    // Update caretaker's blindUserIds array
    await _db.collection('users').doc(caretakerId).update({
      'blindUserIds': FieldValue.arrayUnion([blindUserId])
    });
    
    return userCredential;
  }

  Future<List<AppUser>> getBlindUsersForCaretaker(String caretakerId) async {
    final caretaker = await getUser(caretakerId);
    if (caretaker?.blindUserIds == null) return [];
    
    final List<AppUser> blindUsers = [];
    for (String blindUserId in caretaker!.blindUserIds!) {
      final blindUser = await getUser(blindUserId);
      if (blindUser != null) blindUsers.add(blindUser);
    }
    return blindUsers;
  }
}
