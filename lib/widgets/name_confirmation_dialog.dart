import 'package:flutter/material.dart';

/// Dialog untuk konfirmasi nama yang mirip
class NameConfirmationDialog extends StatelessWidget {
  final String inputName;
  final String existingName;
  final double similarity;

  const NameConfirmationDialog({
    super.key,
    required this.inputName,
    required this.existingName,
    required this.similarity,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 450),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with close button
              Row(
                children: [
                  // Title
                  const Expanded(
                    child: Text(
                      'Similar Name Found',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  // Close button
                  IconButton(
                    onPressed: () => Navigator.pop(context, null),
                    icon: const Icon(Icons.close),
                    color: Colors.red.shade300,
                    iconSize: 24,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    tooltip: 'Cancel',
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Description
              Text(
                'We found a similar name in our records.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 24),

              // Your input
              _buildNameCard(
                label: 'You entered',
                name: inputName,
                color: Colors.blue,
              ),
              const SizedBox(height: 12),

              // Existing name
              _buildNameCard(
                label: 'Existing name',
                name: existingName,
                color: Colors.green,
              ),
              const SizedBox(height: 16),

              // Similarity indicator
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade300),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.analytics_outlined,
                      size: 18,
                      color: Colors.orange.shade800,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${similarity.toStringAsFixed(0)}% match',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.orange.shade900,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Question
              const Text(
                'Is this the same person?',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),

              // Actions (only 2 buttons now)
              Row(
                children: [
                  // No button
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(color: Colors.blue.shade300),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'No, Create New',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Yes button
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        backgroundColor: Colors.green.shade600,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Yes, That\'s Me',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNameCard({
    required String label,
    required String name,
    required MaterialColor color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.shade100,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.shade300),
          ),
          child: Row(
            children: [
              Icon(Icons.person, color: color.shade700, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  name,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: color.shade900,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
