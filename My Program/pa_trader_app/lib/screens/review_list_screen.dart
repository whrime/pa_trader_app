import 'package:flutter/material.dart';
import '../models/review_option.dart';
import 'review_detail_screen.dart';
import 'review_edit_screen.dart';

class ReviewListScreen extends StatefulWidget {
  final Function(List<ReviewOption>)? onReviewsChanged;

  const ReviewListScreen({Key? key, this.onReviewsChanged}) : super(key: key);

  @override
  State<ReviewListScreen> createState() => ReviewListScreenState();
}

class ReviewListScreenState extends State<ReviewListScreen> {
  List<ReviewOption> _customReviews = [];

  List<ReviewOption> get _allReviews {
    final customIds = _customReviews.map((s) => s.id).toSet();
    final filteredPredefined = ReviewOption.predefinedList.where((s) => !customIds.contains(s.id));
    final all = [...filteredPredefined, ..._customReviews];
    all.sort((a, b) {
      final numA = int.tryParse(a.id) ?? 999;
      final numB = int.tryParse(b.id) ?? 999;
      return numA.compareTo(numB);
    });
    return all;
  }

  Future<void> _navigateToEdit({ReviewOption? review}) async {
    final result = await Navigator.push<ReviewOption>(
      context,
      MaterialPageRoute(
        builder: (context) => ReviewEditScreen(review: review),
      ),
    );

    if (result != null) {
      setState(() {
        if (review != null) {
          final index = _customReviews.indexWhere((s) => s.id == review.id);
          if (index != -1) {
            _customReviews[index] = result;
          } else {
            _customReviews.add(result);
          }
        } else {
          _customReviews.add(result);
        }
      });
      widget.onReviewsChanged?.call(_customReviews);
    }
  }

  void _deleteCustomReview(ReviewOption review) {
    setState(() {
      _customReviews.removeWhere((s) => s.id == review.id);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('删除成功')),
    );
  }

  bool _isCustomReview(ReviewOption review) {
    return _customReviews.any((s) => s.id == review.id);
  }

  @override
  Widget build(BuildContext context) {
    final reviews = _allReviews;

    return Scaffold(
      appBar: AppBar(
        title: const Text('复盘分析'),
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              showSearch(
                context: context,
                delegate: _ReviewSearchDelegate(reviews, _isCustomReview, _navigateToEdit, _deleteCustomReview),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _navigateToEdit(),
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        itemCount: reviews.length,
        itemBuilder: (context, index) {
          final review = reviews[index];
          final isCustom = _isCustomReview(review);
          return _ReviewCard(
            review: review,
            index: index,
            isCustom: isCustom,
            reviews: reviews,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ReviewDetailScreen(
                    reviews: reviews,
                    initialIndex: index,
                  ),
                ),
              );
            },
            onEdit: () => _navigateToEdit(review: review),
            onDelete: isCustom ? () => _deleteCustomReview(review) : null,
          );
        },
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final ReviewOption review;
  final int index;
  final bool isCustom;
  final List<ReviewOption> reviews;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _ReviewCard({
    required this.review,
    required this.index,
    required this.isCustom,
    required this.reviews,
    required this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isCustom
                        ? [Colors.orange[400]!, Colors.orange[600]!]
                        : [Colors.purple[400]!, Colors.purple[600]!],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            review.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (isCustom)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.orange[100],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              '自定义',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.orange,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      review.shortDescription,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, size: 20, color: Colors.blue),
                    onPressed: onEdit,
                    visualDensity: VisualDensity.compact,
                  ),
                  if (isCustom)
                    IconButton(
                      icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                      onPressed: onDelete,
                      visualDensity: VisualDensity.compact,
                    ),
                ],
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 18,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReviewSearchDelegate extends SearchDelegate {
  final List<ReviewOption> reviews;
  final bool Function(ReviewOption) isCustomReview;
  final Function({ReviewOption? review}) navigateToEdit;
  final Function(ReviewOption) deleteCustomReview;

  _ReviewSearchDelegate(this.reviews, this.isCustomReview, this.navigateToEdit, this.deleteCustomReview);

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return buildSuggestions(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final results = reviews.where((review) {
      return review.name.toLowerCase().contains(query.toLowerCase()) ||
          review.shortDescription.toLowerCase().contains(query.toLowerCase()) ||
          review.content.toLowerCase().contains(query.toLowerCase());
    }).toList();

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: results.length,
      itemBuilder: (context, index) {
        final review = results[index];
        final isCustom = isCustomReview(review);
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: isCustom ? Colors.orange[400] : Colors.purple[400],
            child: Text(
              review.name[0],
              style: const TextStyle(color: Colors.white),
            ),
          ),
          title: Row(
            children: [
              Expanded(child: Text(review.name)),
              if (isCustom)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.orange[100],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    '自定义',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.orange,
                    ),
                  ),
                ),
            ],
          ),
          subtitle: Text(
            review.shortDescription,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: isCustom
              ? IconButton(
                  icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                  onPressed: () => deleteCustomReview(review),
                )
              : null,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ReviewDetailScreen(
                  reviews: results,
                  initialIndex: index,
                ),
              ),
            );
          },
        );
      },
    );
  }
}
