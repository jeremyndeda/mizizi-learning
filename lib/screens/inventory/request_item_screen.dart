import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../core/models/item_request.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/firestore_service.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/custom_text_field.dart';

class RequestItemScreen extends StatefulWidget {
  const RequestItemScreen({super.key});

  @override
  _RequestItemScreenState createState() => _RequestItemScreenState();
}

class _RequestItemScreenState extends State<RequestItemScreen> {
  final _itemNameController = TextEditingController();
  final _quantityController = TextEditingController();
  final _purposeController = TextEditingController();
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();

  List<String> _inventoryItemNames = [];
  List<ItemRequest> _userRequests = [];
  bool _isLoading = false;
  bool _isLoadingRequests = false;

  @override
  void initState() {
    super.initState();
    _loadInventoryItemNames();
    _loadUserRequests();
  }

  Future<void> _loadInventoryItemNames() async {
    setState(() => _isLoading = true);
    try {
      final items = await _firestoreService.getAllInventoryItemNames();
      setState(() {
        _inventoryItemNames = items;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load inventory items: $e')),
      );
    }
  }

  Future<void> _loadUserRequests() async {
    setState(() => _isLoadingRequests = true);
    try {
      _firestoreService
          .streamFilteredItemRequests(
            requesterId: _authService.currentUser!.uid,
          )
          .listen((requests) {
            setState(() {
              _userRequests = requests;
              _isLoadingRequests = false;
            });
          });
    } catch (e) {
      setState(() => _isLoadingRequests = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load requests: $e')));
    }
  }

  Future<void> _requestItem() async {
    final itemName = _itemNameController.text.trim();
    final quantity = int.tryParse(_quantityController.text.trim()) ?? 0;
    final purpose = _purposeController.text.trim();

    if (itemName.isEmpty || quantity <= 0 || purpose.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields with valid data')),
      );
      return;
    }

    setState(() => _isLoading = true);
    final request = ItemRequest(
      id: const Uuid().v4(),
      itemId: '',
      itemName: itemName,
      quantity: quantity,
      requesterId: _authService.currentUser!.uid,
      purpose: purpose,
      createdAt: DateTime.now(),
    );

    try {
      await _firestoreService.addItemRequest(request);
      _clearForm();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Item request submitted')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to submit request: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _editRequest(ItemRequest request) async {
    final editItemNameController = TextEditingController(
      text: request.itemName,
    );
    final editQuantityController = TextEditingController(
      text: request.quantity.toString(),
    );
    final editPurposeController = TextEditingController(text: request.purpose);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Edit Request',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RawAutocomplete<String>(
                  textEditingController: editItemNameController,
                  focusNode: FocusNode(),
                  optionsBuilder: (TextEditingValue textEditingValue) {
                    if (textEditingValue.text.isEmpty) {
                      return const Iterable<String>.empty();
                    }
                    return _inventoryItemNames.where(
                      (item) => item.toLowerCase().contains(
                        textEditingValue.text.toLowerCase(),
                      ),
                    );
                  },
                  onSelected: (String selection) {
                    editItemNameController.text = selection;
                  },
                  fieldViewBuilder: (
                    BuildContext context,
                    TextEditingController controller,
                    FocusNode focusNode,
                    VoidCallback onFieldSubmitted,
                  ) {
                    return CustomTextField(
                      controller: controller,
                      labelText: 'Item Name',
                      focusNode: focusNode,
                    );
                  },
                  optionsViewBuilder: (
                    BuildContext context,
                    AutocompleteOnSelected<String> onSelected,
                    Iterable<String> options,
                  ) {
                    return Align(
                      alignment: Alignment.topLeft,
                      child: Material(
                        elevation: 4,
                        borderRadius: BorderRadius.circular(12),
                        color: Theme.of(context).cardColor,
                        child: SizedBox(
                          width: MediaQuery.of(context).size.width - 64,
                          child: ListView.separated(
                            padding: EdgeInsets.zero,
                            shrinkWrap: true,
                            itemCount: options.length,
                            separatorBuilder:
                                (_, __) => const Divider(height: 1),
                            itemBuilder: (BuildContext context, int index) {
                              final option = options.elementAt(index);
                              return InkWell(
                                onTap: () => onSelected(option),
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12.0,
                                    horizontal: 16.0,
                                  ),
                                  child: Text(
                                    option,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: editQuantityController,
                  labelText: 'Quantity',
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: editPurposeController,
                  labelText: 'Purpose',
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ),
            TextButton(
              onPressed: () async {
                final itemName = editItemNameController.text.trim();
                final quantity =
                    int.tryParse(editQuantityController.text.trim()) ?? 0;
                final purpose = editPurposeController.text.trim();

                if (itemName.isEmpty || quantity <= 0 || purpose.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please fill all fields with valid data'),
                    ),
                  );
                  return;
                }

                final updatedRequest = ItemRequest(
                  id: request.id,
                  itemId: request.itemId,
                  itemName: itemName,
                  quantity: quantity,
                  requesterId: request.requesterId,
                  status: request.status,
                  purpose: purpose,
                  reason: request.reason,
                  createdAt: request.createdAt,
                );

                try {
                  await _firestoreService.updateItemRequestStatus(
                    updatedRequest.id,
                    updatedRequest.status,
                    reason: updatedRequest.reason,
                    itemId: updatedRequest.itemId,
                  );
                  await _firestoreService.addItemRequest(
                    updatedRequest,
                  ); // Update by overwriting
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Request updated')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to update request: $e')),
                  );
                }
              },
              child: const Text(
                'Save',
                style: TextStyle(fontSize: 16, color: Colors.blue),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteRequest(String requestId) async {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Delete Request',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          content: const Text(
            'Are you sure you want to delete this request?',
            style: TextStyle(fontSize: 16, color: Colors.black54),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ),
            TextButton(
              onPressed: () async {
                try {
                  await _firestoreService.deleteItemRequest(requestId);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Request deleted')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to delete request: $e')),
                  );
                }
              },
              child: const Text(
                'Delete',
                style: TextStyle(fontSize: 16, color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  void _clearForm() {
    _itemNameController.clear();
    _quantityController.clear();
    _purposeController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Request Item',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        elevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            RawAutocomplete<String>(
                              textEditingController: _itemNameController,
                              focusNode: FocusNode(),
                              optionsBuilder: (
                                TextEditingValue textEditingValue,
                              ) {
                                if (textEditingValue.text.isEmpty) {
                                  return const Iterable<String>.empty();
                                }
                                return _inventoryItemNames.where(
                                  (item) => item.toLowerCase().contains(
                                    textEditingValue.text.toLowerCase(),
                                  ),
                                );
                              },
                              onSelected: (String selection) {
                                _itemNameController.text = selection;
                              },
                              fieldViewBuilder: (
                                BuildContext context,
                                TextEditingController controller,
                                FocusNode focusNode,
                                VoidCallback onFieldSubmitted,
                              ) {
                                return CustomTextField(
                                  controller: controller,
                                  labelText: 'Item Name',
                                  focusNode: focusNode,
                                );
                              },
                              optionsViewBuilder: (
                                BuildContext context,
                                AutocompleteOnSelected<String> onSelected,
                                Iterable<String> options,
                              ) {
                                return Align(
                                  alignment: Alignment.topLeft,
                                  child: Material(
                                    elevation: 4,
                                    borderRadius: BorderRadius.circular(12),
                                    color: theme.cardColor,
                                    child: Container(
                                      width:
                                          MediaQuery.of(context).size.width -
                                          32,
                                      decoration: BoxDecoration(
                                        color: theme.cardColor,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: ListView.separated(
                                        padding: EdgeInsets.zero,
                                        shrinkWrap: true,
                                        itemCount: options.length,
                                        separatorBuilder:
                                            (_, __) => const Divider(height: 1),
                                        itemBuilder: (
                                          BuildContext context,
                                          int index,
                                        ) {
                                          final option = options.elementAt(
                                            index,
                                          );
                                          return InkWell(
                                            onTap: () => onSelected(option),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 12.0,
                                                    horizontal: 16.0,
                                                  ),
                                              child: Text(
                                                option,
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  color: Colors.black87,
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 16),
                            CustomTextField(
                              controller: _quantityController,
                              labelText: 'Quantity',
                              keyboardType: TextInputType.number,
                            ),
                            const SizedBox(height: 16),
                            CustomTextField(
                              controller: _purposeController,
                              labelText: 'Purpose',
                              maxLines: 3,
                            ),
                            const SizedBox(height: 24),
                            CustomButton(
                              text: 'Submit Request',
                              onPressed: _requestItem,
                              isLoading: _isLoading,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Your Pending Requests',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: theme.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _isLoadingRequests
                        ? const Center(child: CircularProgressIndicator())
                        : _userRequests.isEmpty
                        ? const Center(
                          child: Text(
                            'No pending requests',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.black54,
                            ),
                          ),
                        )
                        : ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _userRequests.length,
                          separatorBuilder:
                              (_, __) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final request = _userRequests[index];
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              child: Dismissible(
                                key: Key(request.id),
                                direction: DismissDirection.endToStart,
                                background: Container(
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.only(right: 16.0),
                                  color: Colors.red,
                                  child: const Icon(
                                    Icons.delete,
                                    color: Colors.white,
                                  ),
                                ),
                                onDismissed:
                                    (direction) => _deleteRequest(request.id),
                                confirmDismiss: (direction) async {
                                  return await showDialog(
                                    context: context,
                                    builder:
                                        (context) => AlertDialog(
                                          title: const Text(
                                            'Confirm Delete',
                                            style: TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black87,
                                            ),
                                          ),
                                          content: const Text(
                                            'Are you sure you want to delete this request?',
                                            style: TextStyle(
                                              fontSize: 16,
                                              color: Colors.black54,
                                            ),
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed:
                                                  () => Navigator.pop(
                                                    context,
                                                    false,
                                                  ),
                                              child: const Text(
                                                'Cancel',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                            ),
                                            TextButton(
                                              onPressed:
                                                  () => Navigator.pop(
                                                    context,
                                                    true,
                                                  ),
                                              child: const Text(
                                                'Delete',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  color: Colors.red,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                  );
                                },
                                child: Card(
                                  elevation: 1,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.all(16.0),
                                    title: Text(
                                      request.itemName,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    subtitle: Text(
                                      'Quantity: ${request.quantity}\nPurpose: ${request.purpose}\nStatus: ${request.status}',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.black54,
                                      ),
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(
                                            Icons.edit,
                                            color: Colors.blue,
                                          ),
                                          onPressed:
                                              () => _editRequest(request),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.delete,
                                            color: Colors.red,
                                          ),
                                          onPressed:
                                              () => _deleteRequest(request.id),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                  ],
                ),
              ),
    );
  }

  @override
  void dispose() {
    _itemNameController.dispose();
    _quantityController.dispose();
    _purposeController.dispose();
    super.dispose();
  }
}
