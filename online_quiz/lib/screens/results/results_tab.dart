import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/quiz.dart';
import '../../models/course.dart';
import '../../models/attempt.dart';
import '../../providers/quiz_provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/app_theme.dart';
import '../quizzes/quiz_result_screen.dart';
import '../../widgets/results_skeleton_loader.dart';

class ResultsTab extends ConsumerStatefulWidget {
  const ResultsTab({super.key});

  @override
  ConsumerState<ResultsTab> createState() => _ResultsTabState();
}

class _ResultsTabState extends ConsumerState<ResultsTab> {
  // Filter states (applied filters)
  String _selectedGradeFilter = 'All';
  String? _selectedCourseFilter;
  String _selectedDateFilter = 'All Time';
  String _sortBy = 'Recent';
  String _searchQuery = '';
  
  // Temporary filter states (for bottom sheet)
  String _tempGradeFilter = 'All';
  String? _tempCourseFilter;
  String _tempDateFilter = 'All Time';
  String _tempSortBy = 'Recent';
  
  // Pagination
  int _currentPage = 0;
  final int _itemsPerPage = 10;
  
  // Data
  List<QuizResultWithDetails> _allResults = [];
  bool _isLoading = true;
  
  // Controllers
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
        _currentPage = 0;
      });
    });
    
    // Load results once when the widget is first created
    Future.microtask(() async {
      final authState = ref.read(authProvider);
      if (authState.user != null) {
        // Ensure quiz data is initialized
        await ref.read(quizProvider.notifier).initializeQuizzes(authState.user!.userId);
        // Load all results once
        final results = await _getAllQuizResults();
        if (mounted) {
          setState(() {
            _allResults = results;
            _isLoading = false;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refreshResults() async {
    final authState = ref.read(authProvider);
    if (authState.user != null) {
      setState(() {
        _isLoading = true;
      });
      
      // Refresh quiz data
      await ref.read(quizProvider.notifier).refreshQuizzes(authState.user!.userId);
      
      // Reload results
      final results = await _getAllQuizResults();
      
      if (mounted) {
        setState(() {
          _allResults = results;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show loading state while data is being fetched
    if (_isLoading) {
      return const ResultsSkeletonLoader();
    }

    // Filter results locally without reloading
    final filteredResults = _getFilteredResults(_allResults);
    final totalPages = filteredResults.isEmpty ? 1 : (filteredResults.length / _itemsPerPage).ceil();

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _refreshResults,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              _buildHeader(_allResults),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    if (_allResults.isNotEmpty) _buildSearchBar(),
                    if (_allResults.isNotEmpty) const SizedBox(height: 12),
                    if (_allResults.isNotEmpty) _buildFilterSection(),
                    if (_allResults.isNotEmpty) const SizedBox(height: 12),
                    if (_allResults.isNotEmpty) _buildActiveFiltersChips(),
                    if (_allResults.isNotEmpty) const SizedBox(height: 12),
                    if (_allResults.isNotEmpty) _buildResultsStats(filteredResults),
                    if (_allResults.isNotEmpty) const SizedBox(height: 16),
                    _allResults.isEmpty
                        ? _buildEmptyState()
                        : _buildResultsList(filteredResults, totalPages),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(List<QuizResultWithDetails> allResults) {
    final screenHeight = MediaQuery.of(context).size.height;
    final headerHeight = screenHeight < 700 ? 200.0 : 220.0;
    
    final totalQuizzes = allResults.length;
    final averageScore = totalQuizzes > 0 
        ? allResults.map((r) => r.percentage).reduce((a, b) => a + b) / totalQuizzes
        : 0.0;
    
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        // Gradient Background
        Container(
          height: headerHeight,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
            ),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(30),
              bottomRight: Radius.circular(30),
            ),
          ),
        ),
        // Decorative Circles
        Positioned(
          top: -50,
          right: -50,
          child: Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.1),
            ),
          ),
        ),
        Positioned(
          bottom: 50,
          left: -30,
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.1),
            ),
          ),
        ),
        // Content
        Positioned(
          top: MediaQuery.of(context).padding.top + 30,
          left: 24,
          right: 24,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                Icons.analytics,
                color: Colors.white,
                size: screenHeight < 700 ? 40 : 48,
              ),
              SizedBox(height: screenHeight < 700 ? 12 : 16),
              Text(
                'Quiz Results',
                style: TextStyle(
                  fontSize: screenHeight < 700 ? 24 : 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$totalQuizzes ${totalQuizzes == 1 ? 'Result' : 'Results'} - ${averageScore.round()}% Average',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search quizzes or courses...',
          hintStyle: TextStyle(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
          ),
          prefixIcon: Icon(
            Icons.search,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildFilterSection() {
    return Row(
      children: [
        Expanded(
          child: Row(
            children: [
              Icon(
                Icons.filter_list,
                size: 20,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              const SizedBox(width: 8),
              Text(
                'Filters',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        OutlinedButton.icon(
          onPressed: _showFilterBottomSheet,
          icon: const Icon(Icons.tune, size: 18),
          label: const Text('Show'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
        ),
        if (_hasActiveFilters()) ...[
          const SizedBox(width: 8),
          TextButton(
            onPressed: _clearAllFilters,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            child: const Text('Clear All'),
          ),
        ],
      ],
    );
  }

  void _showFilterBottomSheet() {
    // Initialize temp filters with current values
    _tempGradeFilter = _selectedGradeFilter;
    _tempCourseFilter = _selectedCourseFilter;
    _tempDateFilter = _selectedDateFilter;
    _tempSortBy = _sortBy;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.75,
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                // Handle bar
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Row(
                    children: [
                      Icon(
                        Icons.filter_list,
                        color: AppTheme.primaryColor,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Filter Results',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
                
                const Divider(height: 1),
                
                // Filter content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: _buildFilterContent(setModalState),
                  ),
                ),
                
                // Bottom action buttons
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setModalState(() {
                              _tempGradeFilter = 'All';
                              _tempCourseFilter = null;
                              _tempDateFilter = 'All Time';
                              _tempSortBy = 'Recent';
                            });
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text('Reset'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _selectedGradeFilter = _tempGradeFilter;
                              _selectedCourseFilter = _tempCourseFilter;
                              _selectedDateFilter = _tempDateFilter;
                              _sortBy = _tempSortBy;
                              _currentPage = 0;
                            });
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Apply Filters',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilterContent(StateSetter setModalState) {
    final courses = _allResults.map((r) => r.course.code).toSet().toList()..sort();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Grade Filter
        _buildFilterCategory('Grade'),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: ['All', 'Excellent', 'Good', 'Fair', 'Poor'].map((grade) {
            return _buildSelectableChip(
              label: grade,
              isSelected: _tempGradeFilter == grade,
              onTap: () {
                setModalState(() {
                  _tempGradeFilter = grade;
                });
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
        
        // Course Filter
        _buildFilterCategory('Course'),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildSelectableChip(
              label: 'All Courses',
              isSelected: _tempCourseFilter == null,
              onTap: () {
                setModalState(() {
                  _tempCourseFilter = null;
                });
              },
            ),
            ...courses.map((course) {
              return _buildSelectableChip(
                label: course,
                isSelected: _tempCourseFilter == course,
                onTap: () {
                  setModalState(() {
                    _tempCourseFilter = course;
                  });
                },
              );
            }),
          ],
        ),
        const SizedBox(height: 24),
        
        // Date Filter
        _buildFilterCategory('Date Range'),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: ['All Time', 'Today', 'This Week', 'This Month', 'Last 3 Months'].map((date) {
            return _buildSelectableChip(
              label: date,
              isSelected: _tempDateFilter == date,
              onTap: () {
                setModalState(() {
                  _tempDateFilter = date;
                });
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
        
        // Sort By
        _buildFilterCategory('Sort By'),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: ['Recent', 'Oldest', 'Highest Score', 'Lowest Score', 'Course Name'].map((sort) {
            return _buildSelectableChip(
              label: sort,
              isSelected: _tempSortBy == sort,
              onTap: () {
                setModalState(() {
                  _tempSortBy = sort;
                });
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildActiveFiltersChips() {
    if (!_hasActiveFilters()) return const SizedBox.shrink();
    
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (_selectedGradeFilter != 'All')
          _buildFilterChip(
            label: 'Grade: $_selectedGradeFilter',
            onRemove: () {
              setState(() {
                _selectedGradeFilter = 'All';
                _currentPage = 0;
              });
            },
          ),
        if (_selectedCourseFilter != null)
          _buildFilterChip(
            label: 'Course: $_selectedCourseFilter',
            onRemove: () {
              setState(() {
                _selectedCourseFilter = null;
                _currentPage = 0;
              });
            },
          ),
        if (_selectedDateFilter != 'All Time')
          _buildFilterChip(
            label: 'Date: $_selectedDateFilter',
            onRemove: () {
              setState(() {
                _selectedDateFilter = 'All Time';
                _currentPage = 0;
              });
            },
          ),
        if (_sortBy != 'Recent')
          _buildFilterChip(
            label: 'Sort: $_sortBy',
            onRemove: () {
              setState(() {
                _sortBy = 'Recent';
              });
            },
          ),
      ],
    );
  }

  Widget _buildFilterChip({required String label, required VoidCallback onRemove}) {
    return Chip(
      label: Text(
        label,
        style: const TextStyle(fontSize: 12),
      ),
      deleteIcon: const Icon(Icons.close, size: 16),
      onDeleted: onRemove,
      backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
      labelStyle: TextStyle(color: AppTheme.primaryColor),
      deleteIconColor: AppTheme.primaryColor,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  Widget _buildResultsStats(List<QuizResultWithDetails> filteredResults) {
    if (filteredResults.isEmpty) return const SizedBox.shrink();
    
    final avgScore = filteredResults.map((r) => r.percentage).reduce((a, b) => a + b) / filteredResults.length;
    final highestScore = filteredResults.map((r) => r.percentage).reduce((a, b) => a > b ? a : b);
    final lowestScore = filteredResults.map((r) => r.percentage).reduce((a, b) => a < b ? a : b);
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('Results', '${filteredResults.length}', Icons.quiz),
          _buildStatDivider(),
          _buildStatItem('Average', '${avgScore.round()}%', Icons.analytics),
          _buildStatDivider(),
          _buildStatItem('Highest', '${highestScore.round()}%', Icons.trending_up),
          _buildStatDivider(),
          _buildStatItem('Lowest', '${lowestScore.round()}%', Icons.trending_down),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          size: 16,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildStatDivider() {
    return Container(
      height: 40,
      width: 1,
      color: Theme.of(context).dividerColor.withValues(alpha: 0.2),
    );
  }

  Widget _buildFilterCategory(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
        fontWeight: FontWeight.w600,
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
      ),
    );
  }

  Widget _buildSelectableChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryColor
              : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppTheme.primaryColor
                : Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            color: isSelected
                ? Colors.white
                : Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
    );
  }

  bool _hasActiveFilters() {
    return _selectedGradeFilter != 'All' ||
        _selectedCourseFilter != null ||
        _selectedDateFilter != 'All Time' ||
        _sortBy != 'Recent';
  }

  void _clearAllFilters() {
    setState(() {
      _selectedGradeFilter = 'All';
      _selectedCourseFilter = null;
      _selectedDateFilter = 'All Time';
      _sortBy = 'Recent';
      _currentPage = 0;
    });
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.analytics_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No quiz results yet',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Complete quizzes to see your results here',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsList(List<QuizResultWithDetails> results, int totalPages) {
    if (results.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.search_off,
                size: 64,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
              ),
              const SizedBox(height: 16),
              Text(
                'No results found',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _hasActiveFilters() || _searchQuery.isNotEmpty
                    ? 'Try adjusting your filters or search'
                    : 'Complete quizzes to see your results here',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                ),
                textAlign: TextAlign.center,
              ),
              if (_hasActiveFilters() || _searchQuery.isNotEmpty) ...[
                const SizedBox(height: 16),
                TextButton.icon(
                  onPressed: () {
                    _searchController.clear();
                    _clearAllFilters();
                  },
                  icon: const Icon(Icons.clear_all),
                  label: const Text('Clear All Filters'),
                ),
              ],
            ],
          ),
        ),
      );
    }

    final paginatedResults = _getPaginatedResults(results);

    return Column(
      children: [
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          itemCount: paginatedResults.length,
          itemBuilder: (context, index) {
            return _buildResultCard(paginatedResults[index]);
          },
        ),
        if (results.length > _itemsPerPage) _buildPaginationControls(totalPages),
      ],
    );
  }

  Widget _buildResultCard(QuizResultWithDetails resultDetails) {
    final attempt = resultDetails.attempt;
    final quiz = resultDetails.quiz;
    final course = resultDetails.course;
    final percentage = resultDetails.percentage;
    
    Color scoreColor;
    String grade;
    IconData gradeIcon;
    
    if (percentage >= 90) {
      scoreColor = Colors.green;
      grade = 'Excellent';
      gradeIcon = Icons.star;
    } else if (percentage >= 75) {
      scoreColor = Colors.blue;
      grade = 'Good';
      gradeIcon = Icons.thumb_up;
    } else if (percentage >= 60) {
      scoreColor = Colors.orange;
      grade = 'Fair';
      gradeIcon = Icons.trending_up;
    } else {
      scoreColor = Colors.red;
      grade = 'Poor';
      gradeIcon = Icons.trending_down;
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => QuizResultScreen(
              quiz: quiz,
              course: course,
              attempt: attempt,
            ),
          ),
        );
      },
      child: Card(
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.1),
        color: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.only(bottom: 12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with score
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: scoreColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      gradeIcon,
                      color: scoreColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          quiz.title,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${course.code} - ${course.name}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${percentage.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: scoreColor,
                        ),
                      ),
                      Text(
                        grade,
                        style: TextStyle(
                          fontSize: 12,
                          color: scoreColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Score details
              _buildInfoRow(
                Icons.check_circle_outline,
                'Score',
                '${resultDetails.correctAnswers}/${resultDetails.totalQuestions}',
              ),
              _buildDivider(context),
              _buildInfoRow(
                Icons.access_time,
                'Time',
                _formatTimeSpent((attempt.timeSpentSeconds ?? 0) ~/ 60),
              ),
              _buildDivider(context),
              _buildInfoRow(
                Icons.calendar_today,
                'Completed',
                _formatDate(attempt.submittedAt!),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 16,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(BuildContext context) {
    return Divider(
      color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
      height: 16,
    );
  }

  Widget _buildPaginationControls(int totalPages) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: _currentPage > 0 ? () {
              setState(() {
                _currentPage--;
              });
            } : null,
            icon: const Icon(Icons.chevron_left),
            iconSize: 20,
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(
              minWidth: 32,
              minHeight: 32,
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              '${_currentPage + 1} / $totalPages',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ),
          IconButton(
            onPressed: _currentPage < totalPages - 1 ? () {
              setState(() {
                _currentPage++;
              });
            } : null,
            icon: const Icon(Icons.chevron_right),
            iconSize: 20,
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(
              minWidth: 32,
              minHeight: 32,
            ),
          ),
        ],
      ),
    );
  }

  List<QuizResultWithDetails> _getPaginatedResults(List<QuizResultWithDetails> results) {
    final startIndex = _currentPage * _itemsPerPage;
    final endIndex = (startIndex + _itemsPerPage).clamp(0, results.length);
    return results.sublist(startIndex, endIndex);
  }

  Future<List<QuizResultWithDetails>> _getAllQuizResults() async {
    // Check if widget is still mounted before using ref
    if (!mounted) return [];
    
    final quizNotifier = ref.read(quizProvider.notifier);
    final authState = ref.read(authProvider);
    
    if (authState.user == null) return [];
    
    try {
      final resultsData = await quizNotifier.getAllQuizResults(authState.user!.userId);
      
      // Check again after async operation
      if (!mounted) return [];
      
      final results = <QuizResultWithDetails>[];
      
      for (final data in resultsData) {
        final courseData = data['course'] as Map<String, dynamic>;
        results.add(QuizResultWithDetails(
          attempt: data['attempt'],
          quiz: data['quiz'],
          course: Course(
            courseId: courseData['courseId'],
            name: courseData['name'],
            code: courseData['code'],
            instructorUserId: 0,
            createdBy: 0,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          percentage: data['percentage'],
          correctAnswers: data['correctAnswers'],
          totalQuestions: data['totalQuestions'],
        ));
      }
      
      return results;
    } catch (e) {
      debugPrint('Error loading quiz results: $e');
      return [];
    }
  }

  List<QuizResultWithDetails> _getFilteredResults(List<QuizResultWithDetails> allResults) {
    var filtered = allResults;
    
    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((r) {
        return r.quiz.title.toLowerCase().contains(query) ||
            r.course.name.toLowerCase().contains(query) ||
            r.course.code.toLowerCase().contains(query);
      }).toList();
    }
    
    // Apply grade filter
    switch (_selectedGradeFilter) {
      case 'Excellent':
        filtered = filtered.where((r) => r.percentage >= 90).toList();
        break;
      case 'Good':
        filtered = filtered.where((r) => r.percentage >= 75 && r.percentage < 90).toList();
        break;
      case 'Fair':
        filtered = filtered.where((r) => r.percentage >= 60 && r.percentage < 75).toList();
        break;
      case 'Poor':
        filtered = filtered.where((r) => r.percentage < 60).toList();
        break;
    }
    
    // Apply course filter
    if (_selectedCourseFilter != null) {
      filtered = filtered.where((r) => r.course.code == _selectedCourseFilter).toList();
    }
    
    // Apply date filter
    final now = DateTime.now();
    switch (_selectedDateFilter) {
      case 'Today':
        filtered = filtered.where((r) {
          final date = r.attempt.submittedAt!;
          return date.year == now.year && date.month == now.month && date.day == now.day;
        }).toList();
        break;
      case 'This Week':
        final weekAgo = now.subtract(const Duration(days: 7));
        filtered = filtered.where((r) => r.attempt.submittedAt!.isAfter(weekAgo)).toList();
        break;
      case 'This Month':
        filtered = filtered.where((r) {
          final date = r.attempt.submittedAt!;
          return date.year == now.year && date.month == now.month;
        }).toList();
        break;
      case 'Last 3 Months':
        final threeMonthsAgo = DateTime(now.year, now.month - 3, now.day);
        filtered = filtered.where((r) => r.attempt.submittedAt!.isAfter(threeMonthsAgo)).toList();
        break;
    }
    
    // Apply sorting
    switch (_sortBy) {
      case 'Recent':
        filtered.sort((a, b) => b.attempt.submittedAt!.compareTo(a.attempt.submittedAt!));
        break;
      case 'Oldest':
        filtered.sort((a, b) => a.attempt.submittedAt!.compareTo(b.attempt.submittedAt!));
        break;
      case 'Highest Score':
        filtered.sort((a, b) => b.percentage.compareTo(a.percentage));
        break;
      case 'Lowest Score':
        filtered.sort((a, b) => a.percentage.compareTo(b.percentage));
        break;
      case 'Course Name':
        filtered.sort((a, b) => a.course.code.compareTo(b.course.code));
        break;
    }
    
    return filtered;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;
    
    if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Yesterday';
    } else if (difference < 7) {
      return '$difference ${difference == 1 ? 'day' : 'days'} ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  String _formatTimeSpent(int minutes) {
    if (minutes == 0) {
      return 'Less than 1 minute';
    } else if (minutes < 60) {
      return '$minutes ${minutes == 1 ? 'minute' : 'minutes'}';
    } else {
      final hours = minutes ~/ 60;
      final remainingMinutes = minutes % 60;
      if (remainingMinutes == 0) {
        return '$hours ${hours == 1 ? 'hour' : 'hours'}';
      } else {
        return '$hours ${hours == 1 ? 'hour' : 'hours'} $remainingMinutes ${remainingMinutes == 1 ? 'minute' : 'minutes'}';
      }
    }
  }
}

class QuizResultWithDetails {
  final Attempt attempt;
  final Quiz quiz;
  final Course course;
  final double percentage;
  final int correctAnswers;
  final int totalQuestions;

  QuizResultWithDetails({
    required this.attempt,
    required this.quiz,
    required this.course,
    required this.percentage,
    required this.correctAnswers,
    required this.totalQuestions,
  });
}