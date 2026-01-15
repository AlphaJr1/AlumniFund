import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/graduate_model.dart';

/// Form data for a single graduate
class GraduateFormData {
  final TextEditingController nameController;
  final TextEditingController locationController;
  DateTime? date;

  GraduateFormData({
    String? name,
    String? location,
    this.date,
  })  : nameController = TextEditingController(text: name),
        locationController = TextEditingController(text: location);

  factory GraduateFormData.empty() {
    return GraduateFormData();
  }

  factory GraduateFormData.fromGraduate(Graduate graduate) {
    return GraduateFormData(
      name: graduate.name,
      location: graduate.location,
      date: graduate.date,
    );
  }

  bool isValid() {
    return nameController.text.isNotEmpty &&
        locationController.text.isNotEmpty &&
        date != null;
  }

  Graduate toGraduate() {
    return Graduate(
      name: nameController.text,
      date: date!,
      location: locationController.text,
    );
  }

  void dispose() {
    nameController.dispose();
    locationController.dispose();
  }
}

/// Reusable widget untuk dynamic graduate list form
class GraduateListBuilder extends StatefulWidget {
  final List<Graduate>? initialGraduates;
  final int? selectedMonth;
  final int? selectedYear;
  final Function(List<Graduate>) onChanged;
  final Function(String?)? onValidationError;

  const GraduateListBuilder({
    super.key,
    this.initialGraduates,
    this.selectedMonth,
    this.selectedYear,
    required this.onChanged,
    this.onValidationError,
  });

  @override
  State<GraduateListBuilder> createState() => _GraduateListBuilderState();
}

class _GraduateListBuilderState extends State<GraduateListBuilder> {
  List<GraduateFormData> _graduates = [];

  @override
  void initState() {
    super.initState();
    if (widget.initialGraduates != null && widget.initialGraduates!.isNotEmpty) {
      _graduates = widget.initialGraduates!
          .map((g) => GraduateFormData.fromGraduate(g))
          .toList();
    } else {
      _graduates = [GraduateFormData.empty()];
    }
  }

  @override
  void dispose() {
    for (var graduate in _graduates) {
      graduate.dispose();
    }
    super.dispose();
  }

  void _addGraduate() {
    setState(() {
      _graduates.add(GraduateFormData.empty());
    });
  }

  void _removeGraduate(int index) {
    if (_graduates.length > 1) {
      setState(() {
        _graduates[index].dispose();
        _graduates.removeAt(index);
      });
      _notifyParent();
    }
  }

  void _updateGraduate(int index, {String? name, String? location, DateTime? date}) {
    setState(() {
      if (name != null) _graduates[index].nameController.text = name;
      if (location != null) _graduates[index].locationController.text = location;
      if (date != null) _graduates[index].date = date;
    });
    _notifyParent();
  }

  String? _validate() {
    // Check minimum 1 graduate
    if (_graduates.isEmpty) {
      return 'Add at least 1 recipient';
    }

    // Check all fields filled
    for (var i = 0; i < _graduates.length; i++) {
      final graduate = _graduates[i];
      if (graduate.nameController.text.isEmpty) {
        return 'Lengkapi nama wisudawan #${i + 1}';
      }
      if (graduate.locationController.text.isEmpty) {
        return 'Lengkapi lokasi wisudawan #${i + 1}';
      }
      if (graduate.date == null) {
        return 'Lengkapi tanggal wisudawan #${i + 1}';
      }
    }

    // Check no duplicate names
    final names = _graduates
        .map((g) => g.nameController.text.toLowerCase().trim())
        .where((name) => name.isNotEmpty)
        .toList();
    if (names.length != names.toSet().length) {
      return 'Recipient name must be unique';
    }

    return null;
  }

  void _notifyParent() {
    final error = _validate();
    
    if (widget.onValidationError != null) {
      widget.onValidationError!(error);
    }

    if (error == null) {
      final graduates = _graduates
          .where((g) => g.isValid())
          .map((g) => g.toGraduate())
          .toList();
      widget.onChanged(graduates);
    } else {
      widget.onChanged([]);
    }
  }

  String _getMonthName(int month) {
    const months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Recipients List',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 16),
        
        // Graduate rows
        ..._graduates.asMap().entries.map((entry) {
          final index = entry.key;
          final graduate = entry.value;
          
          return _buildGraduateRow(index, graduate);
        }),
        
        const SizedBox(height: 16),
        
        // Add button
        OutlinedButton.icon(
          icon: const Icon(Icons.add, size: 20),
          label: const Text('Add Recipient'),
          onPressed: _addGraduate,
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGraduateRow(int index, GraduateFormData graduate) {
    final canRemove = _graduates.length > 1;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with number and remove button
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Recipient',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF111827),
                ),
              ),
              const Spacer(),
              if (canRemove)
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  color: const Color(0xFFEF4444),
                  onPressed: () => _removeGraduate(index),
                  tooltip: 'Delete',
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Name input
          TextFormField(
            controller: graduate.nameController,
            decoration: InputDecoration(
              labelText: 'Name *',
              hintText: 'Enter recipient name',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
            onChanged: (value) => _notifyParent(),
          ),
          const SizedBox(height: 12),

          // Date picker (flexible - any future date)
          InkWell(
            onTap: () async {
              final now = DateTime.now();
              final date = await showDatePicker(
                context: context,
                initialDate: graduate.date ?? now,
                firstDate: DateTime(now.year - 1),
                lastDate: DateTime(now.year + 5),
              );

              if (date != null) {
                _updateGraduate(index, date: date);
              }
            },
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: 'Graduation Date *',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.white,
                suffixIcon: const Icon(Icons.calendar_today),
              ),
              child: Text(
                graduate.date != null
                    ? DateFormat('dd MMMM yyyy', 'id_ID').format(graduate.date!)
                    : 'Select date',
                style: TextStyle(
                  color: graduate.date != null
                      ? const Color(0xFF111827)
                      : const Color(0xFF9CA3AF),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Location input
          TextFormField(
            controller: graduate.locationController,
            decoration: InputDecoration(
              labelText: 'Location *',
              hintText: 'Example: Main Hall',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
            onChanged: (value) => _notifyParent(),
          ),
        ],
      ),
    );
  }
}
