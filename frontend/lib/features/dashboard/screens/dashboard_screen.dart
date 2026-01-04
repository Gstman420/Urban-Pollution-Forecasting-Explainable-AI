import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/api/prediction_api.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic>? data;
  bool isLoading = true;
  bool hasError = false;

  final List<String> regions = [
    'High Pollution Area',
    'Windy Area',
    'Rainy Area',
    'Normal Urban Area',
    'Seasonal Variation Area',
  ];

  String selectedRegion = 'Rainy Area';
  DateTime selectedDate = DateTime.now();

  String get formattedDate => DateFormat('yyyy-MM-dd').format(selectedDate);

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    try {
      final result = await PredictionApi.fetchPrediction(
        location: selectedRegion,
        date: formattedDate,
      );

      setState(() {
        data = result;
        isLoading = false;
        hasError = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        hasError = true;
        data = null;
      });
    }
  }

  // ================= UI =================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 16),
                  _buildRegionDropdown(),
                  const SizedBox(height: 16),
                  _buildDatePicker(),
                  const SizedBox(height: 28),
                  if (hasError)
                    _buildErrorCard()
                  else if (data != null)
                    ..._buildContent(),
                ],
              ),
            ),
            if (isLoading)
              const Center(
                child: CircularProgressIndicator(
                  color: AppColors.accentTeal,
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ================= HEADER =================

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          selectedRegion,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          formattedDate,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  // ================= INPUTS =================

  Widget _buildRegionDropdown() {
    return DropdownButtonFormField<String>(
      value: selectedRegion,
      dropdownColor: AppColors.bgSecondary,
      decoration: const InputDecoration(
        labelText: 'Select Region Type',
        border: OutlineInputBorder(),
      ),
      items: regions
          .map((r) => DropdownMenuItem(value: r, child: Text(r)))
          .toList(),
      onChanged: (value) {
        if (value == null) return;
        setState(() {
          selectedRegion = value;
          isLoading = true;
          data = null;
        });
        loadData();
      },
    );
  }

  Widget _buildDatePicker() {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: selectedDate,
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
        );
        if (picked != null) {
          setState(() {
            selectedDate = picked;
            isLoading = true;
            data = null;
          });
          loadData();
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.bgSecondary,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.textHint),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              formattedDate,
              style: const TextStyle(color: AppColors.textPrimary),
            ),
            const Icon(
              Icons.calendar_today,
              color: AppColors.textSecondary,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  // ================= CONTENT =================

  List<Widget> _buildContent() {
    return [
      _buildForecastCard(),
      const SizedBox(height: 28),
      _buildTrendChart(),
      const SizedBox(height: 28),
      _buildFactorsChart(),
      const SizedBox(height: 28),
      _buildInsightCard(),
    ];
  }

  // ================= FORECAST =================

  Widget _buildForecastCard() {
    final double value = _asDouble(data?['predicted_pollution']);
    final String category = _categoryFromValue(value);
    final Color color = _colorFromCategory(category);
    final double confidence = _asDouble(data?['confidence_r2']) * 100;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [
            AppColors.bgCard.withOpacity(0.9),
            AppColors.bgSecondary.withOpacity(0.95),
          ],
        ),
        boxShadow: [
          BoxShadow(color: color.withOpacity(0.35), blurRadius: 25),
        ],
      ),
      child: Row(
        children: [
          // LEFT SIDE (UNCHANGED)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Air Quality Forecast',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '${value.toStringAsFixed(1)} AQI',
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Forecasted for $formattedDate • Area Type: $selectedRegion',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      size: 16,
                      color: AppColors.accentTeal,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Prediction Confidence: ${confidence.toStringAsFixed(0)}%',
                      style: const TextStyle(
                        color: AppColors.accentTeal,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // RIGHT SIDE — ✅ ADDITION ONLY
          SizedBox(
            width: 140,
            height: 140,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SfRadialGauge(
                  axes: [
                    RadialAxis(
                      minimum: 0,
                      maximum: 300,
                      startAngle: 180,
                      endAngle: 0,
                      showTicks: false,
                      showLabels: false,
                      axisLineStyle: const AxisLineStyle(
                        thickness: 0.15,
                        thicknessUnit: GaugeSizeUnit.factor,
                        color: AppColors.bgPrimary,
                      ),
                      pointers: [
                        RangePointer(
                          value: value.clamp(0, 300),
                          width: 0.15,
                          sizeUnit: GaugeSizeUnit.factor,
                          cornerStyle: CornerStyle.bothCurve,
                          color: color,
                        ),
                      ],
                    ),
                  ],
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      value.toStringAsFixed(0),
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    const Text(
                      'µg/m³',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      category,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================= TREND GRAPH =================

  Widget _buildTrendChart() {
    final List trend = data?['trend_data'] ?? [];
    final List limitedTrend =
        trend.length > 5 ? trend.sublist(trend.length - 5) : trend;

    const labels = ['Day 1', 'Day 2', 'Day 3', 'Day 4', 'Today'];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: SizedBox(
        height: 220,
        child: LineChart(
          LineChartData(
            gridData: FlGridData(show: false),
            borderData: FlBorderData(show: false),
            minX: 0,
            maxX: 4,
            minY: 0,
            maxY: 300,
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles:
                  AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, _) {
                    if (value % 1 != 0) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        labels[value.toInt()],
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            lineBarsData: [
              LineChartBarData(
                isCurved: true,
                barWidth: 3,
                dotData: FlDotData(show: true),
                gradient: const LinearGradient(
                  colors: [AppColors.accentCyan, AppColors.accentBlue],
                ),
                spots: List.generate(
                  limitedTrend.length,
                  (i) => FlSpot(
                    i.toDouble(),
                    _asDouble(limitedTrend[i]['value']),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ================= FACTORS =================

  Widget _buildFactorsChart() {
    final List factors = data?['factors'] ?? [];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Key Influencing Factors',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          ...factors.map((f) {
            final String name = f['name'] ?? '';
            final double impact = _normalize(_asDouble(f['impact']));
            final String label = impact >= 0.66
                ? 'High Influence'
                : impact >= 0.33
                    ? 'Moderate Influence'
                    : 'Low Influence';

            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _factorIcon(name),
                        size: 18,
                        color: AppColors.accentTeal,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          name,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      Text(
                        label,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: impact,
                    minHeight: 8,
                    backgroundColor: AppColors.bgCard,
                    valueColor: const AlwaysStoppedAnimation(
                      AppColors.accentTeal,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ================= AI INSIGHT =================

  Widget _buildInsightCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'AI Insight Summary',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            data?['explanation'] ?? '',
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // ================= HELPERS =================

  double _asDouble(dynamic v) {
    if (v is num) return v.toDouble();
    return 0.0;
  }

  double _normalize(double v) {
    if (v < 0) return 0;
    if (v > 1) return 1;
    return v;
  }

  String _categoryFromValue(double v) {
    if (v < 50) return 'Good';
    if (v < 100) return 'Moderate';
    if (v < 150) return 'Unhealthy';
    return 'Severe';
  }

  Color _colorFromCategory(String c) {
    switch (c) {
      case 'Good':
        return AppColors.aqiGood;
      case 'Moderate':
        return AppColors.aqiModerate;
      case 'Unhealthy':
        return AppColors.aqiUnhealthy;
      default:
        return AppColors.aqiSevere;
    }
  }

  IconData _factorIcon(String name) {
    final n = name.toLowerCase();
    if (n.contains('wind')) return Icons.air;
    if (n.contains('rain')) return Icons.water_drop;
    if (n.contains('pressure')) return Icons.speed;
    return Icons.insights;
  }

  Widget _buildErrorCard() {
    return const Text(
      'Failed to load data',
      style: TextStyle(color: Colors.red),
    );
  }
}
