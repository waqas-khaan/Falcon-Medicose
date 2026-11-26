import 'dart:ui';
import 'package:flutter/material.dart';
import '../utils/app_theme.dart';
import '../utils/formatters.dart';
import 'dashboard_screen.dart';
import 'pos_screen.dart';
import 'medicines_screen.dart';
import 'customers_screen.dart';
import 'purchases_screen.dart';
import 'inventory_alerts_screen.dart';
import 'suppliers_screen.dart';
import 'returns_screen.dart';
import 'invoices_screen.dart';
import 'expenses_screen.dart';
import 'reports_screen.dart';
import 'settings_screen.dart';
import 'backup_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0; // Mobile bottom nav index (0..3)
  int _desktopTabIndex = 0; // Desktop sidebar index (0..13)

  void _navigateToMobileTab(int index) {
    setState(() => _currentIndex = index);
  }

  void _navigateToDesktopTab(int index) {
    setState(() => _desktopTabIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    // 4 Mobile Primary Screens
    final List<Widget> mobileScreens = [
      DashboardScreen(
        onNavigateToPos: () => _navigateToMobileTab(1),
        isDesktop: false,
      ),
      const PosScreen(),
      const MedicinesScreen(),
      const CustomersScreen(),
    ];

    // Full 14-Module Desktop Suite
    final List<Widget> desktopScreens = [
      DashboardScreen(
        onNavigateToPos: () => _navigateToDesktopTab(1),
        onNavigateToTab: _navigateToDesktopTab,
        isDesktop: true,
      ),
      const PosScreen(),
      const InvoicesScreen(),
      const CustomersScreen(initialTabIndex: 0),
      const CustomersScreen(initialTabIndex: 1),
      const MedicinesScreen(),
      const PurchasesScreen(),
      const SuppliersScreen(),
      const InventoryAlertsScreen(),
      const ReturnsScreen(),
      const ExpensesScreen(),
      const ReportsScreen(),
      const SettingsScreen(),
      const BackupScreen(),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWideScreen = constraints.maxWidth >= 900;

        if (isWideScreen) {
          // Responsive Glassmorphic Desktop Layout with Permanent Sidebar & Header
          return Scaffold(
            backgroundColor: AppColors.background,
            body: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFFF8FAFC),
                    Color(0xFFF1F5F9),
                    Color(0xFFEFF6FF),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 260,
                    child: _buildAppDrawer(isPermanent: true),
                  ),
                  const VerticalDivider(
                    width: 1,
                    thickness: 1,
                    color: Color(0x33CBD5E1),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        _buildDesktopHeader(_desktopTabIndex),
                        Expanded(
                          child: IndexedStack(
                            index: _desktopTabIndex,
                            children: desktopScreens,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // Mobile / Small Screen Layout with Floating Frosted Glass Bar
        return Scaffold(
          extendBody: false,
          backgroundColor: AppColors.background,
          drawer: _buildAppDrawer(isPermanent: false),
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFFF8FAFC),
                  Color(0xFFF1F5F9),
                  Color(0xFFEFF6FF),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: IndexedStack(
              index: _currentIndex,
              children: mobileScreens,
            ),
          ),
          bottomNavigationBar: SafeArea(
            top: false,
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                    color: const Color(0x33CBD5E1), width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0F243A).withValues(alpha: 0.10),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildNavItem(0, Icons.dashboard_outlined,
                          Icons.dashboard_rounded, 'Dashboard'),
                      _buildNavItem(1, Icons.point_of_sale_outlined,
                          Icons.point_of_sale_rounded, 'POS Sale'),
                      _buildNavItem(2, Icons.medication_outlined,
                          Icons.medication_rounded, 'Medicines'),
                      _buildNavItem(3, Icons.people_outline_rounded,
                          Icons.people_rounded, 'Customers'),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDesktopHeader(int tabIndex) {
    const titles = [
      'Executive Dashboard',
      'Point of Sale (POS)',
      'Sales Invoices & Receipts',
      'Retail Customers & Udhaar',
      'Wholesale B2B Clients',
      'Medicine Catalog',
      'Purchases & Stock In',
      'Suppliers & Vendors',
      'Stock & Expiry Alerts',
      'Returns & Adjustments',
      'Daily Expense Tracking',
      'Financial Reports & P&L',
      'Store Settings',
      'Backup & Restore System',
    ];

    const subtitles = [
      'Real-time store telemetry, financials, and quick operations',
      'Instant counter billing, retail checkout, and wholesale orders',
      'Invoice history, payment status tracking, and thermal receipts',
      'Customer ledgers, credit tracking, and balance settlements',
      'B2B clients, bulk distribution pricing, and commercial accounts',
      'Inventory items, batch numbers, and price management',
      'Vendor stock receiving, replenishment, and purchase entries',
      'Supplier directory, balance tracking, and vendor ledgers',
      'Critical inventory alerts for low stock and expiring items',
      'Sales returns and supplier purchase return logs',
      'Daily store operational expenses and utilities ledger',
      'Comprehensive profit & loss, margins, and sales analysis',
      'Store details, receipt formatting, and defaults',
      'Database snapshot management and offline backups',
    ];

    final title =
        tabIndex < titles.length ? titles[tabIndex] : 'Falcon Medicose';
    final subtitle = tabIndex < subtitles.length
        ? subtitles[tabIndex]
        : 'Healthcare System';

    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.85),
        border: const Border(
            bottom: BorderSide(color: Color(0x33CBD5E1), width: 1)),
      ),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textPrimary,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              // Glass Date Pill
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.9), width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0F243A).withValues(alpha: 0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.calendar_today_rounded,
                        size: 13, color: AppColors.primaryLight),
                    const SizedBox(width: 7),
                    Text(
                      Formatters.formatDate(DateTime.now().toIso8601String()),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
      int index, IconData icon, IconData activeIcon, String label) {
    final isSelected = _currentIndex == index;
    return InkWell(
      onTap: () => _navigateToMobileTab(index),
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryLight.withValues(alpha: 0.16)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              color: isSelected ? AppColors.primaryLight : AppColors.textMuted,
              size: 21,
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.primaryLight,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAppDrawer({bool isPermanent = false}) {
    void handleTap(int targetIndex, Widget fallbackScreen) {
      if (isPermanent) {
        _navigateToDesktopTab(targetIndex);
      } else {
        Navigator.pop(context);
        if (targetIndex < 4) {
          _navigateToMobileTab(targetIndex);
        } else {
          Navigator.push(
              context, MaterialPageRoute(builder: (_) => fallbackScreen));
        }
      }
    }

    final content = SafeArea(
      child: Column(
        children: [
          // Branded Glass Executive Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
            decoration: const BoxDecoration(
              gradient: AppColors.headerGradient,
            ),
            child: const Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Falcon Medicose',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.3,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Pharmacy & POS Command Center',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Navigation Items List
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              children: [
                _sectionHeader('CORE OPERATIONS'),
                _drawerTile(
                  icon: Icons.dashboard_outlined,
                  iconColor: AppColors.primaryLight,
                  title: 'Executive Dashboard',
                  isSelected: isPermanent && _desktopTabIndex == 0,
                  onTap: () => handleTap(
                      0,
                      DashboardScreen(
                          onNavigateToPos: () => _navigateToMobileTab(1))),
                ),
                _drawerTile(
                  icon: Icons.point_of_sale_outlined,
                  iconColor: const Color(0xFF10B981),
                  title: 'New POS Sale',
                  isSelected: isPermanent && _desktopTabIndex == 1,
                  onTap: () => handleTap(1, const PosScreen()),
                ),
                _drawerTile(
                  icon: Icons.receipt_long_outlined,
                  iconColor: const Color(0xFF6366F1),
                  title: 'Invoices & Receipts',
                  isSelected: isPermanent && _desktopTabIndex == 2,
                  onTap: () => handleTap(2, const InvoicesScreen()),
                ),

                _sectionHeader('CUSTOMER ACCOUNTS'),
                _drawerTile(
                  icon: Icons.people_outline_rounded,
                  iconColor: const Color(0xFF0284C7),
                  title: 'Retail Customers & Udhaar',
                  isSelected: isPermanent && _desktopTabIndex == 3,
                  onTap: () => handleTap(
                      3, const CustomersScreen(initialTabIndex: 0)),
                ),
                _drawerTile(
                  icon: Icons.business_outlined,
                  iconColor: const Color(0xFF8B5CF6),
                  title: 'Wholesale B2B Clients',
                  isSelected: isPermanent && _desktopTabIndex == 4,
                  onTap: () => handleTap(
                      4, const CustomersScreen(initialTabIndex: 1)),
                ),

                _sectionHeader('INVENTORY & VENDORS'),
                _drawerTile(
                  icon: Icons.medication_outlined,
                  iconColor: const Color(0xFF14B8A6),
                  title: 'Medicine Catalog',
                  isSelected: isPermanent && _desktopTabIndex == 5,
                  onTap: () => handleTap(5, const MedicinesScreen()),
                ),
                _drawerTile(
                  icon: Icons.add_business_outlined,
                  iconColor: const Color(0xFF0EA5E9),
                  title: 'Purchases & Stock In',
                  isSelected: isPermanent && _desktopTabIndex == 6,
                  onTap: () => handleTap(6, const PurchasesScreen()),
                ),
                _drawerTile(
                  icon: Icons.local_shipping_outlined,
                  iconColor: const Color(0xFFF59E0B),
                  title: 'Suppliers & Vendors',
                  isSelected: isPermanent && _desktopTabIndex == 7,
                  onTap: () => handleTap(7, const SuppliersScreen()),
                ),
                _drawerTile(
                  icon: Icons.warning_amber_rounded,
                  iconColor: const Color(0xFFEF4444),
                  title: 'Stock & Expiry Alerts',
                  isSelected: isPermanent && _desktopTabIndex == 8,
                  onTap: () => handleTap(8, const InventoryAlertsScreen()),
                ),
                _drawerTile(
                  icon: Icons.assignment_return_outlined,
                  iconColor: const Color(0xFFEC4899),
                  title: 'Returns & Adjustments',
                  isSelected: isPermanent && _desktopTabIndex == 9,
                  onTap: () => handleTap(9, const ReturnsScreen()),
                ),

                _sectionHeader('FINANCE & SYSTEM'),
                _drawerTile(
                  icon: Icons.account_balance_wallet_outlined,
                  iconColor: const Color(0xFFF97316),
                  title: 'Daily Expenses',
                  isSelected: isPermanent && _desktopTabIndex == 10,
                  onTap: () => handleTap(10, const ExpensesScreen()),
                ),
                _drawerTile(
                  icon: Icons.analytics_outlined,
                  iconColor: const Color(0xFF059669),
                  title: 'Reports & P&L',
                  isSelected: isPermanent && _desktopTabIndex == 11,
                  onTap: () => handleTap(11, const ReportsScreen()),
                ),
                _drawerTile(
                  icon: Icons.settings_outlined,
                  iconColor: AppColors.textSecondary,
                  title: 'Store Settings',
                  isSelected: isPermanent && _desktopTabIndex == 12,
                  onTap: () => handleTap(12, const SettingsScreen()),
                ),
                _drawerTile(
                  icon: Icons.backup_outlined,
                  iconColor: AppColors.primaryLight,
                  title: 'Backup & Restore',
                  isSelected: isPermanent && _desktopTabIndex == 13,
                  onTap: () => handleTap(13, const BackupScreen()),
                ),
              ],
            ),
          ),

          // Footer with Direct Image
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: const BoxDecoration(
              color: Colors.white,
              border:
                  Border(top: BorderSide(color: Color(0x33CBD5E1), width: 1)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/images/falcon_logo.png',
                  height: 30,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Systems by Falcon Softwares',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                    letterSpacing: 0.2,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (isPermanent) {
      return Container(
        color: Colors.white.withValues(alpha: 0.95),
        child: content,
      );
    }

    return Drawer(
      backgroundColor: Colors.white,
      child: content,
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, top: 14, bottom: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: AppColors.textMuted,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _drawerTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required VoidCallback onTap,
    bool isSelected = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 1.5),
      decoration: BoxDecoration(
        color: isSelected
            ? AppColors.primaryLight.withValues(alpha: 0.18)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: isSelected
            ? Border.all(
                color: AppColors.primaryLight.withValues(alpha: 0.6), width: 1)
            : null,
      ),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        dense: true,
        leading: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primaryLight
                : iconColor.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon,
              color: isSelected ? Colors.white : iconColor, size: 17),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            fontSize: 12.5,
            color: isSelected ? AppColors.primaryLight : AppColors.textPrimary,
          ),
        ),
        trailing: isSelected
            ? const Icon(Icons.arrow_right_rounded,
                size: 20, color: AppColors.primaryLight)
            : const Icon(Icons.chevron_right,
                size: 15, color: Color(0x66CBD5E1)),
        onTap: onTap,
      ),
    );
  }
}
