import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_routes.dart';
import '../../models/domain/order_item.dart';
import '../../state/orders_provider.dart';
import '../../state/session_provider.dart';
import '../widgets/main_app_bar.dart';

class CreateOrderScreen extends StatefulWidget {
  const CreateOrderScreen({super.key});

  @override
  State<CreateOrderScreen> createState() => _CreateOrderScreenState();
}

class _CreateOrderScreenState extends State<CreateOrderScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _customerNameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();

  final List<_DraftOrderItem> _items = [_DraftOrderItem()];
  Map<String, String>? _selectedCustomer;

  bool _argsLoaded = false;
  bool _lockCustomer = false;
  bool _blockedTaggedEnrollment = false;
  String _blockedTaggedMessage = '';
  String _taggedEventId = '';
  String _taggedRegistrationId = '';
  String _taggedParticipantUid = '';
  String _selectedAssignmentId = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _hydrateInitialData();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_argsLoaded) return;
    _argsLoaded = true;

    final args = ModalRoute.of(context)?.settings.arguments;
    final map = args is Map<String, dynamic> ? args : <String, dynamic>{};

    _lockCustomer = map['lockCustomer'] == true;
    _taggedEventId = map['eventId']?.toString() ?? '';
    _taggedRegistrationId = map['eventRegistrationId']?.toString() ?? '';
    _taggedParticipantUid = map['eventParticipantUid']?.toString() ?? '';
    _selectedAssignmentId = _taggedRegistrationId;

    if (_lockCustomer) {
      _customerNameController.text = map['customerName']?.toString() ?? '';
      _phoneNumberController.text = map['phoneNumber']?.toString() ?? '';
      _addressController.text = map['address']?.toString() ?? '';
    }
  }

  Future<void> _hydrateInitialData() async {
    final session = context.read<SessionProvider>();
    final ordersProvider = context.read<OrdersProvider>();

    await ordersProvider.loadCreateOrderDependencies(
      role: session.role,
      currentUid: session.currentUser?.uid ?? '',
    );

    final options = ordersProvider.eventAssignmentOptions;
    if (_taggedRegistrationId.isNotEmpty) {
      final exists = options.any(
        (item) => item.registrationId == _taggedRegistrationId,
      );
      if (!exists) {
        _blockedTaggedEnrollment = true;
        _blockedTaggedMessage =
            'This enrollment billing is closed or not available for tagging.';
      }
    }

    final role = session.role;
    if (role != 'Owner' && role != 'Manager') {
      _customerNameController.text = session.currentUser?.fullName ?? '';
      _addressController.text = session.currentUser?.address ?? '';
      _phoneNumberController.text = session.currentUser?.phone ?? '';
    }

    if (mounted) {
      setState(() {});
    }
  }

  double _calculateTotal(Map<String, double> medicinePrices) {
    var total = 0.0;
    for (final item in _items) {
      if (item.product == null) continue;
      total += (medicinePrices[item.product!] ?? 0) * item.quantity;
    }
    return total;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_blockedTaggedEnrollment) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _blockedTaggedMessage.isEmpty
                ? 'Tagged enrollment is no longer available.'
                : _blockedTaggedMessage,
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final orderItems = _items
        .where((item) => item.product != null && item.product!.isNotEmpty)
        .map(
          (item) => OrderItem(product: item.product!, quantity: item.quantity),
        )
        .toList();

    if (orderItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one product.')),
      );
      return;
    }

    final success = await context.read<OrdersProvider>().createOrder(
      customerName: _customerNameController.text.trim(),
      address: _addressController.text.trim(),
      phoneNumber: _phoneNumberController.text.trim(),
      items: orderItems,
      eventId: _taggedEventId.isEmpty ? null : _taggedEventId,
      eventRegistrationId: _taggedRegistrationId.isEmpty
          ? null
          : _taggedRegistrationId,
      eventParticipantUid: _taggedParticipantUid.isEmpty
          ? null
          : _taggedParticipantUid,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Order created successfully'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pushReplacementNamed(context, AppRoutes.orders);
      return;
    }

    final rawMessage =
        context.read<OrdersProvider>().actionState.errorMessage ??
        'Failed to create order';
    final message = _friendlyOrderError(rawMessage);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  String _friendlyOrderError(String rawMessage) {
    if (rawMessage.contains('Billing is already closed')) {
      return 'এই enrollment এর billing closed. নতুন event-tagged order তৈরি করা যাবে না।';
    }
    if (rawMessage.contains('event enrollment was not found')) {
      return 'Selected event enrollment পাওয়া যায়নি। নতুন enrollment select করুন।';
    }
    if (rawMessage.contains('does not match selected event')) {
      return 'Selected enrollment এবং event মিলছে না।';
    }
    return rawMessage;
  }

  @override
  void dispose() {
    _customerNameController.dispose();
    _addressController.dispose();
    _phoneNumberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionProvider>();
    final ordersProvider = context.watch<OrdersProvider>();

    final medicinePrices = ordersProvider.medicinePrices;
    final products = medicinePrices.keys.toList()..sort();
    final previousCustomers = ordersProvider.previousCustomers;
    final isPrivileged = session.role == 'Owner' || session.role == 'Manager';
    final total = _calculateTotal(medicinePrices);
    final assignmentOptions = ordersProvider.eventAssignmentOptions;
    final hasSelectedAssignment = assignmentOptions.any(
      (item) => item.registrationId == _selectedAssignmentId,
    );

    return Scaffold(
      appBar: const MainAppBar(title: 'Invoice', icon: Icons.text_snippet),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Customer Information',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (_taggedRegistrationId.isNotEmpty) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFC8E6C9)),
                          ),
                          child: const Text(
                            'Tagged to enrollment. এই order deliver হলে event হিসাব auto update হবে.',
                            style: TextStyle(
                              color: Color(0xFF1B5E20),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      if (isPrivileged) ...[
                        DropdownButtonFormField<Map<String, String>>(
                          isExpanded: true,
                          value: _selectedCustomer,
                          onChanged: _lockCustomer
                              ? null
                              : (value) {
                                  setState(() {
                                    _selectedCustomer = value;
                                    if (value != null) {
                                      _customerNameController.text =
                                          value['name'] ?? '';
                                      _addressController.text =
                                          value['address'] ?? '';
                                      _phoneNumberController.text =
                                          value['phone'] ?? '';
                                    }
                                  });
                                },
                          items: previousCustomers
                              .map(
                                (
                                  customer,
                                ) => DropdownMenuItem<Map<String, String>>(
                                  value: customer,
                                  child: Text(
                                    '${customer['name']} (${customer['phone']})',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                              .toList(),
                          decoration: const InputDecoration(
                            labelText: 'Select Previous Customer',
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      TextFormField(
                        controller: _customerNameController,
                        readOnly: _lockCustomer,
                        decoration: const InputDecoration(labelText: 'Name'),
                        validator: (value) => value == null || value.isEmpty
                            ? 'Please enter customer name'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _addressController,
                        readOnly: _lockCustomer,
                        decoration: const InputDecoration(labelText: 'Address'),
                        validator: (value) => value == null || value.isEmpty
                            ? 'Please enter address'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _phoneNumberController,
                        readOnly: _lockCustomer,
                        decoration: const InputDecoration(
                          labelText: 'Phone Number',
                        ),
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter phone number';
                          }
                          if (value.length < 10) {
                            return 'Please enter valid phone number';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (!_lockCustomer)
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Event Assignment (Optional)',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          isExpanded: true,
                          value:
                              !hasSelectedAssignment ||
                                  _selectedAssignmentId.isEmpty
                              ? null
                              : _selectedAssignmentId,
                          items: assignmentOptions
                              .map(
                                (option) => DropdownMenuItem<String>(
                                  value: option.registrationId,
                                  child: Text(
                                    '${option.eventTitle} • ${option.participantName} (${option.participantPhone})',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            if (value == null || value.isEmpty) {
                              setState(() {
                                _selectedAssignmentId = '';
                                _taggedEventId = '';
                                _taggedRegistrationId = '';
                                _taggedParticipantUid = '';
                              });
                              return;
                            }

                            final selected = assignmentOptions.where(
                              (item) => item.registrationId == value,
                            );
                            if (selected.isEmpty) return;
                            final option = selected.first;
                            setState(() {
                              _selectedAssignmentId = option.registrationId;
                              _taggedEventId = option.eventId;
                              _taggedRegistrationId = option.registrationId;
                              _taggedParticipantUid = option.participantUid;
                              _customerNameController.text =
                                  option.participantName;
                              _addressController.text =
                                  option.participantAddress;
                              _phoneNumberController.text =
                                  option.participantPhone;
                            });
                          },
                          decoration: const InputDecoration(
                            labelText: 'Attach to event enrollment',
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (_taggedRegistrationId.isNotEmpty)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F5E9),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: const Color(0xFFC8E6C9),
                              ),
                            ),
                            child: const Text(
                              'Event-tagged order: delivered হলে medicine issued amount auto update হবে.',
                              style: TextStyle(
                                color: Color(0xFF1B5E20),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        if (_blockedTaggedEnrollment)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              _blockedTaggedMessage,
                              style: const TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        if (assignmentOptions.isEmpty)
                          const Padding(
                            padding: EdgeInsets.only(top: 8),
                            child: Text(
                              'No open enrollments available for event tagging.',
                              style: TextStyle(
                                color: Color(0xFF546E5A),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Order Items',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      for (var i = 0; i < _items.length; i++)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 5,
                                child: DropdownButtonFormField<String>(
                                  isExpanded: true,
                                  value: _items[i].product,
                                  decoration: const InputDecoration(
                                    labelText: 'Product',
                                  ),
                                  items: products
                                      .map(
                                        (name) => DropdownMenuItem<String>(
                                          value: name,
                                          child: Text(
                                            name,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      _items[i].product = value;
                                    });
                                  },
                                  validator: (value) =>
                                      value == null ? 'Select' : null,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                flex: 2,
                                child: TextFormField(
                                  initialValue: _items[i].quantity.toString(),
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    labelText: 'Qty',
                                  ),
                                  onChanged: (value) {
                                    final parsed = int.tryParse(value);
                                    setState(() {
                                      _items[i].quantity =
                                          (parsed == null || parsed <= 0)
                                          ? 1
                                          : parsed;
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                onPressed: _items.length == 1
                                    ? null
                                    : () {
                                        setState(() {
                                          _items.removeAt(i);
                                        });
                                      },
                                icon: const Icon(Icons.delete_outline),
                              ),
                            ],
                          ),
                        ),
                      TextButton.icon(
                        onPressed: () {
                          setState(() {
                            _items.add(_DraftOrderItem());
                          });
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Add Item'),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Total: ${total.toStringAsFixed(2)} TK',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              ElevatedButton(
                onPressed: ordersProvider.actionState.isLoading
                    ? null
                    : _submit,
                child: ordersProvider.actionState.isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Create Order'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DraftOrderItem {
  String? product;
  int quantity = 1;
}
