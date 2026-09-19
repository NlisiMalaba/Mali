import 'package:flutter/material.dart';

enum AnalyticsTab {
  overview,
  spending,
  trends;

  String get label => switch (this) {
        overview => 'Overview',
        spending => 'Spending',
        trends => 'Trends',
      };

  Key get tabKey => Key('analytics-tab-$name');

  Key get panelKey => Key('analytics-panel-$name');
}
