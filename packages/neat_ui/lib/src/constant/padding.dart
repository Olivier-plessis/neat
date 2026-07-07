part of 'constant.dart';

extension PaddingExt on Widget {
  Widget paddedH(double value) {
    return Padding(
      padding: .symmetric(horizontal: value),
      child: this,
    );
  }

  Widget paddedV(double value) {
    return Padding(
      padding: .symmetric(vertical: value),
      child: this,
    );
  }

  Widget paddedHV(double horizontal, double vertical) {
    return Padding(
      padding: .symmetric(horizontal: horizontal, vertical: vertical),
      child: this,
    );
  }

  Widget paddedL(double value) {
    return Padding(
      padding: .only(left: value),
      child: this,
    );
  }

  Widget paddedR(double value) {
    return Padding(
      padding: .only(right: value),
      child: this,
    );
  }

  Widget paddedLR(double left, double right) {
    return Padding(
      padding: .only(left: left, right: right),
      child: this,
    );
  }

  Widget paddedT(double value) {
    return Padding(
      padding: .only(top: value),
      child: this,
    );
  }

  Widget paddedB(double value) {
    return Padding(
      padding: .only(bottom: value),
      child: this,
    );
  }

  Widget paddedTB(double top, double bottom) {
    return Padding(
      padding: .only(top: top, bottom: bottom),
      child: this,
    );
  }

  Widget paddedAll(double value) {
    return Padding(padding: .all(value), child: this);
  }

  Widget paddedLRTB({double left = 0, double right = 0, double top = 0, double bottom = 0}) {
    return Padding(
      padding: .only(left: left, right: right, top: top, bottom: bottom),
      child: this,
    );
  }
}
