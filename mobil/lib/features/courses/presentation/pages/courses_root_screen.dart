import 'package:flutter/material.dart';
import '../../data/courses_service.dart';
import '../../../../core/models/course_match_model.dart';

/// Courses tab root screen - EMİLETÖR (Ders Arkadaşı Eşleştirme)
class CoursesRootScreen extends StatefulWidget {
  const CoursesRootScreen({super.key});

  @override
  State<CoursesRootScreen> createState() => _CoursesRootScreenState();
}

class _CoursesRootScreenState extends State<CoursesRootScreen> with AutomaticKeepAliveClientMixin {
  final ScrollController _scrollController = ScrollController();
  final CoursesService _coursesService = CoursesService();
  
  bool _isRefreshing = false;
  bool _isLoading = true;
  List<CourseModel> _myCourses = [];
  List<CourseMatchModel> _matches = [];
  String? _error;
  int _selectedTab = 0; // 0: Derslerim, 1: Eşleşmeler

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final courses = await _coursesService.getMyCourses();
      final matches = await _coursesService.getMatches();
      
      if (mounted) {
        setState(() {
          _myCourses = courses;
          _matches = matches;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _onRefresh() async {
    setState(() => _isRefreshing = true);
    await _loadData();
    if (mounted) {
      setState(() => _isRefreshing = false);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('EMİLETÖR - Ders Arkadaşı Bul'),
        bottom: TabBar(
          onTap: (index) => setState(() => _selectedTab = index),
          tabs: [
            Tab(
              icon: const Icon(Icons.book),
              text: 'Derslerim (${_myCourses.length})',
            ),
            Tab(
              icon: const Icon(Icons.people),
              text: 'Eşleşmeler (${_matches.length})',
            ),
          ],
        ),
        actions: [
          if (_selectedTab == 0)
            IconButton(
              icon: const Icon(Icons.add),
              tooltip: 'Ders Ekle',
              onPressed: _showAddCourseDialog,
            ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => debugPrint('🎯 Filter tapped'),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorState()
              : RefreshIndicator(
                  onRefresh: _onRefresh,
                  child: _selectedTab == 0
                      ? _buildMyCoursesTab()
                      : _buildMatchesTab(),
                ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Bir hata oluştu',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'Bilinmeyen hata',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadData,
              child: const Text('Tekrar Dene'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMyCoursesTab() {
    if (_myCourses.isEmpty) {
      return _buildEmptyCoursesState();
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _myCourses.length,
      itemBuilder: (context, index) {
        final course = _myCourses[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Text(
                course.code.substring(0, 2),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              course.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${course.code} • ${course.credits} Kredi'),
                if (course.professor != null)
                  Text(
                    course.professor!,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.people_outline),
                  tooltip: 'Ders Arkadaşlarını Gör',
                  onPressed: () => _showCourseMatches(course),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: 'Dersi Çıkar',
                  onPressed: () => _removeCourse(course),
                ),
              ],
            ),
            isThreeLine: course.professor != null,
          ),
        );
      },
    );
  }

  Widget _buildMatchesTab() {
    if (_matches.isEmpty) {
      return _buildEmptyMatchesState();
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _matches.length,
      itemBuilder: (context, index) {
        final match = _matches[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
              child: Text(
                '${match.compatibilityScore.toInt()}%',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSecondaryContainer,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            title: Text(
              '${match.matchedUser.firstName} ${match.matchedUser.lastName}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  '${match.commonCourses.length} ortak ders',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 2),
                Text(
                  match.commonCourses.join(', '),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                ),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.message_outlined),
              tooltip: 'Mesaj Gönder',
              onPressed: () => _sendMessage(match),
            ),
            isThreeLine: true,
            onTap: () => _showMatchDetails(match),
          ),
        );
      },
    );
  }

  Widget _buildEmptyCoursesState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.book_outlined,
              size: 80,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
            ),
            const SizedBox(height: 24),
            Text(
              'Henüz ders eklemediniz',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Text(
              'Ders ekleyerek ders arkadaşları bulabilirsiniz',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _showAddCourseDialog,
              icon: const Icon(Icons.add),
              label: const Text('İlk Dersi Ekle'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyMatchesState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 80,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
            ),
            const SizedBox(height: 24),
            Text(
              'Henüz eşleşme bulunamadı',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Text(
              _myCourses.isEmpty
                  ? 'Önce ders ekleyin, sonra eşleşmeler görünecek'
                  : 'Derslerinize kayıtlı başka öğrenci bulunamadı',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showAddCourseDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ders Ekle'),
        content: const Text('Ders ekleme özelliği yakında eklenecek...'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  void _showCourseMatches(CourseModel course) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${course.code} - Ders Arkadaşları'),
        content: const Text('Bu dersi alan diğer öğrenciler gösterilecek...'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kapat'),
          ),
        ],
      ),
    );
  }

  void _removeCourse(CourseModel course) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Dersi Çıkar'),
        content: Text('${course.name} dersini çıkarmak istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Çıkar'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        await _coursesService.unenrollCourse(course.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ders çıkarıldı')),
          );
          _loadData();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Hata: $e')),
          );
        }
      }
    }
  }

  void _showMatchDetails(CourseMatchModel match) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${match.matchedUser.firstName} ${match.matchedUser.lastName}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Uyumluluk: ${match.compatibilityScore.toInt()}%'),
            const SizedBox(height: 12),
            Text('Ortak Dersler (${match.commonCourses.length}):'),
            const SizedBox(height: 8),
            ...match.commonCourses.map((course) => Padding(
                  padding: const EdgeInsets.only(left: 8, bottom: 4),
                  child: Text('• $course'),
                )),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kapat'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _sendMessage(match);
            },
            icon: const Icon(Icons.message),
            label: const Text('Mesaj Gönder'),
          ),
        ],
      ),
    );
  }

  void _sendMessage(CourseMatchModel match) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${match.matchedUser.firstName}\'a mesaj gönderme özelliği yakında...'),
      ),
    );
  }
}
