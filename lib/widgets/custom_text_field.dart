import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CustomTextField extends StatefulWidget {
  final TextEditingController? controller;
  final String? hintText;
  final String? labelText;
  final Widget? customLabel;
  final Widget? labelPrefix;
  final String? suffixText;
  final Widget? suffixIcon;
  final IconData? prefixIcon;
  final Widget? prefixIconWidget;
  final Widget? prefix;
  final String? prefixText;
  final String? initialValue;
  final bool isPassword;
  final bool obscureText;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;
  final void Function()? onTap;
  final bool enabled;
  final bool readOnly;
  final int? maxLines;
  final int? minLines;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;
  final FocusNode? focusNode;
  final FocusNode? nextFocusNode;
  final bool autofocus;
  final TextCapitalization textCapitalization;
  final TextAlign textAlign;
  final EdgeInsetsGeometry? contentPadding;
  final double borderRadius;
  final Color? borderColor;
  final Color? focusedBorderColor;
  final Color? errorBorderColor;
  final Color? backgroundColor;
  final TextStyle? textStyle;
  final TextStyle? hintStyle;
  final bool showCharacterCount;
  final double? width;
  final double? height;
  final bool isFilled;
  final Color? fillColor;
  final String? errorText;

  const CustomTextField({
    super.key,
    this.controller,
    this.initialValue,
    this.hintText,
    this.labelText,
    this.customLabel,
    this.labelPrefix,
    this.suffixText,
    this.suffixIcon,
    this.prefixIcon,
    this.prefixIconWidget,
    this.prefix,
    this.prefixText,
    this.isPassword = false,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.enabled = true,
    this.readOnly = false,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.inputFormatters,
    this.focusNode,
    this.nextFocusNode,
    this.autofocus = false,
    this.textCapitalization = TextCapitalization.none,
    this.textAlign = TextAlign.start,
    this.contentPadding,
    this.borderRadius = 12.0,
    this.borderColor,
    this.focusedBorderColor,
    this.errorBorderColor,
    this.backgroundColor,
    this.textStyle,
    this.hintStyle,
    this.showCharacterCount = false,
    this.width,
    this.height = 50,
    this.isFilled = false,
    this.fillColor,
    this.errorText,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  late bool _obscureText;
  late FocusNode _focusNode;
  bool _isInternalFocusNode = false;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.isPassword ? true : widget.obscureText;

    if (widget.focusNode == null) {
      _focusNode = FocusNode();
      _isInternalFocusNode = true;
    } else {
      _focusNode = widget.focusNode!;
      _isInternalFocusNode = false;
    }

    _focusNode.canRequestFocus = true;
  }

  @override
  void didUpdateWidget(CustomTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.focusNode != oldWidget.focusNode) {
      if (_isInternalFocusNode) {
        _focusNode.dispose();
      }
      if (widget.focusNode == null) {
        _focusNode = FocusNode();
        _isInternalFocusNode = true;
      } else {
        _focusNode = widget.focusNode!;
        _isInternalFocusNode = false;
      }
    }
  }

  @override
  void dispose() {
    if (_isInternalFocusNode) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  void _toggleObscureText() {
    setState(() {
      _obscureText = !_obscureText;
    });
  }

  void _handleSubmitted(String value) {
    if (widget.onSubmitted != null) {
      widget.onSubmitted!(value);
    }
    if (widget.nextFocusNode != null) {
      FocusScope.of(context).requestFocus(widget.nextFocusNode);
    } else if (widget.textInputAction == TextInputAction.done) {
      _focusNode.unfocus();
    }
  }

  Widget? _buildSuffixIcon(ThemeData theme) {
    if (widget.isPassword) {
      return IconButton(
        icon: Icon(
          _obscureText ? Icons.visibility_off : Icons.visibility,
          color: theme.colorScheme.onSurface.withOpacity(0.6),
          size: 20,
        ),
        onPressed: _toggleObscureText,
        splashRadius: 20,
      );
    }
    return widget.suffixIcon;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveBorderColor = widget.borderColor ?? theme.colorScheme.outline;
    final effectiveFocusedBorderColor = widget.focusedBorderColor ?? theme.colorScheme.primary;
    final effectiveErrorBorderColor = widget.errorBorderColor ?? theme.colorScheme.error;
    final effectiveBackgroundColor = widget.backgroundColor ?? Colors.transparent;
    final effectiveFillColor = widget.fillColor ?? theme.colorScheme.surfaceContainerHighest.withOpacity(0.3);

    return Container(
      width: widget.width,
      constraints: BoxConstraints(minHeight: widget.height ?? 60),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.customLabel != null) ...[
            widget.customLabel!,
          ] else if (widget.labelText != null) ...[
            Row(
              children: [
                if (widget.labelPrefix != null) ...[
                  widget.labelPrefix!,
                  const SizedBox(width: 8),
                ],
                Text(
                  widget.labelText!,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
          Flexible(
            child: widget.prefixText != null
                ? Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(widget.borderRadius),
                      border: Border.all(
                        color: _focusNode.hasFocus
                            ? effectiveFocusedBorderColor
                            : (widget.errorText != null
                                  ? effectiveErrorBorderColor
                                  : effectiveBorderColor),
                        width: _focusNode.hasFocus ? 1.5 : 1.0,
                      ),
                      color: widget.isFilled ? effectiveFillColor : effectiveBackgroundColor,
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            widget.prefixText!,
                            style: TextStyle(
                              fontSize: 14,
                              color: theme.colorScheme.onSurface.withOpacity(0.7),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Expanded(
                          child: TextFormField(
                            controller: widget.controller,
                            initialValue: widget.controller == null ? widget.initialValue : null,
                            focusNode: _focusNode,
                            obscureText: _obscureText,
                            keyboardType: widget.keyboardType,
                            textInputAction: widget.textInputAction,
                            validator: widget.validator,
                            onChanged: widget.onChanged,
                            onFieldSubmitted: (value) => _handleSubmitted(value),
                            onTapOutside: (event) => FocusScope.of(context).unfocus(),
                            autovalidateMode: AutovalidateMode.onUserInteraction,
                            onTap: widget.onTap,
                            enabled: widget.enabled,
                            readOnly: widget.readOnly,
                            maxLines: widget.maxLines,
                            minLines: widget.minLines,
                            maxLength: widget.maxLength,
                            inputFormatters: widget.inputFormatters,
                            autofocus: widget.autofocus,
                            textCapitalization: widget.textCapitalization,
                            textAlign: widget.textAlign,
                            style: widget.textStyle ?? TextStyle(
                              fontSize: 15,
                              color: theme.colorScheme.onSurface,
                            ),
                            decoration: InputDecoration(
                              hintText: widget.hintText,
                              hintStyle: widget.hintStyle ?? TextStyle(
                                color: theme.colorScheme.onSurface.withOpacity(0.4),
                              ),
                              suffixText: widget.suffixText,
                              suffixIcon: widget.suffixText == null ? _buildSuffixIcon(theme) : null,
                              prefixIcon: widget.prefixIconWidget ?? (widget.prefixIcon == null ? null : Icon(widget.prefixIcon, color: theme.colorScheme.onSurface.withOpacity(0.6))),
                              filled: false,
                              counterText: widget.showCharacterCount ? null : '',
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              errorBorder: InputBorder.none,
                              focusedErrorBorder: InputBorder.none,
                              disabledBorder: InputBorder.none,
                              isDense: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : TextFormField(
                    controller: widget.controller,
                    initialValue: widget.controller == null ? widget.initialValue : null,
                    focusNode: _focusNode,
                    obscureText: _obscureText,
                    keyboardType: widget.keyboardType,
                    textInputAction: widget.textInputAction,
                    validator: widget.validator,
                    onChanged: widget.onChanged,
                    onFieldSubmitted: (value) => _handleSubmitted(value),
                    onTapOutside: (event) => FocusScope.of(context).unfocus(),
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    onTap: widget.onTap,
                    enabled: widget.enabled,
                    readOnly: widget.readOnly,
                    maxLines: widget.maxLines,
                    minLines: widget.minLines,
                    maxLength: widget.maxLength,
                    inputFormatters: widget.inputFormatters,
                    autofocus: widget.autofocus,
                    textCapitalization: widget.textCapitalization,
                    textAlign: widget.textAlign,
                    style: widget.textStyle ?? TextStyle(
                      fontSize: 15,
                      color: theme.colorScheme.onSurface,
                    ),
                    decoration: InputDecoration(
                      hintText: widget.hintText,
                      hintStyle: widget.hintStyle ?? TextStyle(
                        color: theme.colorScheme.onSurface.withOpacity(0.4),
                      ),
                      prefix: widget.prefix,
                      suffixText: widget.suffixText,
                      suffixIcon: widget.suffixText == null ? _buildSuffixIcon(theme) : null,
                      prefixIcon: widget.prefixIconWidget ?? (widget.prefixIcon == null ? null : Icon(widget.prefixIcon, color: theme.colorScheme.onSurface.withOpacity(0.6))),
                      filled: widget.isFilled,
                      fillColor: effectiveFillColor,
                      counterText: widget.showCharacterCount ? null : '',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(widget.borderRadius),
                        borderSide: BorderSide(color: effectiveBorderColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(widget.borderRadius),
                        borderSide: BorderSide(color: effectiveBorderColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(widget.borderRadius),
                        borderSide: BorderSide(color: effectiveFocusedBorderColor, width: 1.5),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(widget.borderRadius),
                        borderSide: BorderSide(color: effectiveErrorBorderColor),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(widget.borderRadius),
                        borderSide: BorderSide(color: effectiveErrorBorderColor, width: 1.5),
                      ),
                      disabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(widget.borderRadius),
                        borderSide: BorderSide(color: theme.disabledColor.withOpacity(0.1)),
                      ),
                      errorStyle: TextStyle(color: theme.colorScheme.error, fontSize: 12),
                      errorMaxLines: 2,
                      errorText: widget.errorText,
                      isDense: true,
                    ),
                  ),
          ),
          if (widget.prefixText != null && widget.errorText != null)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                widget.errorText!,
                style: TextStyle(color: theme.colorScheme.error, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }
}
