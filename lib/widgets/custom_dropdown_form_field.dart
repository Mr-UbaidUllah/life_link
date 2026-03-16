import 'package:flutter/material.dart';

class CustomDropdownFormField<T> extends StatelessWidget {
  final T? value;
  final List<T> items;
  final String Function(T) itemToString;
  final void Function(T?)? onChanged;
  final String? labelText;
  final Widget? customLabel;
  final Widget? labelPrefix;
  final String? hintText;
  final bool isExpanded;
  final EdgeInsetsGeometry? contentPadding;
  final double borderRadius;
  final Color? borderColor;
  final Color? focusedBorderColor;
  final Color? backgroundColor;
  final String? errorText;
  final String? Function(T?)? validator;
  final Widget? prefixIcon;
  final Widget? suffixIcon;

  final TextStyle? textStyle;
  final TextStyle? hintStyle;
  final bool enabled;
  final bool readOnly;

  const CustomDropdownFormField({
    super.key,
    required this.value,
    required this.items,
    required this.itemToString,
    this.onChanged,
    this.labelText,
    this.customLabel,
    this.labelPrefix,
    this.hintText,
    this.isExpanded = true,
    this.contentPadding,
    this.borderRadius = 12.0,
    this.borderColor,
    this.focusedBorderColor,
    this.backgroundColor,
    this.errorText,
    this.validator,
    this.prefixIcon,
    this.suffixIcon,
    this.textStyle,
    this.hintStyle,
    this.enabled = true,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveBorderColor = borderColor ?? theme.colorScheme.outline;
    final effectiveFocusedBorderColor = focusedBorderColor ?? theme.colorScheme.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (customLabel != null) ...[
          customLabel!,
          const SizedBox(height: 8),
        ] else if (labelText != null) ...[
          Row(
            children: [
              if (labelPrefix != null) ...[
                labelPrefix!,
                const SizedBox(width: 8),
              ],
              Text(
                labelText!,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
        DropdownButtonFormField<T>(
          value: value,
          isExpanded: isExpanded,
          dropdownColor: theme.colorScheme.surface,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(borderRadius),
              borderSide: BorderSide(color: effectiveBorderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(borderRadius),
              borderSide: BorderSide(color: effectiveBorderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(borderRadius),
              borderSide: BorderSide(color: effectiveFocusedBorderColor, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(borderRadius),
              borderSide: BorderSide(color: theme.colorScheme.error),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(borderRadius),
              borderSide: BorderSide(color: theme.colorScheme.error, width: 1.5),
            ),
            contentPadding:
                contentPadding ??
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            filled: backgroundColor != null,
            fillColor: backgroundColor,
            prefixIcon: prefixIcon,
            hintText: hintText,
            hintStyle:
                hintStyle ??
                TextStyle(
                  fontSize: 16,
                  color: theme.colorScheme.onSurface.withOpacity(0.4),
                  fontWeight: FontWeight.w400,
                ),
            errorText: errorText,
            errorStyle: TextStyle(color: theme.colorScheme.error, fontSize: 12),
          ),
          selectedItemBuilder: (BuildContext context) {
            return items.map<Widget>((T item) {
              return Container(
                alignment: Alignment.centerLeft,
                child: Text(
                  itemToString(item),
                  style:
                      textStyle ??
                      TextStyle(
                        fontSize: 16,
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.w400,
                      ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              );
            }).toList();
          },
          items: items.map((T item) {
            return DropdownMenuItem<T>(
              value: item,
              child: Text(
                itemToString(item),
                style: TextStyle(fontSize: 15, color: theme.colorScheme.onSurface),
              ),
            );
          }).toList(),
          onChanged: enabled && !readOnly ? onChanged : null,
          validator: validator,
          icon: suffixIcon ?? Icon(Icons.arrow_drop_down, color: theme.colorScheme.onSurface.withOpacity(0.6)),
        ),
      ],
    );
  }
}
