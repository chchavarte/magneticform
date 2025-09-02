/// Grid system and magnetic snapping constants
class GridConstants {
  // Private constructor to prevent instantiation
  GridConstants._();

  // Grid System
  static const double cardHeight = 70.0;
  static const int maxRows = 12;
  static const int totalColumns = 6;
  static const double snapThreshold = 30.0;
  static const double fieldGap = 4.0;

  // Magnetic Card Widths (based on 6-column grid)
  static const List<double> cardWidths = [
    2 / 6, // 2 columns (1/3 width)
    3 / 6, // 3 columns (1/2 width)
    4 / 6, // 4 columns (2/3 width)
    6 / 6, // 6 columns (full width)
  ];

  // Column calculations
  static const double columnWidth = 1.0 / totalColumns;

  // Row height calculations
  static double getRowY(int row) => row * cardHeight;

  // Column position calculations
  static double getColumnX(int column) => column * columnWidth;

  // Width to column span mapping
  static int getColumnSpan(double width) {
    if (width <= 2 / 6 + 0.001) return 2; // 2/6 width = 2 columns
    if (width <= 3 / 6 + 0.001) return 3; // 3/6 width = 3 columns
    if (width <= 4 / 6 + 0.001) return 4; // 4/6 width = 4 columns
    return 6; // 6/6 width = 6 columns (full row)
  }
}