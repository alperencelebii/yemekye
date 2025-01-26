import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ReportDetailPage extends StatefulWidget {
  final String reportId;
  final String shopId;

  const ReportDetailPage({
    Key? key,
    required this.reportId,
    required this.shopId,
  }) : super(key: key);

  @override
  _ReportDetailPageState createState() => _ReportDetailPageState();
}

class _ReportDetailPageState extends State<ReportDetailPage> {
  final TextEditingController _noteController = TextEditingController();
  bool _isClosingReport = false;

  Future<void> _startReview(String docId) async {
    try {
      await FirebaseFirestore.instance.collection('reports').doc(docId).update({
        'status': 'İşleniyor',
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Rapor işlenmeye başlandı.')),
      );

      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Durum güncellenirken bir hata oluştu.')),
      );
    }
  }

  Future<void> _closeReport(String docId) async {
    final note = _noteController.text.trim();

    if (note.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen bir not girin.')),
      );
      return;
    }

    setState(() {
      _isClosingReport = true;
    });

    try {
      await FirebaseFirestore.instance.collection('reports').doc(docId).update({
        'status': 'Tamamlandı',
        'reviewerNote': note,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Rapor başarıyla kapatıldı.')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Rapor kapatılırken bir hata oluştu.')),
      );
    } finally {
      setState(() {
        _isClosingReport = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rapor Detayları'),
        centerTitle: true,
      ),
      body: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        future: FirebaseFirestore.instance
            .collection('reports')
            .doc(widget.reportId)
            .get(),
        builder: (context, reportSnapshot) {
          if (reportSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!reportSnapshot.hasData || !reportSnapshot.data!.exists) {
            return const Center(child: Text('Rapor bulunamadı.'));
          }

          final report = reportSnapshot.data!.data()!;
          final topic = report['topic'] ?? 'Konu Yok';
          final message = report['message'] ?? 'Mesaj Yok';
          final status = report['status'] ?? 'Bekleniyor';
          final timestamp = report['timestamp'] != null
              ? (report['timestamp'] as Timestamp).toDate()
              : null;

          return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            future: FirebaseFirestore.instance
                .collection('shops')
                .doc(widget.shopId)
                .get(),
            builder: (context, shopSnapshot) {
              if (shopSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!shopSnapshot.hasData || !shopSnapshot.data!.exists) {
                return const Center(child: Text('Mağaza bilgisi bulunamadı.'));
              }

              final shop = shopSnapshot.data!.data()!;
              final shopName = shop['name'] ?? 'Ad Yok';
              final shopAddress = shop['address'] ?? 'Adres Yok';

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionCard(
                      'Mağaza Bilgileri',
                      [
                        _buildInfoRow('Mağaza ID', widget.shopId),
                        _buildInfoRow('Mağaza Adı', shopName),
                        _buildMultilineInfoRow('Adres', shopAddress),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildSectionCard(
                      'Rapor Bilgileri',
                      [
                        _buildInfoRow('Konu', topic),
                        const SizedBox(height: 8),
                        _buildMultilineInfoRow('Mesaj', message),
                        if (timestamp != null)
                          _buildInfoRow('Tarih', _formatTimestamp(timestamp)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (status == 'Bekleniyor') ...[
                      ElevatedButton(
                        onPressed: () => _startReview(widget.reportId),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          minimumSize: const Size.fromHeight(50),
                        ),
                        child: const Text(
                          'İncelemeye Başla',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ] else if (status == 'İşleniyor') ...[
                      _buildSectionCard(
                        'Not Ekle',
                        [
                          _buildNoteField(),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _isClosingReport
                                ? null
                                : () => _closeReport(widget.reportId),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              minimumSize: const Size.fromHeight(50),
                            ),
                            child: _isClosingReport
                                ? const CircularProgressIndicator(
                                    color: Colors.white,
                                  )
                                : const Text(
                                    'Raporu Kapat',
                                    style: TextStyle(fontSize: 16),
                                  ),
                          ),
                        ],
                      ),
                    ] else if (status == 'Tamamlandı') ...[
                      _buildSectionCard(
                        'Rapor Durumu',
                        [
                          _buildInfoRow('Durum', 'Tamamlandı'),
                          const SizedBox(height: 8),
                          _buildMultilineInfoRow(
                            'Not',
                            report['reviewerNote'] ?? 'Bir not eklenmemiş.',
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildSectionCard(String title, List<Widget> children) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(height: 24, color: Colors.grey),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(color: Colors.black54),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMultilineInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: Text(
                value,
                style: const TextStyle(color: Colors.black54, height: 1.4),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoteField() {
    return TextField(
      controller: _noteController,
      maxLines: 5,
      decoration: InputDecoration(
        hintText: 'Rapor ile ilgili notunuzu yazın...',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        filled: true,
        fillColor: Colors.grey[200],
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    return '${timestamp.day}/${timestamp.month}/${timestamp.year} ${timestamp.hour}:${timestamp.minute}';
  }
}
