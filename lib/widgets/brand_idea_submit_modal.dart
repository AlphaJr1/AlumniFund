import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/brand_identity_provider.dart';
import '../providers/user_identification_provider.dart';

class BrandIdeaSubmitModal extends ConsumerStatefulWidget {
  final String? userId;

  const BrandIdeaSubmitModal({
    super.key,
    this.userId,
  });

  @override
  ConsumerState<BrandIdeaSubmitModal> createState() =>
      _BrandIdeaSubmitModalState();
}

class _BrandIdeaSubmitModalState extends ConsumerState<BrandIdeaSubmitModal> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _titleController = TextEditingController();
  final _philosophyController = TextEditingController();
  bool _isSubmitting = false;
  bool _isEditMode = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill data from existing idea or user data
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final userState = ref.read(userIdentificationProvider);
      final user = userState.userData;
      
      // Pre-fill name
      if (user != null) {
        _nameController.text = user.displayName;
      }
      
      // Fetch existing idea if userId available
      final userId = user?.userId ?? widget.userId;
      if (userId != null) {
        try {
          final service = ref.read(brandIdentityServiceProvider);
          final existingIdea = await service.getUserIdea(userId);
          
          if (existingIdea != null) {
            // Edit mode - pre-fill all fields
            setState(() {
              _isEditMode = true;
              _nameController.text = existingIdea.submittedByName;
              _titleController.text = existingIdea.title;
              _philosophyController.text = existingIdea.philosophy;
            });
          }
        } catch (e) {
          // Silently fail - user can still submit new
        }
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _titleController.dispose();
    _philosophyController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final service = ref.read(brandIdentityServiceProvider);
      
      // Prioritas: gunakan userId dari userIdentificationProvider
      final userState = ref.read(userIdentificationProvider);
      final userData = userState.userData;
      
      final effectiveUserId = userData?.userId ?? 
          widget.userId ?? 
          'anon_${_nameController.text.trim().toLowerCase().replaceAll(' ', '_')}';
      
      await service.submitIdea(
        userId: effectiveUserId,
        title: _titleController.text.trim(),
        philosophy: _philosophyController.text.trim(),
        submittedByName: _nameController.text.trim(),
      );

      // Invalidate provider to refresh data
      ref.invalidate(brandIdentityProvider(effectiveUserId));

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditMode 
              ? 'Your idea has been updated successfully!' 
              : 'Your idea has been submitted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userState = ref.watch(userIdentificationProvider);
    final user = userState.userData;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.deepPurple.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.lightbulb,
                        color: Colors.deepPurple.shade600,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        _isEditMode ? 'Update Your Idea' : 'Submit Your Idea',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                // Name Confirmation
                const Text(
                  'Your Name:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Is this you: ${user?.displayName ?? ""}?',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'If not, please correct it below:',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    hintText: 'Your full name',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Brand Name
                const Text(
                  'Brand Name:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _titleController,
                  maxLength: 30,
                  decoration: InputDecoration(
                    hintText: 'Your choice will be used for this community',
                    hintStyle: TextStyle(
                      color: Colors.grey.withOpacity(0.4),
                      fontSize: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    counterText: '',
                  ),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                  textCapitalization: TextCapitalization.characters,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a brand name';
                    }
                    if (value.trim().length > 30) {
                      return 'Maximum 30 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Philosophy
                const Text(
                  'Philosophy:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Explain your concept and vision',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _philosophyController,
                  maxLines: 6,
                  decoration: InputDecoration(
                    hintText: 'Share the meaning and story behind your proposed name...',
                    hintStyle: TextStyle(
                      color: Colors.grey.withOpacity(0.3),
                      fontSize: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please describe the philosophy';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isSubmitting
                            ? null
                            : () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _handleSubmit,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: Colors.deepPurple,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(_isEditMode ? 'Update' : 'Submit'),
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
}
