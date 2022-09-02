import 'package:flutter/material.dart';

class CustomIconButton extends StatefulWidget {
  final AnimatedIconData icon;
  final Function buttonFon;
  final double? iconSize;
  final Color? iconColor;
  final Duration duration;

  const CustomIconButton({
    Key? key,
    this.icon = AnimatedIcons.play_pause,
    this.iconSize,
    this.iconColor,
    this.duration = const Duration(milliseconds: 500),
    required this.buttonFon,
  }) : super(key: key);

  @override
  CustomIconButtonState createState() => CustomIconButtonState();
}

class CustomIconButtonState extends State<CustomIconButton> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  bool isPlaying = false;

  @override
  Widget build(BuildContext context) {
    return IconButton(
        iconSize: widget.iconSize,
        onPressed: () {
          _handleOnPressed();
          widget.buttonFon();
        },
        icon: AnimatedIcon(
          icon: widget.icon,
          progress: _animationController,
          color: widget.iconColor,
        ));
  }

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleOnPressed() {
    setState(() {
      isPlaying = !isPlaying;
      isPlaying ? _animationController.forward() : _animationController.reverse();
    });
  }
}
