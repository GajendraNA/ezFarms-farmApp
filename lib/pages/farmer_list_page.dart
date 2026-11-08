import 'dart:convert';
import 'package:farmer/util/ipfile.dart';
import 'package:farmer/util/ui_helpers.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class FarmerListPage extends StatelessWidget {
  const FarmerListPage({super.key});

  @override
  Widget build(BuildContext context) => PeopleListPage(
        title: 'FARMERS',
        url: getAllFarmersUrl,
        icon: Icons.agriculture,
      );
}

/// Searchable list of people (farmers or customers) from the backend.
class PeopleListPage extends StatefulWidget {
  final String title;
  final String url;
  final IconData icon;

  const PeopleListPage({
    super.key,
    required this.title,
    required this.url,
    required this.icon,
  });

  @override
  State<PeopleListPage> createState() => _PeopleListPageState();
}

class _PeopleListPageState extends State<PeopleListPage> {
  List<Map<String, dynamic>> _people = [];
  bool _loading = true;
  String? _error;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = _people.isEmpty;
      _error = null;
    });
    try {
      final response = await http.get(Uri.parse(widget.url)).timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) throw Exception('Status ${response.statusCode}');
      final list = (json.decode(response.body) as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .toList()
        ..sort((a, b) => (a['name'] ?? '')
            .toString()
            .toLowerCase()
            .compareTo((b['name'] ?? '').toString().toLowerCase()));
      if (!mounted) return;
      setState(() {
        _people = list;
        _loading = false;
      });
    } catch (e) {
      debugPrint('Error: $e');
      if (!mounted) return;
      setState(() {
        _error = kNetworkError;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final q = _search.toLowerCase();
    final visible = q.isEmpty
        ? _people
        : _people
            .where((p) => '${p['name']} ${p['email']} ${p['address']} ${p['phone']}'
                .toLowerCase()
                .contains(q))
            .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.green,
        shadowColor: Colors.black,
        elevation: 10,
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/images/background.jpg"),
            fit: BoxFit.cover,
          ),
        ),
        child: AsyncStateView(
          isLoading: _loading,
          error: _error,
          isEmpty: _people.isEmpty,
          emptyMessage: 'No ${widget.title.toLowerCase()} found',
          onRetry: _load,
          child: RefreshIndicator(
            onRefresh: _load,
            child: ListView(
              padding: const EdgeInsets.all(10),
              children: [
                ResponsiveCenter(
                  maxWidth: 800,
                  child: Column(
                    children: [
                      TextField(
                        onChanged: (v) => setState(() => _search = v.trim()),
                        decoration: InputDecoration(
                          hintText: 'Search by name, phone, email or place',
                          prefixIcon: const Icon(Icons.search),
                          isDense: true,
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          '${visible.length} of ${_people.length}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      for (final person in visible) _personCard(person),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _personCard(Map<String, dynamic> p) {
    final name = (p['name'] ?? 'N/A').toString();
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        shape: const Border(),
        leading: CircleAvatar(
          backgroundColor: Colors.green[200],
          child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: TextStyle(color: Colors.green[900], fontWeight: FontWeight.bold)),
        ),
        title: Text(name,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        subtitle: Text(p['phone']?.toString() ?? ''),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        children: [
          InfoRow(icon: Icons.email, label: 'Email', value: p['email'] ?? 'N/A'),
          InfoRow(icon: Icons.phone, label: 'Phone', value: p['phone'] ?? 'N/A'),
          InfoRow(icon: Icons.location_on, label: 'Address', value: p['address'] ?? 'N/A'),
        ],
      ),
    );
  }
}
