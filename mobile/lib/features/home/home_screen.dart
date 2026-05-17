import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:provider/provider.dart";

import "../../core/config/app_config.dart";
import "../../core/services/firestore_service.dart";
import "../../core/services/notification_service.dart";
import "../../core/services/triggers/emergency_trigger_coordinator.dart";
import "../../core/state/auth_provider.dart";
import "../../core/state/offline_provider.dart";
import "../../core/state/safety_provider.dart";
import "../../core/state/sos_provider.dart";
import "../../core/theme/lifeline_colors.dart";
import "../../shared/widgets/home/glow_sos_button.dart";
import "../../shared/widgets/home/home_info_card.dart";
import "../../shared/widgets/home/home_quick_action.dart";
import "../../shared/widgets/home/starry_background.dart";
import "../auth/login_screen.dart";
import "../disguise/fake_calculator_screen.dart";
import "../history/history_screen.dart";
import "../profile/profile_setup_screen.dart";
import "../settings/emergency_settings_screen.dart";
import "../sos/live_tracking_screen.dart";

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final NotificationService _notificationService = NotificationService();
  final FirestoreService _firestore = FirestoreService();

  int _contactCount = 0;
  int _navIndex = 0;

  @override
  void initState() {
    super.initState();
    _notificationService.initialize();
    if (AppConfig.firebaseReady) {
      EmergencyTriggerCoordinator.instance.arm();
      _loadContacts();
    }
  }

  Future<void> _loadContacts() async {
    try {
      final contacts = await _firestore.getContacts();
      if (mounted) setState(() => _contactCount = contacts.length);
    } catch (_) {}
  }

  void _onNavTap(int index) {
    if (index == _navIndex) return;
    setState(() => _navIndex = index);

    switch (index) {
      case 1:
        Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryScreen()));
      case 2:
        Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileSetupScreen()));
      case 3:
        Navigator.push(context, MaterialPageRoute(builder: (_) => const EmergencySettingsScreen()));
      default:
        break;
    }
    setState(() => _navIndex = 0);
  }

  @override
  Widget build(BuildContext context) {
    final sos = context.watch<SosProvider>();
    final offline = context.watch<OfflineProvider>();
    final auth = context.read<AuthProvider>();

    return Scaffold(
      backgroundColor: LifelineColors.background,
      body: StarryBackground(
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(auth),
              if (offline.initialized && (offline.isOffline || offline.isWeak || offline.pendingCount > 0))
                _buildOfflineBanner(offline),
              _buildSafetyBanner(context),
              if (sos.isActive) _buildEmergencyBanner(),
              Expanded(child: _buildMainContent(sos)),
              _buildInfoCards(),
              const SizedBox(height: 8),
              _buildBottomNav(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(AuthProvider auth) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 12, 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: LifelineColors.gold.withOpacity(0.4)),
              boxShadow: [
                BoxShadow(
                  color: LifelineColors.gold.withOpacity(0.15),
                  blurRadius: 12,
                ),
              ],
            ),
            child: const Icon(Icons.shield, color: LifelineColors.gold, size: 22),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Lifeline AI",
                  style: TextStyle(
                    color: LifelineColors.gold,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  "Volume 3× → Emergency help flow",
                  style: TextStyle(color: LifelineColors.textMuted, fontSize: 12),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const FakeCalculatorScreen()),
              );
            },
            icon: Icon(Icons.calculate_outlined, color: LifelineColors.gold.withOpacity(0.9)),
          ),
          IconButton(
            onPressed: () async {
              await EmergencyTriggerCoordinator.instance.disarm();
              await auth.signOut();
              if (!context.mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (_) => false,
              );
            },
            icon: Icon(Icons.logout, color: LifelineColors.textMuted.withOpacity(0.9)),
          ),
        ],
      ),
    );
  }

  Widget _buildOfflineBanner(OfflineProvider offline) {
    final color = offline.isOffline ? const Color(0xFF5D4037) : const Color(0xFF455A64);
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 4, 20, 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: color.withOpacity(0.85),
        border: Border.all(color: LifelineColors.gold.withOpacity(0.35)),
      ),
      child: Row(
        children: [
          Icon(
            offline.isOffline ? Icons.wifi_off : Icons.signal_cellular_alt_1_bar,
            color: LifelineColors.gold,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              offline.statusLabel,
              style: const TextStyle(color: Colors.white, fontSize: 12, height: 1.3),
            ),
          ),
          if (offline.pendingCount > 0)
            TextButton(
              onPressed: () => offline.syncNow(),
              child: const Text("Sync", style: TextStyle(color: LifelineColors.gold)),
            ),
        ],
      ),
    );
  }

  Widget _buildSafetyBanner(BuildContext context) {
    final safety = context.watch<SafetyProvider>();
    if (safety.riskScore == null) return const SizedBox.shrink();

    final high = safety.hasHighRisk;
    final color = high ? const Color(0xFF4A148C) : const Color(0xFF1B3A4B);
    final alert = safety.alerts.isNotEmpty ? safety.alerts.first : null;

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 4, 20, 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: color.withOpacity(0.9),
        border: Border.all(color: high ? Colors.orangeAccent : LifelineColors.gold.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          Icon(high ? Icons.warning_amber_rounded : Icons.shield_outlined,
              color: high ? Colors.orangeAccent : LifelineColors.gold, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Area risk: ${safety.riskLevel ?? "—"} (${safety.riskScore}/100)",
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                ),
                if (alert != null)
                  Text(
                    alert["message"] as String? ?? "",
                    style: const TextStyle(color: Colors.white70, fontSize: 11),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          if (safety.loading)
            const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
          else
            IconButton(
              icon: const Icon(Icons.refresh, color: LifelineColors.gold, size: 20),
              onPressed: () => safety.refreshLocationRisk(),
            ),
        ],
      ),
    );
  }

  Widget _buildEmergencyBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: const LinearGradient(
          colors: [Color(0xFFB71C1C), LifelineColors.emergency],
        ),
        boxShadow: [
          BoxShadow(
            color: LifelineColors.emergency.withOpacity(0.45),
            blurRadius: 16,
            spreadRadius: 1,
          ),
        ],
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.white, size: 20),
          SizedBox(width: 8),
          Text(
            "EMERGENCY ALERT ACTIVE",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent(SosProvider sos) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GlowSosButton(
          isBusy: sos.isBusy,
          isActive: sos.isActive,
          onPressed: () => sos.requestManualSos(),
        ),
        const SizedBox(height: 28),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              HomeQuickAction(
                icon: Icons.phone_in_talk,
                label: "Call 999",
                highlight: true,
                onTap: () {
                  HapticFeedback.mediumImpact();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Dial emergency services: 999"),
                      backgroundColor: LifelineColors.emergency,
                    ),
                  );
                },
              ),
              HomeQuickAction(
                icon: Icons.my_location,
                label: "Share Live",
                onTap: () async {
                  HapticFeedback.mediumImpact();
                  if (sos.isActive && sos.activeEventId != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => LiveTrackingScreen(eventId: sos.activeEventId!),
                      ),
                    );
                  } else {
                    await sos.requestManualSos();
                  }
                },
              ),
              HomeQuickAction(
                icon: Icons.phone_callback,
                label: "Fake Call",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const FakeCalculatorScreen()),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCards() {
    final contactLabel = _contactCount == 0
        ? "Add your trusted contacts"
        : "$_contactCount contact${_contactCount == 1 ? "" : "s"} added";

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Column(
        children: [
          HomeInfoCard(
            icon: Icons.people_alt_outlined,
            title: "Trusted Contacts",
            subtitle: contactLabel,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileSetupScreen()),
              ).then((_) => _loadContacts());
            },
          ),
          const SizedBox(height: 12),
          HomeInfoCard(
            icon: Icons.map_outlined,
            title: "Safe Zones",
            subtitle: "Configure protection areas",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const EmergencySettingsScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    const items = [
      (Icons.home_rounded, "Home"),
      (Icons.history_rounded, "History"),
      (Icons.person_rounded, "Profile"),
      (Icons.tune_rounded, "Settings"),
    ];

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: LifelineColors.card.withOpacity(0.95),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: LifelineColors.cardBorder),
        boxShadow: const [
          BoxShadow(color: Color(0x50000000), blurRadius: 24, offset: Offset(0, -4)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(items.length, (i) {
          final selected = _navIndex == i;
          final (icon, label) = items[i];
          return GestureDetector(
            onTap: () => _onNavTap(i),
            behavior: HitTestBehavior.opaque,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: selected ? LifelineColors.gold.withOpacity(0.15) : Colors.transparent,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    color: selected ? LifelineColors.gold : LifelineColors.textMuted,
                    size: 24,
                  ),
                  if (selected) ...[
                    const SizedBox(height: 2),
                    Text(
                      label,
                      style: const TextStyle(
                        color: LifelineColors.gold,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}
