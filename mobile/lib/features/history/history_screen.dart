import "package:flutter/material.dart";
import "package:intl/intl.dart";
import "package:provider/provider.dart";

import "../../core/state/sos_provider.dart";

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late Future<List<Map<String, dynamic>>> _historyFuture;

  @override
  void initState() {
    super.initState();
    _historyFuture = context.read<SosProvider>().loadHistory();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Emergency history")),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _historyFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Failed to load history: ${snapshot.error}"));
          }

          final items = snapshot.data ?? [];
          if (items.isEmpty) {
            return const Center(child: Text("No emergencies recorded yet."));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final item = items[index];
              final date = DateTime.tryParse(
                    item["triggeredAt"]?.toString() ?? "",
                  ) ??
                  DateTime.now();

              return Card(
                child: ListTile(
                  leading: Icon(
                    item["status"] == "active" ? Icons.warning_amber : Icons.check_circle,
                    color: item["status"] == "active" ? Colors.redAccent : Colors.green,
                  ),
                  title: Text("Status: ${item["status"] ?? "unknown"}"),
                  subtitle: Text(
                    "Triggered: ${DateFormat.yMMMd().add_jm().format(date)}\n"
                    "Location: ${item["latitude"]}, ${item["longitude"]}",
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
