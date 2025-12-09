import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

enum CustomAppBarVariant {
  standard,
  centered,
  minimal,
  search,
  profile,
}

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final CustomAppBarVariant variant;
  final List<Widget>? actions;
  final Widget? leading;
  final bool automaticallyImplyLeading;
  final VoidCallback? onBackPressed;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double? elevation;
  final bool showNotificationBadge;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onSearchTap;
  final String? searchHint;
  final TextEditingController? searchController;
  final ValueChanged<String>? onSearchChanged;
  final bool isSearchActive;
  final VoidCallback? onSearchClose;
  final bool? centerTitle;
  final TextStyle? titleStyle;

  const CustomAppBar({
    super.key,
    this.title,
    this.variant = CustomAppBarVariant.standard,
    this.actions,
    this.leading,
    this.automaticallyImplyLeading = true,
    this.onBackPressed,
    this.backgroundColor,
    this.foregroundColor,
    this.elevation,
    this.showNotificationBadge = false,
    this.onNotificationTap,
    this.onSearchTap,
    this.searchHint = 'Search clients...',
    this.searchController,
    this.onSearchChanged,
    this.isSearchActive = false,
    this.onSearchClose,
    this.centerTitle,
    this.titleStyle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AppBar(
      title: _buildTitle(context),
      centerTitle: centerTitle ?? (variant == CustomAppBarVariant.centered),
      leading: _buildLeading(context),
      automaticallyImplyLeading: automaticallyImplyLeading,
      actions: _buildActions(context),
      backgroundColor: backgroundColor ?? theme.appBarTheme.backgroundColor,
      foregroundColor: foregroundColor ?? theme.appBarTheme.foregroundColor,
      elevation: elevation ?? theme.appBarTheme.elevation,
      shadowColor: theme.appBarTheme.shadowColor,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: theme.brightness == Brightness.light
            ? Brightness.dark
            : Brightness.light,
        statusBarBrightness: theme.brightness,
      ),
      titleTextStyle: titleStyle ?? _getTitleTextStyle(context),
      toolbarHeight:
          variant == CustomAppBarVariant.search && isSearchActive ? 72 : 56,
    );
  }

  Widget? _buildTitle(BuildContext context) {
    switch (variant) {
      case CustomAppBarVariant.search:
        if (isSearchActive) {
          return _buildSearchField(context);
        }
        return _buildStandardTitle(context);
      case CustomAppBarVariant.minimal:
        return null;
      case CustomAppBarVariant.profile:
        return _buildProfileTitle(context);
      default:
        return _buildStandardTitle(context);
    }
  }

  Widget? _buildStandardTitle(BuildContext context) {
    if (title == null) return null;

    return Text(
      title!,
      style: _getTitleTextStyle(context),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildProfileTitle(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title ?? 'Profile',
          style: _getTitleTextStyle(context),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          'Manage your sitter profile',
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color:
                Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchField(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: 40,
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: TextField(
        controller: searchController,
        onChanged: onSearchChanged,
        autofocus: true,
        style: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: theme.colorScheme.onSurface,
        ),
        decoration: InputDecoration(
          hintText: searchHint,
          hintStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
          prefixIcon: Icon(
            Icons.search,
            size: 20,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
          suffixIcon: searchController?.text.isNotEmpty == true
              ? IconButton(
                  icon: Icon(
                    Icons.clear,
                    size: 20,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  onPressed: () {
                    searchController?.clear();
                    onSearchChanged?.call('');
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
      ),
    );
  }

  Widget? _buildLeading(BuildContext context) {
    if (leading != null) return leading;

    if (variant == CustomAppBarVariant.search && isSearchActive) {
      return IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: onSearchClose ?? () => Navigator.of(context).pop(),
      );
    }

    if (automaticallyImplyLeading && Navigator.of(context).canPop()) {
      return IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: onBackPressed ?? () => Navigator.of(context).pop(),
      );
    }

    return null;
  }

  List<Widget>? _buildActions(BuildContext context) {
    if (variant == CustomAppBarVariant.search && isSearchActive) {
      return null;
    }

    List<Widget> defaultActions = [];

    // Add search action for search variant
    if (variant == CustomAppBarVariant.search && !isSearchActive) {
      defaultActions.add(
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: onSearchTap,
          tooltip: 'Search',
        ),
      );
    }

    // Add notification action for dashboard and client list
    if (_shouldShowNotifications(context)) {
      defaultActions.add(
        Stack(
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined),
              onPressed:
                  onNotificationTap ?? () => _navigateToNotifications(context),
              tooltip: 'Notifications',
            ),
            if (showNotificationBadge)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.error,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      );
    }

    // Add profile action for dashboard
    if (_shouldShowProfile(context)) {
      defaultActions.add(
        IconButton(
          icon: const Icon(Icons.account_circle_outlined),
          onPressed: () => _navigateToProfile(context),
          tooltip: 'Profile',
        ),
      );
    }

    // Combine with custom actions
    if (actions != null) {
      defaultActions.addAll(actions!);
    }

    return defaultActions.isNotEmpty ? defaultActions : null;
  }

  bool _shouldShowNotifications(BuildContext context) {
    final currentRoute = ModalRoute.of(context)?.settings.name;
    return currentRoute == '/dashboard' || currentRoute == '/client-list';
  }

  bool _shouldShowProfile(BuildContext context) {
    final currentRoute = ModalRoute.of(context)?.settings.name;
    return currentRoute == '/dashboard';
  }

  void _navigateToNotifications(BuildContext context) {
    // For now, show a snackbar. In a real app, navigate to notifications screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Notifications feature coming soon'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _navigateToProfile(BuildContext context) {
    Navigator.pushNamed(context, '/sitter-profile-setup');
  }

  TextStyle _getTitleTextStyle(BuildContext context) {
    final theme = Theme.of(context);

    switch (variant) {
      case CustomAppBarVariant.minimal:
        return GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w500,
          color: theme.colorScheme.onSurface,
        );
      case CustomAppBarVariant.profile:
        return GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.onSurface,
        );
      default:
        return GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.onSurface,
          letterSpacing: 0.15,
        );
    }
  }

  @override
  Size get preferredSize => Size.fromHeight(
        variant == CustomAppBarVariant.search && isSearchActive ? 72 : 56,
      );
}
