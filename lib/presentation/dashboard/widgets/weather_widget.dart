import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

class WeatherWidget extends StatelessWidget {
  final Map<String, dynamic>? weatherData;
  final bool isLocationEnabled;
  final VoidCallback? onEnableLocation;

  const WeatherWidget({
    super.key,
    this.weatherData,
    required this.isLocationEnabled,
    this.onEnableLocation,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (!isLocationEnabled) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            CustomIconWidget(
              iconName: 'location_off',
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              size: 5.w,
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Weather Info',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  SizedBox(height: 0.5.h),
                  Text(
                    'Enable location for weather updates',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: onEnableLocation,
              child: Text(
                'Enable',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (weatherData == null) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.shadow.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            SizedBox(
              width: 5.w,
              height: 5.w,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor:
                    AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
              ),
            ),
            SizedBox(width: 3.w),
            Text(
              'Loading weather...',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _getWeatherGradientColor(weatherData!['condition'] as String)
                .withValues(alpha: 0.8),
            _getWeatherGradientColor(weatherData!['condition'] as String)
                .withValues(alpha: 0.6),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          CustomIconWidget(
            iconName: _getWeatherIcon(weatherData!['condition'] as String),
            color: Colors.white,
            size: 8.w,
          ),
          SizedBox(width: 4.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${weatherData!['temperature']}°F',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 0.5.h),
                Text(
                  weatherData!['condition'] as String,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
                SizedBox(height: 0.5.h),
                Text(
                  weatherData!['location'] as String,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CustomIconWidget(
                    iconName: 'air',
                    color: Colors.white.withValues(alpha: 0.8),
                    size: 3.w,
                  ),
                  SizedBox(width: 1.w),
                  Text(
                    '${weatherData!['windSpeed']} mph',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 1.h),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CustomIconWidget(
                    iconName: 'water_drop',
                    color: Colors.white.withValues(alpha: 0.8),
                    size: 3.w,
                  ),
                  SizedBox(width: 1.w),
                  Text(
                    '${weatherData!['humidity']}%',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getWeatherIcon(String condition) {
    switch (condition.toLowerCase()) {
      case 'sunny':
      case 'clear':
        return 'wb_sunny';
      case 'cloudy':
      case 'overcast':
        return 'cloud';
      case 'partly cloudy':
        return 'partly_cloudy_day';
      case 'rainy':
      case 'rain':
        return 'rainy';
      case 'snowy':
      case 'snow':
        return 'ac_unit';
      case 'stormy':
      case 'thunderstorm':
        return 'thunderstorm';
      default:
        return 'wb_cloudy';
    }
  }

  Color _getWeatherGradientColor(String condition) {
    switch (condition.toLowerCase()) {
      case 'sunny':
      case 'clear':
        return Colors.orange;
      case 'cloudy':
      case 'overcast':
        return Colors.grey;
      case 'partly cloudy':
        return Colors.blue;
      case 'rainy':
      case 'rain':
        return Colors.indigo;
      case 'snowy':
      case 'snow':
        return Colors.blueGrey;
      case 'stormy':
      case 'thunderstorm':
        return Colors.deepPurple;
      default:
        return Colors.blue;
    }
  }
}
