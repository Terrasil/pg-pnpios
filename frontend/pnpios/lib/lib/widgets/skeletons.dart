import 'package:flutter/material.dart';

class SkeletonBox extends StatefulWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;

  const SkeletonBox({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius,
  });

  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
      lowerBound: 0.45,
      upperBound: 0.95,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: widget.borderRadius ?? BorderRadius.circular(10),
        ),
      ),
    );
  }
}

class SkeletonListCard extends StatelessWidget {
  const SkeletonListCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            SkeletonBox(width: 54, height: 74),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonBox(width: double.infinity, height: 16),
                  SizedBox(height: 8),
                  SkeletonBox(width: 180, height: 12),
                  SizedBox(height: 8),
                  SkeletonBox(width: 120, height: 12),
                ],
              ),
            ),
            SizedBox(width: 12),
            SkeletonBox(width: 72, height: 18),
          ],
        ),
      ),
    );
  }
}

class SkeletonDialogContent extends StatelessWidget {
  const SkeletonDialogContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Row(
          children: [
            SkeletonBox(width: 90, height: 130),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonBox(width: double.infinity, height: 20),
                  SizedBox(height: 8),
                  SkeletonBox(width: 180, height: 14),
                  SizedBox(height: 8),
                  SkeletonBox(width: 140, height: 14),
                ],
              ),
            )
          ],
        ),
        SizedBox(height: 20),
        SkeletonBox(width: double.infinity, height: 14),
        SizedBox(height: 8),
        SkeletonBox(width: double.infinity, height: 14),
        SizedBox(height: 8),
        SkeletonBox(width: 220, height: 14),
        SizedBox(height: 20),
        SkeletonListCard(),
        SkeletonListCard(),
      ],
    );
  }
}
