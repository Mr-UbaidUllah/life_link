import 'package:flutter/material.dart';

class CustomDropdown extends StatelessWidget {
  final String hint;
  final List<String> items;
  final String? selectedValue;
  final ValueChanged<String?> onChanged;

  const CustomDropdown({
    super.key,
    required this.hint,
    required this.items,
    required this.selectedValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: width * 0.03,
        vertical: height * 0.004,
      ),
      child: Container(
        height: height * 0.06,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: theme.colorScheme.outline),
        ),
        child: DropdownButtonFormField<String>(
          value: selectedValue,
          dropdownColor: theme.colorScheme.surface,
          hint: Text(
            hint,
            style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6)),
          ),
          icon: Icon(Icons.arrow_drop_down, color: theme.colorScheme.onSurface.withOpacity(0.6)),
          decoration: const InputDecoration(border: InputBorder.none),
          items: items.map((String value) {
            return DropdownMenuItem<String>(
              value: value, 
              child: Text(
                value,
                style: TextStyle(color: theme.colorScheme.onSurface),
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
