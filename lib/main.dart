import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'dart:math' as math;

void main() {
  runApp(
    const MyApp(),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        home: Scaffold(
      appBar: AppBar(
        title: const Text('2D Scrolling'),
      ),
      body: TwoDimensionalGridView(
        diagonalDragBehavior: DiagonalDragBehavior.free,
        delegate: TwoDimensionalChildBuilderDelegate(
          maxXIndex: 9,
          maxYIndex: 9,
          builder: (
            context,
            ChildVicinity vicinity,
          ) {
            return Container(
              color: vicinity.xIndex.isEven && vicinity.yIndex.isEven
                  ? Colors.amber[50]
                  : (vicinity.yIndex.isOdd && vicinity.yIndex.isOdd)
                      ? Colors.purpleAccent[50]
                      : null,
              height: 200,
              width: 200,
              child: Text(
                'Row ${vicinity.yIndex} : Column ${vicinity.xIndex}',
              ),
            );
          },
        ),
      ),
    ));
  }
}

class TwoDimensionalGridView extends TwoDimensionalScrollView {
  const TwoDimensionalGridView({
    super.key,
    super.primary,
    super.mainAxis = Axis.vertical,
    super.cacheExtent,
    super.diagonalDragBehavior,
    super.verticalDetails = const ScrollableDetails.vertical(),
    super.horizontalDetails = const ScrollableDetails.horizontal(),
    super.dragStartBehavior = DragStartBehavior.start,
    super.keyboardDismissBehavior = ScrollViewKeyboardDismissBehavior.manual,
    super.clipBehavior = Clip.hardEdge,
    required TwoDimensionalChildBuilderDelegate delegate,
  }) : super(
          delegate: delegate,
        );

  @override
  Widget buildViewport(BuildContext context, ViewportOffset verticalOffset,
      ViewportOffset horizontalOffset) {
    return TwoDimensionalGridViewport(
      verticalOffset: verticalOffset,
      verticalAxisDirection: verticalDetails.direction,
      horizontalOffset: horizontalOffset,
      horizontalAxisDirection: horizontalDetails.direction,
      delegate: delegate as TwoDimensionalChildBuilderDelegate,
      mainAxis: mainAxis,
      cacheExtent: cacheExtent,
      clipBehavior: clipBehavior,
    );
  }
}

class TwoDimensionalGridViewport extends TwoDimensionalViewport {
  const TwoDimensionalGridViewport({
    super.key,
    required super.verticalOffset,
    required super.verticalAxisDirection,
    required super.horizontalOffset,
    required super.horizontalAxisDirection,
    required TwoDimensionalChildBuilderDelegate super.delegate,
    required super.mainAxis,
    super.cacheExtent,
    super.clipBehavior,
  });

  @override
  RenderTwoDimensionalGridViewport createRenderObject(BuildContext context) {
    return RenderTwoDimensionalGridViewport(
      horizontalOffset: horizontalOffset,
      horizontalAxisDirection: horizontalAxisDirection,
      verticalOffset: verticalOffset,
      verticalAxisDirection: verticalAxisDirection,
      delegate: delegate as TwoDimensionalChildBuilderDelegate,
      mainAxis: mainAxis,
      cacheExtent: cacheExtent,
      clipBehavior: clipBehavior,
      childManager: context as TwoDimensionalChildManager,
    );
  }

  @override
  void updateRenderObject(BuildContext context,
      covariant RenderTwoDimensionalGridViewport renderObject) {
    renderObject
      ..horizontalOffset = horizontalOffset
      ..horizontalAxisDirection = horizontalAxisDirection
      ..verticalOffset = verticalOffset
      ..verticalAxisDirection = verticalAxisDirection
      ..mainAxis = mainAxis
      ..delegate = delegate
      ..cacheExtent = cacheExtent
      ..clipBehavior = clipBehavior;
  }
}

class RenderTwoDimensionalGridViewport extends RenderTwoDimensionalViewport {
  RenderTwoDimensionalGridViewport({
    required super.horizontalOffset,
    required super.horizontalAxisDirection,
    required super.verticalOffset,
    required super.verticalAxisDirection,
    required TwoDimensionalChildBuilderDelegate delegate,
    required super.mainAxis,
    required super.childManager,
    super.cacheExtent,
    super.clipBehavior = Clip.hardEdge,
  }) : super(
          delegate: delegate,
        );

  @override
  void layoutChildSequence() {
    final double horizontalPixels = horizontalOffset.pixels;
    final double verticalPixels = verticalOffset.pixels;
    final double viewportWidth = viewportDimension.width + cacheExtent;
    final double viewportHeight = viewportDimension.height + cacheExtent;

    final TwoDimensionalChildBuilderDelegate builderDelegate =
        delegate as TwoDimensionalChildBuilderDelegate;

    final int maxRowIndex = builderDelegate.maxYIndex!;
    final int maxColumnIndex = builderDelegate.maxXIndex!;

    final int leadingColumn = math.max(
      (horizontalPixels / 200).floor(),
      0,
    );
    final int leadingRow = math.max(
      (verticalPixels / 200).floor(),
      0,
    );

    final int trailingColumn = math.min(
      ((horizontalPixels + viewportWidth) / 200).ceil(),
      maxColumnIndex,
    );
    final int trailingRow = math.min(
      ((verticalPixels + viewportHeight) / 200).ceil(),
      maxRowIndex, 
    );

    double xLayoutOffset = (leadingColumn * 200) - horizontalOffset.pixels;
    for (int column = leadingColumn; column < trailingColumn; column++) {
      double yLayoutOffset = (leadingRow * 200) - verticalOffset.pixels;
      for (int row = leadingRow; row <= trailingRow; row++) {
        final ChildVicinity vicinity =
            ChildVicinity(xIndex: column, yIndex: row);

        final RenderBox child = buildOrObtainChildFor(vicinity)!;
        child.layout(
          constraints.loosen(),
        );

        parentDataOf(child).layoutOffset = Offset(xLayoutOffset, yLayoutOffset);

        yLayoutOffset += 200;
      }
      xLayoutOffset += 200;
    }

    final double verticalExtent = 200 * (maxRowIndex + 1);
    verticalOffset.applyContentDimensions(
      0.0,
      (verticalExtent - viewportDimension.height).clamp(
        0.0,
        double.infinity,
      ),
    );

    final double horizontalExtent = 200 * (maxColumnIndex + 1);

    horizontalOffset.applyContentDimensions(
      0.0,
      (horizontalExtent - viewportDimension.width).clamp(
        0.0,
        double.infinity,
      ),
    );
  }
}
