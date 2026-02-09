import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

/// Script untuk fix allocation target yang sedang active
/// Mengupdate allocated_from_fund dari 100K menjadi 120K
void main() async {
  print('🔧 Starting allocation fix...');
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  final firestore = FirebaseFirestore.instance;
  
  try {
    // 1. Get active target
    final activeTargetSnapshot = await firestore
        .collection('graduation_targets')
        .where('status', whereIn: ['active', 'closing_soon'])
        .limit(1)
        .get();
    
    if (activeTargetSnapshot.docs.isEmpty) {
      print('❌ No active target found');
      return;
    }
    
    final activeTarget = activeTargetSnapshot.docs.first;
    final targetData = activeTarget.data();
    final currentAllocated = (targetData['allocated_from_fund'] as num?)?.toDouble() ?? 0.0;
    final currentAmount = (targetData['current_amount'] as num?)?.toDouble() ?? 0.0;
    final targetAmount = (targetData['target_amount'] as num?)?.toDouble() ?? 0.0;
    
    print('📊 Current Target Status:');
    print('   - ID: ${activeTarget.id}');
    print('   - Month: ${targetData['month']} ${targetData['year']}');
    print('   - current_amount: Rp ${currentAmount.toStringAsFixed(0)}');
    print('   - allocated_from_fund: Rp ${currentAllocated.toStringAsFixed(0)}');
    print('   - target_amount: Rp ${targetAmount.toStringAsFixed(0)}');
    
    // 2. Get general fund balance
    final fundDoc = await firestore
        .collection('general_fund')
        .doc('current')
        .get();
    
    final fundBalance = (fundDoc.data()?['balance'] as num?)?.toDouble() ?? 0.0;
    print('   - General Fund: Rp ${fundBalance.toStringAsFixed(0)}');
    
    // 3. Calculate new allocation
    final stillNeeded = targetAmount - currentAmount;
    final newAllocation = fundBalance < stillNeeded ? fundBalance : stillNeeded;
    final clampedAllocation = newAllocation > 0 ? newAllocation : 0.0;
    
    print('\n🔄 Recalculating allocation:');
    print('   - Still needed: Rp ${stillNeeded.toStringAsFixed(0)}');
    print('   - Available in fund: Rp ${fundBalance.toStringAsFixed(0)}');
    print('   - New allocation: Rp ${clampedAllocation.toStringAsFixed(0)}');
    
    // 4. Update target
    await activeTarget.reference.update({
      'allocated_from_fund': clampedAllocation,
      'updated_at': FieldValue.serverTimestamp(),
    });
    
    print('\n✅ Allocation updated successfully!');
    print('   - allocated_from_fund: Rp ${currentAllocated.toStringAsFixed(0)} → Rp ${clampedAllocation.toStringAsFixed(0)}');
    print('   - Display amount: Rp ${(currentAmount + clampedAllocation).toStringAsFixed(0)}');
    
  } catch (e) {
    print('❌ Error: $e');
  }
}
