class PaginationResponse<T> {
  final List<T> data;
  final int total;
  final int totalPages;
  final int currentPage;
  final int limit;
  final bool hasNextPage;
  final bool hasPrevPage;

  PaginationResponse({
    required this.data,
    required this.total,
    required this.totalPages,
    required this.currentPage,
    required this.limit,
    required this.hasNextPage,
    required this.hasPrevPage,
  });

  factory PaginationResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic) dataParser,
  ) {
    // Convertir la lista de datos usando el parseador genérico
    // El parseador recibe un único item y retorna un objeto de tipo T
    final List<T> parsedData = [];
    if (json['data'] is List) {
      for (var item in json['data'] as List) {
        parsedData.add(dataParser(item));
      }
    }

    // Acceder a la información de paginación desde el objeto anidado
    // El API retorna: { data: [...], pagination: { page, limit, total, totalPages, hasNextPage, hasPrevPage } }
    final paginationData = json['pagination'] as Map<String, dynamic>? ?? {};
    
    int totalRecords = paginationData['total'] as int? ?? 0;
    final totalPages = paginationData['totalPages'] as int? ?? 1;
    final currentPage = paginationData['page'] as int? ?? 1;
    final limitPerPage = paginationData['limit'] as int? ?? 10;
    
    // Si no hay total pero hay páginas, calculamos
    if (totalRecords == 0 && totalPages > 0) {
      totalRecords = (totalPages - 1) * limitPerPage + parsedData.length;
    }

    // Calcular hasNextPage y hasPrevPage desde el objeto paginationData
    bool hasNextPage = paginationData['hasNextPage'] as bool? ?? (currentPage < totalPages);
    bool hasPrevPage = paginationData['hasPrevPage'] as bool? ?? (currentPage > 1);

    return PaginationResponse(
      data: parsedData,
      total: totalRecords,
      totalPages: totalPages,
      currentPage: currentPage,
      limit: limitPerPage,
      hasNextPage: hasNextPage,
      hasPrevPage: hasPrevPage,
    );
  }
}
