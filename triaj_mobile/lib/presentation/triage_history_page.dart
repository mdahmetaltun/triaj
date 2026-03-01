import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/models/firestore_models.dart';
import '../services/triage_record_repository.dart';

class TriageHistoryPage extends StatefulWidget {
  const TriageHistoryPage({super.key});

  @override
  State<TriageHistoryPage> createState() => _TriageHistoryPageState();
}

class _TriageHistoryPageState extends State<TriageHistoryPage> {
  final TriageRecordRepository _repository = TriageRecordRepository();
  List<TriageCaseRecord>? _records;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  Future<void> _loadRecords() async {
    try {
      final records = await _repository.fetchUserRecords();
      if (!mounted) return;
      setState(() {
        _records = records;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Color _getMtsColor(String mts) {
    switch (mts) {
      case 'K':
        return Colors.red;
      case 'T':
        return Colors.orange;
      case 'S':
        return Colors.amber;
      case 'Y':
        return Colors.green;
      case 'M':
      case 'B':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  Color _getStsColor(String tsb) {
    if (tsb == 'KIRMIZI') return Colors.red;
    if (tsb == 'SARI') return Colors.amber;
    if (tsb == 'YESIL' || tsb == 'YE') return Colors.green;
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColors = isDark
        ? [const Color(0xFF1B1330), const Color(0xFF291A45)]
        : [const Color(0xFFFFF4FB), const Color(0xFFFFEFD8)];

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Geçmiş Kayıtlar',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: bgColors,
          ),
        ),
        child: SafeArea(child: _buildBody(isDark)),
      ),
    );
  }

  Widget _buildBody(bool isDark) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Kayıtlar Yüklenemedi',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                    _error = null;
                  });
                  _loadRecords();
                },
                child: const Text('Tekrar Dene'),
              ),
            ],
          ),
        ),
      );
    }

    if (_records == null || _records!.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.history,
              size: 64,
              color: isDark ? Colors.white24 : Colors.black26,
            ),
            const SizedBox(height: 16),
            Text(
              'Henüz kayıt bulunmuyor.',
              style: TextStyle(
                fontSize: 16,
                color: isDark ? Colors.white60 : Colors.black54,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _records!.length,
      itemBuilder: (context, index) {
        final record = _records![index];
        final savedAtStr = record.savedAt != null
            ? DateFormat('dd.MM.yyyy HH:mm').format(record.savedAt!)
            : 'Tarih Yok';

        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          color: isDark ? const Color(0x7F2A1E4B) : Colors.white,
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            title: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Vaka #${record.caseNo} • $savedAtStr',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white60 : Colors.grey.shade600,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        record.schema,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Row(
                children: [
                  _buildBadge('STS: ${record.tsb}', _getStsColor(record.tsb)),
                  const SizedBox(width: 8),
                  _buildBadge('MTS: ${record.mts}', _getMtsColor(record.mts)),
                  if (record.compatibilityShort.isNotEmpty) ...[
                    const Spacer(),
                    Text(
                      record.compatibilityShort,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _getCompatColor(record.compatibilityType),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            children: [
              const Divider(),
              _buildDetailRow('Sonuç', record.discriminator),
              _buildDetailRow('Hastanın Yaşı', record.patient.age),
              _buildDetailRow('Cinsiyeti', record.patient.gender),
              if (record.patient.history.isNotEmpty)
                _buildDetailRow('Özgeçmiş', record.patient.history.join(', ')),
              _buildDetailRow('Değerlendirme Süresi', '${record.seconds} sn'),
              if (record.compatibilityMessage.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  margin: const EdgeInsets.only(top: 8),
                  decoration: BoxDecoration(
                    color: _getCompatColor(
                      record.compatibilityType,
                    ).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _getCompatColor(
                        record.compatibilityType,
                      ).withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    record.compatibilityMessage,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? _getCompatColor(
                              record.compatibilityType,
                            ).withOpacity(0.9)
                          : _getCompatColor(record.compatibilityType),
                    ),
                  ),
                ),

              if (record.tsbResponses.isNotEmpty) ...[
                const SizedBox(height: 16),
                _buildSectionHeader('Sağlık Bakanlığı (STS) Yanıtları', isDark),
                const SizedBox(height: 8),
                ...record.tsbResponses.map(
                  (res) => _buildDatalogRow(
                    question: res['question'] ?? 'Bilinmiyor',
                    answer: res['answer'] ?? '?',
                    categoryLabel: res['category'],
                    isYes: res['answer'] == 'Evet',
                    isDark: isDark,
                  ),
                ),
              ],

              if (record.mtsPath.isNotEmpty) ...[
                const SizedBox(height: 16),
                _buildSectionHeader('MTS Değerlendirme Adımları', isDark),
                const SizedBox(height: 8),
                ...record.mtsPath.map((res) {
                  final hasValue =
                      res['value'] != null &&
                      res['value'].toString().isNotEmpty;
                  final q = res['discriminator'] ?? 'Bilinmiyor';
                  final qText = hasValue ? '$q (${res['value']})' : q;

                  return _buildDatalogRow(
                    question: qText,
                    answer: res['answer'] ?? '?',
                    categoryLabel: res['category'],
                    isYes: res['answer'] == 'Evet',
                    isDark: isDark,
                  );
                }),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      decoration: BoxDecoration(
        color: isDark ? Colors.white12 : Colors.black.withOpacity(0.04),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: isDark ? Colors.white70 : Colors.black87,
        ),
      ),
    );
  }

  Widget _buildDatalogRow({
    required String question,
    required String answer,
    String? categoryLabel,
    required bool isYes,
    required bool isDark,
  }) {
    final Color answerColor = isYes
        ? Colors.red.shade400
        : (isDark ? Colors.white54 : Colors.black54);

    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0, left: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isYes ? Icons.check_circle : Icons.remove_circle_outline,
            size: 14,
            color: answerColor,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white70 : Colors.black87,
                  fontFamily: 'Inter', // Default system font fallback
                ),
                children: [
                  TextSpan(text: '$question '),
                  if (categoryLabel != null)
                    TextSpan(
                      text: '($categoryLabel) ',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: _getStsColor(categoryLabel),
                      ),
                    ),
                  TextSpan(
                    text: '→ $answer',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: answerColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Color _getCompatColor(String type) {
    if (type == 'uyumlu') return const Color(0xFF27AE60);
    if (type == 'alttriaj') return const Color(0xFFE67E22);
    if (type == 'usttriaj') return const Color(0xFFE74C3C);
    return Colors.grey;
  }

  Widget _buildDetailRow(String label, String value) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
