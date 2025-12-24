import 'package:flutter/material.dart';
import '../models/credit_card_model.dart';
import '../models/bank_model.dart';
import '../services/credit_card_service.dart';
import '../services/bank_service.dart';
import '../services/auth_service.dart';

class CreditCardScreen extends StatefulWidget {
  const CreditCardScreen({super.key});

  @override
  State<CreditCardScreen> createState() => _CreditCardScreenState();
}

class _CreditCardScreenState extends State<CreditCardScreen> {
  final _creditCardService = CreditCardService();
  final _bankService = BankService();
  final _authService = AuthService();
  
  List<CreditCard> _cards = [];
  List<Bank> _banks = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final token = _authService.token;
      if (token == null) throw Exception('No hay sesión activa');

      final results = await Future.wait([
        _creditCardService.getCreditCards(token),
        _bankService.getBanks(token),
      ]);
      
      if (mounted) {
        setState(() {
          _cards = results[0] as List<CreditCard>;
          _banks = results[1] as List<Bank>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  void _showCardDialog({CreditCard? card}) {
    showDialog(
      context: context,
      builder: (context) => _CreditCardFormDialog(
        card: card,
        banks: _banks,
        onSave: (name, bankId, isActive) async {
          final token = _authService.token;
          if (token == null) return;

          try {
            if (card == null) {
              await _creditCardService.createCreditCard(token, name, bankId);
            } else {
              await _creditCardService.updateCreditCard(token, card.id, name, isActive);
            }
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(card == null ? 'Tarjeta creada' : 'Tarjeta actualizada'),
                  backgroundColor: Colors.green,
                  behavior: SnackBarBehavior.floating,
                ),
              );
              _loadData(); 
            }
          } catch (e) {
            if (mounted) {
               ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error: ${e.toString().replaceFirst('Exception: ', '')}'),
                  backgroundColor: Colors.red,
                  behavior: SnackBarBehavior.floating,
                ),
              );
             }
          }
        },
      ),
    );
  }

  Future<void> _handleDeleteCard(CreditCard card) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Tarjeta'),
        content: Text('¿Eliminar "${card.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Eliminar', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final token = _authService.token;
        if (token == null) return;
        await _creditCardService.deleteCreditCard(token, card.id);
        _loadData();
      } catch (e) {
        if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
         }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tarjetas de Crédito'),
        backgroundColor: Colors.indigo,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: ElevatedButton.icon(
              onPressed: () => _showCardDialog(),
              icon: const Icon(Icons.add, size: 20),
              label: const Text('Agregar'),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.indigo,
                backgroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                      const SizedBox(height: 16),
                      Text('Error: $_errorMessage'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadData,
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              : _cards.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.credit_card_off, size: 64, color: Colors.grey[300]),
                          const SizedBox(height: 16),
                          const Text('No hay tarjetas registradas'),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () => _showCardDialog(),
                            icon: const Icon(Icons.add),
                            label: const Text('Agregar Tarjeta'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.indigo,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 350,
                        mainAxisExtent: 180, // Altura fija responsive
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      itemCount: _cards.length,
                      itemBuilder: (context, index) {
                        final card = _cards[index];
                        return Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: card.active
                                    ? [Colors.indigo[400]!, Colors.indigo[700]!]
                                    : [Colors.grey[400]!, Colors.grey[600]!],
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: const Icon(
                                          Icons.credit_card,
                                          color: Colors.white,
                                          size: 28,
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: card.active
                                              ? Colors.green.withOpacity(0.3)
                                              : Colors.red.withOpacity(0.3),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: card.active ? Colors.green[200]! : Colors.red[200]!,
                                            width: 1,
                                          ),
                                        ),
                                        child: Text(
                                          card.active ? 'ACTIVA' : 'INACTIVA',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Spacer(),
                                  Text(
                                    card.name,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.account_balance,
                                          color: Colors.white70,
                                          size: 12,
                                        ),
                                        const SizedBox(width: 4),
                                        Flexible(
                                          child: Text(
                                            card.bank?.name ?? "Banco desconocido",
                                            style: const TextStyle(
                                              color: Colors.white70,
                                              fontSize: 12,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit, color: Colors.white, size: 18),
                                        onPressed: () => _showCardDialog(card: card),
                                        tooltip: 'Editar',
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                      ),
                                      const SizedBox(width: 8),
                                      IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.white70, size: 18),
                                        onPressed: () => _handleDeleteCard(card),
                                        tooltip: 'Eliminar',
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}

class _CreditCardFormDialog extends StatefulWidget {
  final CreditCard? card;
  final List<Bank> banks;
  final Function(String name, int bankId, bool isActive) onSave;

  const _CreditCardFormDialog({this.card, required this.banks, required this.onSave});

  @override
  State<_CreditCardFormDialog> createState() => _CreditCardFormDialogState();
}

class _CreditCardFormDialogState extends State<_CreditCardFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late int? _selectedBankId;
  late bool _isActive;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.card?.name ?? '');
    _selectedBankId = widget.card?.bankId;
    _isActive = widget.card?.active ?? true;
    
    // Si es nuevo y hay bancos, seleccionar el primero por defecto o dejar nulo
    if (_selectedBankId == null && widget.banks.isNotEmpty) {
      // _selectedBankId = widget.banks.first.id; // Opcional
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.card == null ? 'Nueva Tarjeta' : 'Editar Tarjeta',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nombre'),
                validator: (v) => v!.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                value: _selectedBankId,
                decoration: const InputDecoration(labelText: 'Banco'),
                items: widget.banks.where((b) => b.active || b.id == _selectedBankId).map((bank) {
                  return DropdownMenuItem(
                    value: bank.id,
                    child: Text(bank.name),
                  );
                }).toList(),
                onChanged: widget.card == null 
                  ? (v) => setState(() => _selectedBankId = v)
                  : null, // No editable en update según API doc? "Si cambias tarjeta..." en deuda sí, pero en la tarjeta misma el banco es fijo? La API doc solo muestra PUT con name e id_estado. Asumo que bankId no es editable.
                validator: (v) => v == null ? 'Requerido' : null,
              ),
               if (widget.card != null) ...[
                 const SizedBox(height: 8),
                 Text('El banco no se puede cambiar.', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
               ],

              const SizedBox(height: 16),
              if (widget.card != null)
                SwitchListTile(
                  title: const Text('Activa'),
                  value: _isActive,
                  onChanged: (v) => setState(() => _isActive = v),
                ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancelar'),
                  ),
                  ElevatedButton(
                    onPressed: _isLoading
                        ? null
                        : () async {
                            if (_formKey.currentState!.validate()) {
                              setState(() => _isLoading = true);
                              await widget.onSave(
                                _nameController.text.trim(),
                                _selectedBankId!,
                                _isActive,
                              );
                              if (mounted) Navigator.pop(context);
                            }
                          },
                    child: _isLoading
                        ? const CircularProgressIndicator()
                        : const Text('Guardar'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
