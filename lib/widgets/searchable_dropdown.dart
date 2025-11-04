import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../../core/config/app_config.dart';

class SearchableDropdown extends StatefulWidget {
  final String label;
  final IconData icon;
  final String? value;
  final Function(String?, int?) onChanged; // Hem name hem ID döndür
  final String? Function(String?)? validator;
  final String apiEndpoint; // 'schools' ya da 'departments'
  final String displayField; // hangi alanı gösterecek
  final String valueField; // hangi alanı value olarak kullanacak
  final String idField; // ID field name (varsayılan 'id')

  const SearchableDropdown({
    super.key,
    required this.label,
    required this.icon,
    required this.value,
    required this.onChanged,
    required this.apiEndpoint,
    required this.displayField,
    required this.valueField,
    this.idField = 'id',
    this.validator,
  });

  @override
  State<SearchableDropdown> createState() => _SearchableDropdownState();
}

class _SearchableDropdownState extends State<SearchableDropdown> {
  List<Map<String, dynamic>> _items = [];
  List<Map<String, dynamic>> _filteredItems = [];
  bool _isLoading = false;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _isExpanded = false;
  String? _selectedDisplayName;

  @override
  void initState() {
    super.initState();
    _fetchItems();

    // Eğer başlangıç değeri varsa, onu display name'e çevir
    if (widget.value != null) {
      _selectedDisplayName = widget.value;
    }
  }

  Future<void> _fetchItems([String? searchQuery]) async {
    setState(() => _isLoading = true);

    // Retry mekanizması ile 3 deneme yap
    int retries = 3;
    int attempt = 0;

    while (attempt < retries) {
      try {
        final apiUrl = AppConfig.effectiveApiBaseUrl;
        final queryParam = searchQuery?.isNotEmpty == true
            ? '?search=${Uri.encodeComponent(searchQuery!)}'
            : '';
        final uri = Uri.parse('$apiUrl/${widget.apiEndpoint}$queryParam');

        debugPrint(
            '🔄 Fetching ${widget.apiEndpoint} (attempt ${attempt + 1}/$retries): $uri');

        final response = await http.get(
          uri,
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
        ).timeout(
          const Duration(seconds: 15),
          onTimeout: () {
            throw Exception('Request timeout after 15 seconds');
          },
        );

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final items = data is Map && data.containsKey('data')
              ? data['data'] as List<dynamic>
              : data as List<dynamic>;

          setState(() {
            _items = items.cast<Map<String, dynamic>>();
            _filteredItems = _items;
          });

          debugPrint(
              '✅ Successfully fetched ${_items.length} items from ${widget.apiEndpoint}');
          break; // Başarılı olduysa döngüden çık
        } else {
          debugPrint(
              '⚠️ HTTP ${response.statusCode} from ${widget.apiEndpoint}');
          throw Exception('HTTP ${response.statusCode}');
        }
      } catch (e) {
        attempt++;
        debugPrint(
            '❌ Error fetching ${widget.apiEndpoint} (attempt $attempt/$retries): $e');

        if (attempt >= retries) {
          // Son deneme de başarısız olduysa kullanıcıya hata göster
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content:
                    Text('${widget.label} yüklenemedi. Lütfen tekrar deneyin.'),
                backgroundColor: Colors.red,
                action: SnackBarAction(
                  label: 'Tekrar Dene',
                  textColor: Colors.white,
                  onPressed: () => _fetchItems(searchQuery),
                ),
              ),
            );
          }
        } else {
          // Bir sonraki deneme öncesi kısa bekle
          await Future.delayed(Duration(seconds: attempt));
        }
      }
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  void _onSearchChanged(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredItems = []; // Boş iken hiçbir şey gösterme
      });
    } else if (query.length >= 3) {
      // 3+ karakter girildiyinde API'den ara
      _fetchItems(query);
    } else {
      // 3 karakterden az ise sadece uyarı göster
      setState(() {
        _filteredItems = [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () {
            setState(() => _isExpanded = !_isExpanded);
            if (_isExpanded) {
              _fetchItems(); // Açıldığında fresh data getir
              // Kısa bir gecikme ile arama alanına focus et
              Future.delayed(const Duration(milliseconds: 100), () {
                if (mounted) {
                  _searchFocusNode.requestFocus();
                }
              });
            }
          },
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: Theme.of(context)
                    .colorScheme
                    .outline
                    .withOpacity( 0.5),
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              leading: Icon(widget.icon),
              title: Text(
                _selectedDisplayName ?? widget.label,
                style: TextStyle(
                  color: _selectedDisplayName != null
                      ? Theme.of(context).colorScheme.onSurface
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              trailing: Icon(
                _isExpanded
                    ? Icons.keyboard_arrow_up
                    : Icons.keyboard_arrow_down,
              ),
            ),
          ),
        ),
        if (_isExpanded) ...[
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: Theme.of(context)
                    .colorScheme
                    .outline
                    .withOpacity( 0.5),
              ),
              borderRadius: BorderRadius.circular(12),
              color: Theme.of(context).colorScheme.surface,
            ),
            child: Column(
              children: [
                // Arama kutusu
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    autofocus: false,
                    decoration: InputDecoration(
                      hintText: '${widget.label} ara...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                _onSearchChanged('');
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    onChanged: _onSearchChanged,
                  ),
                ),

                // Sonuçlar listesi
                Container(
                  constraints: const BoxConstraints(maxHeight: 200),
                  child: _isLoading
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      : _filteredItems.isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Text(
                                  _searchController.text.isNotEmpty &&
                                          _searchController.text.length < 3
                                      ? 'En az 3 karakter girin'
                                      : _searchController.text.length >= 3
                                          ? 'Sonuç bulunamadı'
                                          : '${widget.label} aramak için yazın',
                                  style: TextStyle(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                                ),
                              ),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              itemCount: _filteredItems.length,
                              itemBuilder: (context, index) {
                                final item = _filteredItems[index];
                                final displayValue =
                                    item[widget.displayField]?.toString() ?? '';
                                final itemValue =
                                    item[widget.valueField]?.toString() ?? '';
                                final itemId = item[widget.idField] as int?;

                                return ListTile(
                                  title: Text(displayValue),
                                  onTap: () {
                                    setState(() {
                                      _selectedDisplayName = displayValue;
                                      _isExpanded = false;
                                      _searchController.clear();
                                    });
                                    widget.onChanged(itemValue, itemId);
                                  },
                                );
                              },
                            ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }
}
