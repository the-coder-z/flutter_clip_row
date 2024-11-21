library flutter_clip_row;

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class ClipRow extends MultiChildRenderObjectWidget {
  final bool suffix;
  final double spacing;
  const ClipRow._({
    super.key,
    required super.children,
    required this.suffix,
    required this.spacing,
  });

  static ClipRow build({
    Key? key,
    required List<Widget> children,
    Widget? suffix,
    double spacing = 0,
  }) {
    return ClipRow._(
      key: key,
      suffix: suffix != null,
      spacing: spacing,
      children: [
        ...children,
        if (suffix != null) suffix,
      ],
    );
  }

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _ClipRowRender(spacing: spacing, hasSuffix: suffix);
  }
}

class _ParentData extends ContainerBoxParentData<RenderBox> {}

class _ClipRowRender extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _ParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _ParentData> {
  final bool hasSuffix;
  final double spacing;
  _ClipRowRender({this.spacing = 0, this.hasSuffix = false});

  @override
  void setupParentData(covariant RenderObject child) {
    if (child.parentData is! _ParentData) {
      child.parentData = _ParentData();
    }
  }

  @override
  void performLayout() {
    if (childCount == 0 || childCount == 1 && hasSuffix) {
      size = Size(constraints.minWidth, constraints.minHeight);
      return;
    }

    var childrenWidth = constraints.maxWidth;
    var maxHeight = constraints.minHeight;
    if (hasSuffix) {
      // 先确定suffix的大小
      lastChild!.layout(const BoxConstraints(), parentUsesSize: true);
      childrenWidth = constraints.maxWidth - spacing - lastChild!.size.width;
      maxHeight = max(maxHeight, lastChild!.size.height);
    }

    RenderBox? child = firstChild;
    _ParentData parentData;
    var dx = 0.0;
    var outOfRange = false;
    while (child != null) {
      parentData = child.parentData as _ParentData;
      if (outOfRange) {
        if (hasSuffix && child == lastChild) {
          parentData.offset = Offset(dx, 0);
          dx += (child.size.width + spacing);
          break;
        }
        child.layout(
          const BoxConstraints(maxWidth: 0, maxHeight: 0),
          parentUsesSize: true,
        );
      } else {
        if (child == lastChild && hasSuffix) {
          // 不要展示suffix了
          child.layout(
            const BoxConstraints(maxWidth: 0, maxHeight: 0),
            parentUsesSize: true,
          );
          break;
        }
        child.layout(const BoxConstraints(), parentUsesSize: true);
        if (dx + child.size.width > childrenWidth) {
          // 已经不能完整的放下这个child了
          if (child == firstChild) {
            // 首个child必须展示
            child.layout(
              BoxConstraints(maxWidth: childrenWidth),
              parentUsesSize: true,
            );
            parentData.offset = Offset(dx, 0);
            dx += (child.size.width + spacing);
          } else {
            child.layout(
              const BoxConstraints(maxHeight: 0, maxWidth: 0),
              parentUsesSize: true,
            );
          }
          outOfRange = true;
        } else {
          parentData.offset = Offset(dx, 0);
          dx += (child.size.width + spacing);
        }
        maxHeight = max(maxHeight, child.size.height);
      }
      child = parentData.nextSibling;
    }
    child = firstChild;
    while (child != null) {
      parentData = child.parentData as _ParentData;
      parentData.offset = Offset(
        parentData.offset.dx,
        (maxHeight - child.size.height) * 0.5,
      );
      child = parentData.nextSibling;
    }
    maxHeight = min(constraints.maxHeight, maxHeight);
    var selfWidth = max(constraints.minWidth, dx - spacing);
    selfWidth = min(selfWidth, constraints.maxWidth);
    size = Size(selfWidth, maxHeight);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    defaultPaint(context, offset);
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    return defaultHitTestChildren(result, position: position);
  }
}
