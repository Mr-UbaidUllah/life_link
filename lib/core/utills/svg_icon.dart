
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SvgIcon extends StatelessWidget {  
  final String assetName;
  final Function()? onTap;
  final double? width;
  final double? height;
  final Color? color;
  final BoxFit fit;
  const SvgIcon(
    this.assetName, {
    super.key,
    this.onTap,
    this.width,
    this.height,
    this.color,
    this.fit = BoxFit.contain,
  });
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        enableFeedback: true,
        onTap: onTap,
        child: SvgPicture.asset(
          assetName,
          width: width,
          height: height,
          colorFilter: color != null
              ? ColorFilter.mode(color!, BlendMode.srcIn)
              : null,
          fit: fit,
        ),
      ),
    );
  }
}
