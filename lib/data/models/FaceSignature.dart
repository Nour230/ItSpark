import 'dart:math';
import 'dart:ui';

class FaceSignature {
  final List<Point> points;
  final List<double> vectors;
  final Map<String, double> classifications;
  final Rect boundingBox;

  FaceSignature({
    required this.points,
    required this.vectors,
    required this.classifications,
    required this.boundingBox,
  });

  @override
  String toString() {
    return 'FaceSignature(points: ${points.length}, vectors: ${vectors.length})';
  }
}
