import 'package:flutter/material.dart';
import '../../services/purchase_request_service.dart';

class PurchaseRequestListPage extends StatefulWidget {
  const PurchaseRequestListPage({super.key});

  @override
  State<PurchaseRequestListPage> createState() =>
      _PurchaseRequestListPageState();
}

class _PurchaseRequestListPageState extends State<PurchaseRequestListPage> {
  List<dynamic> list = [];
  bool isLoading = true;
  bool isLoadingMore = false;
  bool hasMoreData = true;
  int currentPage = 1;
  String? searchQuery;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadData();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 200 &&
          !isLoadingMore &&
          hasMoreData) {
        _loadMoreData();
      }
    });
  }

  Future<void> _loadData({String? search}) async {
    setState(() {
      isLoading = true;
      currentPage = 1;
      searchQuery = search;
      list.clear();
    });

    final result = await PurchaseRequestService.getAll(page: 1, search: search);

    if (result['status'] == true) {
      setState(() {
        list = result['data'] ?? [];
        hasMoreData =
            (result['meta']?['current_page'] ?? 1) <
            (result['meta']?['last_page'] ?? 1);
      });
    }
    setState(() => isLoading = false);
  }

  Future<void> _loadMoreData() async {
    if (isLoadingMore || !hasMoreData) return;
    setState(() => isLoadingMore = true);
    currentPage++;

    final result = await PurchaseRequestService.getAll(
      page: currentPage,
      search: searchQuery,
    );

    if (result['status'] == true) {
      setState(() {
        list.addAll(result['data'] ?? []);
        hasMoreData =
            (result['meta']?['current_page'] ?? 1) <
            (result['meta']?['last_page'] ?? 1);
      });
    }
    setState(() => isLoadingMore = false);
  }

  Future<void> _deleteItem(String hashid) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Purchase Request?'),
        content: const Text('Tindakan ini tidak dapat dibatalkan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final result = await PurchaseRequestService.delete(hashid);
      if (result['status'] == true) {
        _loadData(search: searchQuery);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Berhasil dihapus'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Purchase Request'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadData(search: searchQuery),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Cari nama part atau user...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                filled: true,
              ),
              onChanged: (value) {
                Future.delayed(const Duration(milliseconds: 600), () {
                  if (mounted) _loadData(search: value);
                });
              },
            ),
          ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: () => _loadData(search: searchQuery),
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: list.length + (isLoadingMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == list.length) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        final item = list[index];
                        final hashid = item['hashid']?.toString() ?? '';

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: ListTile(
                            title: Text(item['nama_part'] ?? '-'),
                            subtitle: Text(
                              "${item['part_number'] ?? '-'} • ${item['pic'] ?? '-'}",
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Status
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(
                                      item['status'] ?? 'PR',
                                    ).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    item['status'] ?? 'PR',
                                    style: TextStyle(
                                      color: _getStatusColor(
                                        item['status'] ?? 'PR',
                                      ),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),

                                // Edit Button
                                IconButton(
                                  icon: const Icon(
                                    Icons.edit,
                                    color: Colors.blue,
                                  ),
                                  onPressed: () async {
                                    final result = await Navigator.pushNamed(
                                      context,
                                      '/purchase/form',
                                      arguments: {'hashid': hashid},
                                    );
                                    if (result == true)
                                      _loadData(search: searchQuery);
                                  },
                                ),

                                // Delete Button
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                  onPressed: () => _deleteItem(hashid),
                                ),
                              ],
                            ),
                            onTap: () => Navigator.pushNamed(
                              context,
                              '/purchase/detail',
                              arguments: hashid,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.pushNamed(context, '/purchase/form');
          if (result == true) _loadData(search: searchQuery);
        },
        icon: const Icon(Icons.add),
        label: const Text('Ajukan Baru'),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Completed':
        return Colors.green;
      case 'PO':
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }
}
