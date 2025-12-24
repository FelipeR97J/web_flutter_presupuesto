import 'package:flutter/material.dart';

class PaginationControls extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final VoidCallback onPreviousPage;
  final VoidCallback onNextPage;
  final bool isLoading;

  const PaginationControls({
    required this.currentPage,
    required this.totalPages,
    required this.onPreviousPage,
    required this.onNextPage,
    this.isLoading = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final canGoPrevious = currentPage > 1 && !isLoading;
    final canGoNext = currentPage < totalPages && !isLoading;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxWidth < 480;

        return Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            border: Border(
              top: BorderSide(color: Colors.grey[200]!),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Botón anterior
              isSmallScreen
                  ? ElevatedButton(
                      onPressed: canGoPrevious ? onPreviousPage : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: canGoPrevious ? Colors.deepPurple : Colors.grey[300],
                        foregroundColor: canGoPrevious ? Colors.white : Colors.grey[600],
                        disabledBackgroundColor: Colors.grey[300],
                        disabledForegroundColor: Colors.grey[600],
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        minimumSize: const Size(44, 44),
                      ),
                      child: const Icon(Icons.chevron_left),
                    )
                  : ElevatedButton.icon(
                      onPressed: canGoPrevious ? onPreviousPage : null,
                      icon: const Icon(Icons.chevron_left),
                      label: const Text('Anterior'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: canGoPrevious ? Colors.deepPurple : Colors.grey[300],
                        foregroundColor: canGoPrevious ? Colors.white : Colors.grey[600],
                        disabledBackgroundColor: Colors.grey[300],
                        disabledForegroundColor: Colors.grey[600],
                      ),
                    ),

              // Información de página
              Expanded(
                child: Center(
                  child: isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          'Página $currentPage de $totalPages',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: isSmallScreen ? 13 : 14,
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                ),
              ),

              // Botón siguiente
              isSmallScreen
                  ? ElevatedButton(
                      onPressed: canGoNext ? onNextPage : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: canGoNext ? Colors.deepPurple : Colors.grey[300],
                        foregroundColor: canGoNext ? Colors.white : Colors.grey[600],
                        disabledBackgroundColor: Colors.grey[300],
                        disabledForegroundColor: Colors.grey[600],
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        minimumSize: const Size(44, 44),
                      ),
                      child: const Icon(Icons.chevron_right),
                    )
                  : ElevatedButton.icon(
                      onPressed: canGoNext ? onNextPage : null,
                      icon: const Icon(Icons.chevron_right),
                      label: const Text('Siguiente'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: canGoNext ? Colors.deepPurple : Colors.grey[300],
                        foregroundColor: canGoNext ? Colors.white : Colors.grey[600],
                        disabledBackgroundColor: Colors.grey[300],
                        disabledForegroundColor: Colors.grey[600],
                      ),
                    ),
            ],
          ),
        );
      },
    );
  }
}
