import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class CustomButton extends StatelessWidget {
  const CustomButton({
    Key? key,
    required this.buttonColor,
    required this.onButtonPress,
    required this.buttonHeight,
    this.buttonWidth,
    this.showIconButton,
    this.borderColor,
    this.buttonText,
    this.icon,
    required this.textColor,
    this.topLeftRadius,
    this.topRightRadius,
    this.bottomRightRadius,
    this.bottomLeftRadius,
    this.fontSize,
    this.isLoading,
  }) : super(key: key);
  final Color buttonColor;
  final Color? borderColor;
  final String? buttonText;
  final void Function() onButtonPress;
  final double buttonHeight;
  final double? buttonWidth;
  final bool? showIconButton;
  final String? icon;
  final Color textColor;
  final double? topLeftRadius;
  final double? topRightRadius;
  final double? bottomRightRadius;
  final double? bottomLeftRadius;
  final double? fontSize;
  final bool? isLoading;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // excludeFromSemantics: true,
      onTap: (isLoading ?? false) ? () {} : onButtonPress,
      child: Container(
        height: buttonHeight,
        width: buttonWidth ?? 350,
        margin: const EdgeInsets.symmetric(horizontal: 0),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: borderColor != null
              ? Border.all(color: borderColor!, width: 1)
              : null,
          color: buttonColor,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(topLeftRadius ?? 6),
            topRight: Radius.circular(topRightRadius ?? 6),
            bottomRight: Radius.circular(bottomRightRadius ?? 6),
            bottomLeft: Radius.circular(bottomLeftRadius ?? 6),
          ),
        ),
        child: (isLoading ?? false)
            ? const CircularProgressIndicator(
                color: Colors.white,
              )
            : showIconButton ?? false
                ? SvgPicture.asset(
                    icon ?? 'assets/vertical_dots.svg',
                  )
                : Text(
                    buttonText ?? '',
                    style: TextStyle(
                      fontSize: fontSize ?? 18,
                      color: textColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
      ),
    );
  }
}
