import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/theme.dart';
import '../../providers/auth_provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import '../../core/utils/environment.dart';

class ReviewsScreen extends ConsumerStatefulWidget {
  const ReviewsScreen({super.key});

  @override
  ConsumerState<ReviewsScreen> createState() => _ReviewsScreenState();
}

class _ReviewsScreenState extends ConsumerState<ReviewsScreen> {
  bool _isLoading = true;
  List<dynamic> _reviews = [];

  @override
  void initState() {
    super.initState();
    _fetchReviews();
  }

  Future<void> _fetchReviews() async {
    setState(() => _isLoading = true);
    try {
      final authState = ref.read(authProvider);
      final url = Uri.parse('${Environment.apiUrl}/reviews?branchId=${authState.branchId}');
      
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${authState.accessToken}',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _reviews = data['data'] ?? [];
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load reviews. Status: ${response.statusCode}')),
        );
      }
    } catch (e) {
      print('Error fetching reviews: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading reviews')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildStarRating(int rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return Icon(
          index < rating ? Icons.star : Icons.star_border,
          color: Colors.amber,
          size: 16,
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Customer Reviews', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchReviews,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _reviews.isEmpty
              ? const Center(
                  child: Text(
                    'No reviews found for this branch yet.',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _fetchReviews,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _reviews.length,
                    itemBuilder: (context, index) {
                      final review = _reviews[index];
                      final date = DateTime.tryParse(review['created_at'] ?? '');
                      final formattedDate = date != null
                          ? DateFormat('MMM d, yyyy - h:mm a').format(date.toLocal())
                          : 'Unknown Date';
                          
                      final isFlagged = review['is_flagged'] == true;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                        color: Colors.white,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      const Text('Overall: ', style: TextStyle(fontWeight: FontWeight.bold)),
                                      _buildStarRating(review['rating'] ?? 0),
                                    ],
                                  ),
                                  Text(formattedDate, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Text('Food: ', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                                  _buildStarRating(review['food_rating'] ?? review['rating'] ?? 0),
                                  const SizedBox(width: 16),
                                  const Text('Service: ', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                                  _buildStarRating(review['service_rating'] ?? review['rating'] ?? 0),
                                ],
                              ),
                              if (review['comment'] != null && review['comment'].toString().trim().isNotEmpty) ...[
                                const SizedBox(height: 12),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: isFlagged ? const Color(0xFFFEF2F2) : const Color(0xFFF8F9FA),
                                    borderRadius: BorderRadius.circular(8),
                                    border: isFlagged ? Border.all(color: const Color(0xFFFCA5A5)) : null,
                                  ),
                                  child: Text(
                                    '"${review['comment']}"',
                                    style: TextStyle(
                                      fontStyle: FontStyle.italic,
                                      color: isFlagged ? const Color(0xFF991B1B) : AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                              ]
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
