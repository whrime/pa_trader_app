import 'package:flutter/material.dart';

class CustomInputField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool readOnly;
  final double width;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final List<String>? dropdownItems;
  final String? hintText;

  const CustomInputField({
    Key? key,
    required this.label,
    required this.controller,
    this.readOnly = false,
    this.width = 100,
    this.validator,
    this.onChanged,
    this.dropdownItems,
    this.hintText,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: dropdownItems != null
                ? _buildDropdown()
                : _buildTextField(),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField() {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      enabled: !readOnly,
      onChanged: onChanged,
      validator: validator,
      decoration: InputDecoration(
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
        ),
        filled: readOnly,
        fillColor: readOnly ? Colors.grey[100] : null,
        hintText: hintText,
      ),
      style: TextStyle(
        fontSize: 14,
        color: readOnly ? Colors.grey[700] : Colors.black,
      ),
    );
  }

  Widget _buildDropdown() {
    return DropdownButtonFormField<String>(
      value: controller.text.isEmpty ? null : controller.text,
      items: dropdownItems!.map((item) {
        return DropdownMenuItem(
          value: item,
          child: Text(item),
        );
      }).toList(),
      onChanged: (value) {
        if (value != null) {
          controller.text = value;
          onChanged?.call(value);
        }
      },
      decoration: InputDecoration(
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }
}

class ReadOnlyDisplayField extends StatelessWidget {
  final String label;
  final String value;
  final double width;

  const ReadOnlyDisplayField({
    Key? key,
    required this.label,
    required this.value,
    this.width = 100,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: Colors.grey[100],
                border: Border.all(color: Colors.grey[400]!),
              ),
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
