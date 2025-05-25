import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants/typography.dart';
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

  List<String> _inventoryItemNames = [];

  @override
  void initState() {
    super.initState();
    _loadInventoryItemNames();
  }

  Future<void> _loadInventoryItemNames() async {
    final items = await _firestoreService.getAllInventoryItemNames();
    setState(() {
      _inventoryItemNames = items;
    });
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

    final request = ItemRequest(
      id: const Uuid().v4(),
      itemId: '', // Still empty – you can link if needed
      itemName: itemName,
      quantity: quantity,
      requesterId: AuthService().currentUser!.uid,
      purpose: purpose,
      createdAt: DateTime.now(),
    );

    try {
      await _firestoreService.addItemRequest(request);
      Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Item request submitted')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to submit request: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Request Item', style: AppTypography.heading2),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            RawAutocomplete<String>(
              textEditingController: _itemNameController,
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
                      width: MediaQuery.of(context).size.width - 32,
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListView.separated(
                        padding: EdgeInsets.zero,
                        shrinkWrap: true,
                        itemCount: options.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
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
                                style: theme.textTheme.bodyMedium,
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
            ),
            const SizedBox(height: 24),
            CustomButton(text: 'Submit Request', onPressed: _requestItem),
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
