// DEVELOPMENT ONLY - Check allocation directly
// Add this to ManageTargetsView for debugging

Future<void> _debugCheckFirestore() async {
  final firestore = FirebaseFirestore.instance;
  
  // Get active target
  final targetSnap = await firestore
      .collection('graduation_targets')
      .where('status', whereIn: ['active', 'closing_soon'])
      .limit(1)
      .get();
      
  if (targetSnap.docs.isEmpty) {
    print('❌ No active target');
    return;
  }
  
  final targetData = targetSnap.docs.first.data();
  final targetId = targetSnap.docs.first.id;
  
  // Get general fund
  final fundSnap = await firestore.collection('general_fund').doc('current').get();
  final fundData = fundSnap.data();
  
  print('📊 FIRESTORE DATA:');
  print('Target ID: $targetId');
  print('  - current_amount: ${targetData['current_amount']}');
  print('  - allocated_from_fund: ${targetData['allocated_from_fund']}');
  print('  - target_amount: ${targetData['target_amount']}');
  print('');
  print('General Fund:');
  print('  - balance: ${fundData?['balance']}');
  print('');
  
  // Calculate what allocation SHOULD be
  final current = (targetData['current_amount'] as num?)?.toDouble() ?? 0.0;
  final target = (targetData['target_amount'] as num?)?.toDouble() ?? 0.0;
  final fund = (fundData?['balance'] as num?)?.toDouble() ?? 0.0;
  
  final needed = target - current;
  final shouldAllocate = fund < needed ? fund : needed;
  
  print('📐 CALCULATION:');
  print('  - Still needed: $needed');
  print('  - Fund available: $fund');
  print('  - SHOULD allocate: $shouldAllocate');
  
  // FORCE UPDATE
  await firestore.collection('graduation_targets').doc(targetId).update({
    'allocated_from_fund': shouldAllocate,
  });
  
  print('');
  print('✅ FORCE UPDATED allocated_from_fund to $shouldAllocate');
}
