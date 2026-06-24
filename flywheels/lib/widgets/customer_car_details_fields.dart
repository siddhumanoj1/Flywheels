import 'package:flywheels/services/car_media_service.dart';
import 'package:flywheels/widgets/app_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class CustomerCarDetailsFields extends StatefulWidget {
  const CustomerCarDetailsFields({
    super.key,
    required this.picker,
    required this.carNumberController,
    required this.modelController,
    required this.fuelController,
    required this.yearController,
    this.initialImagePath,
    this.onImagePathChanged,
    this.onEdited,
  });

  final ImagePicker picker;
  final TextEditingController carNumberController;
  final TextEditingController modelController;
  final TextEditingController fuelController;
  final TextEditingController yearController;
  final String? initialImagePath;
  final ValueChanged<String?>? onImagePathChanged;
  final VoidCallback? onEdited;

  @override
  State<CustomerCarDetailsFields> createState() =>
      _CustomerCarDetailsFieldsState();
}

class _CustomerCarDetailsFieldsState extends State<CustomerCarDetailsFields> {
  static const _companies = {
    'MG': ['Hector', 'Astor', 'Gloster', 'ZS EV'],
    'Hyundai': ['Creta', 'Venue', 'Verna', 'i20'],
    'Maruti Suzuki': ['Swift', 'Baleno', 'Brezza', 'Ertiga'],
    'Tata': ['Nexon', 'Harrier', 'Punch', 'Safari'],
    'Mahindra': ['XUV700', 'Scorpio N', 'Thar', 'XUV300'],
    'Toyota': ['Innova Crysta', 'Fortuner', 'Glanza', 'Urban Cruiser'],
    'Kia': ['Seltos', 'Sonet', 'Carens', 'EV6'],
    'Honda': ['City', 'Amaze', 'Elevate', 'Jazz'],
  };

  late String _selectedCompany;
  late String _selectedModel;
  String? _selectedImagePath;

  @override
  void initState() {
    super.initState();
    _selectedCompany = _companies.keys.first;
    _selectedModel = _companies[_selectedCompany]!.first;
    _selectedImagePath = widget.initialImagePath;
    _hydrateDefaults();
  }

  void _hydrateDefaults() {
    if (widget.yearController.text.trim().isEmpty) {
      widget.yearController.text = DateTime.now().year.toString();
    }
    if (widget.modelController.text.trim().isEmpty) {
      widget.modelController.text = '$_selectedCompany $_selectedModel';
      return;
    }

    final existingModel = widget.modelController.text.toLowerCase();
    for (final entry in _companies.entries) {
      for (final model in entry.value) {
        if (existingModel.contains(entry.key.toLowerCase()) &&
            existingModel.contains(model.toLowerCase())) {
          _selectedCompany = entry.key;
          _selectedModel = model;
          return;
        }
      }
    }
  }

  int get _year {
    return int.tryParse(widget.yearController.text.trim()) ??
        DateTime.now().year;
  }

  String get _previewPath {
    return _selectedImagePath ??
        CarMediaService.imageForModel(widget.modelController.text, year: _year);
  }

  void _markEdited() {
    widget.onEdited?.call();
  }

  Future<void> _pickCarImage() async {
    final image = await widget.picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (image == null) return;
    if (!mounted) return;
    setState(() => _selectedImagePath = image.path);
    widget.onImagePathChanged?.call(image.path);
    _markEdited();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppImage(
          path: _previewPath,
          width: double.infinity,
          height: 150,
          borderRadius: BorderRadius.circular(12),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: widget.carNumberController,
          textInputAction: TextInputAction.next,
          onChanged: (_) => _markEdited(),
          decoration: const InputDecoration(labelText: 'Car number'),
        ),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
          initialValue: _selectedCompany,
          decoration: const InputDecoration(labelText: 'Company'),
          items: _companies.keys
              .map(
                (company) =>
                    DropdownMenuItem(value: company, child: Text(company)),
              )
              .toList(),
          onChanged: (value) {
            if (value == null) return;
            setState(() {
              _selectedCompany = value;
              _selectedModel = _companies[value]!.first;
              widget.modelController.text = '$_selectedCompany $_selectedModel';
            });
            _markEdited();
          },
        ),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
          key: ValueKey(_selectedCompany),
          initialValue: _selectedModel,
          decoration: const InputDecoration(labelText: 'Model'),
          items: _companies[_selectedCompany]!
              .map(
                (model) => DropdownMenuItem(value: model, child: Text(model)),
              )
              .toList(),
          onChanged: (value) {
            if (value == null) return;
            setState(() {
              _selectedModel = value;
              widget.modelController.text = '$_selectedCompany $_selectedModel';
            });
            _markEdited();
          },
        ),
        const SizedBox(height: 10),
        TextField(
          controller: widget.modelController,
          textInputAction: TextInputAction.next,
          onChanged: (_) {
            setState(() {});
            _markEdited();
          },
          decoration: const InputDecoration(
            labelText: 'Full model number / variant',
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: widget.fuelController,
          textInputAction: TextInputAction.next,
          onChanged: (_) => _markEdited(),
          decoration: const InputDecoration(labelText: 'Fuel type'),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: widget.yearController,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.done,
          onChanged: (_) {
            setState(() {});
            _markEdited();
          },
          decoration: const InputDecoration(labelText: 'Year'),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _pickCarImage,
          icon: const Icon(Icons.photo_outlined),
          label: Text(
            _selectedImagePath == null
                ? 'Use my car picture'
                : 'Change selected picture',
          ),
        ),
      ],
    );
  }
}
