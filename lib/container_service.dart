import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/container_model.dart';

class ContainerService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get container by ID
  Future<ContainerData?> getContainerById(String containerId) async {
    try {
      final doc = await _firestore
          .collection('containers')
          .doc(containerId)
          .get();

      if (doc.exists) {
        return ContainerData.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Error fetching container: $e');
    }
  }

  // Save scanned container to user's history
  Future<void> saveToScanHistory({
    required String userId,
    required ContainerData container,
  }) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('scanHistory')
          .doc(container.containerId)
          .set({
        'containerId': container.containerId,
        'containerNumber': container.containerNumber,
        'voyageId': container.voyageId,
        'priority': container.priority.index,
        'cargoType': container.cargoType.index,
        'dateCreated': Timestamp.fromDate(container.dateCreated),
        'scannedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Error saving scan history: $e');
    }
  }

  // Get user's scan history
  Stream<List<ContainerData>> getScanHistory(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('scanHistory')
        .orderBy('scannedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ContainerData.fromFirestore(doc))
            .toList());
  }

  // Add sample containers to Firestore (for testing)
  Future<void> addSampleContainers() async {
    final containers = [
      {
        'containerId': 'CON123456',
        'containerNumber': 'C12345',
        'voyageId': 'V789',
        'priority': 1, // Medium
        'cargoType': 0, // General
        'dateCreated': Timestamp.fromDate(DateTime.now().subtract(Duration(days: 5))),
      },
      {
        'containerId': 'CON789012',
        'containerNumber': 'C78901',
        'voyageId': 'V456',
        'priority': 2, // High
        'cargoType': 1, // Refrigerated
        'dateCreated': Timestamp.fromDate(DateTime.now().subtract(Duration(days: 2))),
      },
    ];

    for (var container in containers) {
      await _firestore
          .collection('containers')
          .doc(container['containerId'] as String)
          .set(container);
    }
  }
}