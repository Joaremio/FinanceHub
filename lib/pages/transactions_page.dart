import 'package:financehub/controllers/transaction_controller.dart';
import 'package:financehub/widgets/transactions_widgets.dart';
import 'package:flutter/material.dart';

class TransactionsPage extends StatefulWidget {
  const TransactionsPage({super.key});

  @override
  State<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends State<TransactionsPage> {
  late final TransactionsController _controller;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller = TransactionsController();
    _controller.addListener(_rebuild);
    _controller.load();
    _scrollController.addListener(_onScroll);
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  void _onScroll() {
    final nearEnd =
        _scrollController.offset >=
        _scrollController.position.maxScrollExtent - 200;
    if (nearEnd) _controller.loadMore();
  }

  @override
  void dispose() {
    _controller.removeListener(_rebuild);
    _controller.dispose();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Text(
                'Transações',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            TransactionSearchBar(
              controller: _searchController,
              onChanged: _controller.setSearch,
            ),
            TransactionFilterBar(
              filter: _controller.filter,
              sort: _controller.sort,
              onFilterChanged: _controller.setFilter,
              onSortChanged: _controller.setSort,
            ),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_controller.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_controller.error != null) {
      return TransactionErrorState(
        message: _controller.error!,
        onRetry: _controller.load,
      );
    }

    if (_controller.items.isEmpty) {
      return TransactionEmptyState(
        filter: _controller.filter,
        search: _controller.search,
      );
    }

    return TransactionList(
      items: _controller.items,
      scrollController: _scrollController,
      controller: _controller,
      isLoadingMore: _controller.isLoadingMore,
    );
  }
}
