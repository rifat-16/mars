import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/domain/inventory_item.dart';
import '../../state/inventory_provider.dart';
import '../widgets/main_app_bar.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  String selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InventoryProvider>().listenInventory();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<InventoryProvider>().state;

    return Scaffold(
      appBar: const MainAppBar(title: 'Inventory', icon: Icons.inventory_2),
      body: Builder(
        builder: (context) {
          if (state.isLoading || state.isIdle) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.isError) {
            return Center(
              child: Text(state.errorMessage ?? 'Failed to load inventory'),
            );
          }

          final items = state.data ?? <InventoryItem>[];
          final categories = <String>{'All'};
          for (final item in items) {
            if (item.category.isNotEmpty) categories.add(item.category);
          }

          final filteredItems = selectedCategory == 'All'
              ? items
              : items
                    .where((item) => item.category == selectedCategory)
                    .toList();

          if (filteredItems.isEmpty) {
            return const Center(child: Text('No inventory data found'));
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: DropdownButtonFormField<String>(
                  value: selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Filter by category',
                  ),
                  items: categories
                      .map(
                        (category) => DropdownMenuItem<String>(
                          value: category,
                          child: Text(category),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() {
                      selectedCategory = value;
                    });
                  },
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: filteredItems.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final item = filteredItems[index];
                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 5,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: ListTile(
                        title: Text(
                          item.productName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          'Category: ${item.category.isEmpty ? 'N/A' : item.category}',
                        ),
                        trailing: Chip(
                          label: Text(item.quantity.toString()),
                          backgroundColor: item.quantity <= 10
                              ? Colors.red.withValues(alpha: 0.15)
                              : Colors.green.withValues(alpha: 0.15),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
