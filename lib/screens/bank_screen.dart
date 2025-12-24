import 'package:flutter/material.dart';
import '../models/bank_model.dart';
import '../services/bank_service.dart';
import '../services/auth_service.dart';

class BankScreen extends StatefulWidget {
  const BankScreen({super.key});

  @override
  State<BankScreen> createState() => _BankScreenState();
}

class _BankScreenState extends State<BankScreen> {
  final _bankService = BankService();
  final _authService = AuthService();
  
  List<Bank> _banks = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadBanks();
  }

  Future<void> _loadBanks() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final token = _authService.token;
      if (token == null) throw Exception('No hay sesión activa');

      final banks = await _bankService.getBanks(token);
      
      if (mounted) {
        setState(() {
          _banks = banks;
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

  void _showBankDialog({Bank? bank}) {
    showDialog(
      context: context,
      builder: (context) => _BankFormDialog(
        bank: bank,
        onSave: (name, isActive) async {
          final token = _authService.token;
          if (token == null) return;

          try {
            if (bank == null) {
              await _bankService.createBank(token, name);
            } else {
              await _bankService.updateBank(token, bank.id, name, isActive);
            }
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(bank == null ? 'Banco creado' : 'Banco actualizado'),
                  backgroundColor: Colors.green,
                  behavior: SnackBarBehavior.floating,
                ),
              );
              _loadBanks();
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

  Future<void> _handleDeleteBank(Bank bank) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Banco'),
        content: Text('¿Eliminar "${bank.name}"?'),
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
        await _bankService.deleteBank(token, bank.id);
        _loadBanks();
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
        title: const Text('Bancos'),
        backgroundColor: Colors.teal,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: ElevatedButton.icon(
              onPressed: () => _showBankDialog(),
              icon: const Icon(Icons.add, size: 20),
              label: const Text('Agregar'),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.teal,
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
                        onPressed: _loadBanks,
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              : _banks.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.account_balance_outlined, size: 64, color: Colors.grey[300]),
                          const SizedBox(height: 16),
                          const Text('No hay bancos registrados'),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () => _showBankDialog(),
                            icon: const Icon(Icons.add),
                            label: const Text('Agregar Banco'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.teal,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 300,
                        mainAxisExtent: 180, // Altura fija responsive
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      itemCount: _banks.length,
                      itemBuilder: (context, index) {
                        final bank = _banks[index];
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
                                colors: bank.active
                                    ? [Colors.teal[400]!, Colors.teal[600]!]
                                    : [Colors.grey[400]!, Colors.grey[600]!],
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: const Icon(
                                          Icons.account_balance,
                                          color: Colors.white,
                                          size: 32,
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: bank.active
                                              ? Colors.green.withOpacity(0.3)
                                              : Colors.red.withOpacity(0.3),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: bank.active ? Colors.green[200]! : Colors.red[200]!,
                                            width: 1,
                                          ),
                                        ),
                                        child: Text(
                                          bank.active ? 'ACTIVO' : 'INACTIVO',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Spacer(),
                                  Text(
                                    bank.name,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit, color: Colors.white, size: 20),
                                        onPressed: () => _showBankDialog(bank: bank),
                                        tooltip: 'Editar',
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.white70, size: 20),
                                        onPressed: () => _handleDeleteBank(bank),
                                        tooltip: 'Eliminar',
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

class _BankFormDialog extends StatefulWidget {
  final Bank? bank;
  final Function(String name, bool isActive) onSave;

  const _BankFormDialog({this.bank, required this.onSave});

  @override
  State<_BankFormDialog> createState() => _BankFormDialogState();
}

class _BankFormDialogState extends State<_BankFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late bool _isActive;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.bank?.name ?? '');
    _isActive = widget.bank?.active ?? true;
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
                widget.bank == null ? 'Nuevo Banco' : 'Editar Banco',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nombre'),
                validator: (v) => v!.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 16),
              if (widget.bank != null)
                SwitchListTile(
                  title: const Text('Activo'),
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
