import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:yemekye/yoneticipanel/reports/reportdetailspage.dart';

class ReportListPage extends StatefulWidget {
  const ReportListPage({Key? key}) : super(key: key);

  @override
  State<ReportListPage> createState() => _ReportListPageState();
}

class _ReportListPageState extends State<ReportListPage> {
  String _selectedStatus = 'Hepsi'; // Varsayılan durum filtresi
  final List<String> _statusOptions = [
    'Hepsi',
    'Bekleniyor',
    'İşleniyor',
    'Tamamlandı'
  ];

  final Color primaryColor = const Color(0xFFF9A602); // Ana renk (turuncu)
  final Color backgroundColor = const Color(0xFFF5F5F5); // Arka plan rengi

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: primaryColor,
        title: const Text(
          'Raporlar',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      backgroundColor: backgroundColor,
      body: Column(
        children: [
          _buildFilterBar(),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('reports')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('Henüz rapor yok.'));
                }

                final reports = snapshot.data!.docs;

                // Filtreleme işlemi
                final filteredReports = _selectedStatus == 'Hepsi'
                    ? reports
                    : reports
                        .where((doc) => doc.data()['status'] == _selectedStatus)
                        .toList();

                if (filteredReports.isEmpty) {
                  return const Center(
                      child: Text('Bu durum için rapor bulunamadı.'));
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredReports.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final report = filteredReports[index].data();
                    final docId = filteredReports[index].id;
                    final shopId = report['shopId'] ?? 'Bilinmiyor';
                    final topic = report['topic'] ?? 'Konu Yok';
                    final message = report['message'] ?? 'Mesaj Yok';
                    final status = report['status'] ?? 'Bekleniyor';
                    final timestamp = report['timestamp'] != null
                        ? (report['timestamp'] as Timestamp).toDate()
                        : null;

                    return _buildReportCard(
                      shopId: shopId,
                      topic: topic,
                      message: message,
                      timestamp: timestamp,
                      status: status,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ReportDetailPage(
                              reportId: docId,
                              shopId: shopId,
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: primaryColor.withOpacity(0.1),
        border: Border(
          bottom: BorderSide(color: primaryColor, width: 2),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _statusOptions.map((status) {
            final isSelected = _selectedStatus == status;

            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedStatus = status;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 8),
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? primaryColor : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: primaryColor,
                    width: 1.5,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: primaryColor.withOpacity(0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: isSelected ? Colors.white : primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildReportCard({
    required String shopId,
    required String topic,
    required String message,
    DateTime? timestamp,
    required String status,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        future:
            FirebaseFirestore.instance.collection('shops').doc(shopId).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final shopData = snapshot.data!.data()!;
          final shopName = shopData['name'] ?? 'Ad Bilinmiyor';
          final shopAddress = shopData['address'] ?? 'Adres Bilinmiyor';

          return Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 5,
            shadowColor: primaryColor.withOpacity(0.5),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Mağaza bilgileri
                  Text(
                    'Mağaza Bilgileri',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildInfoRow('Mağaza ID', shopId),
                  const SizedBox(height: 4),
                  _buildInfoRow('Adı', shopName),
                  const SizedBox(height: 8),
                  _buildMultilineInfoRow('Adres', shopAddress),
                  const Divider(height: 20, thickness: 1),

                  // Rapor bilgileri
                  Text(
                    'Rapor Bilgileri',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildInfoRow('Konu', topic),
                  const SizedBox(height: 8),
                  _buildMultilineInfoRow('Mesaj', message),
                  const SizedBox(height: 8),
                  if (timestamp != null)
                    _buildInfoRow('Tarih', _formatTimestamp(timestamp)),
                  const SizedBox(height: 12),
                  _buildStatusChip(status),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '$label:',
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
        Flexible(
          child: Text(
            value,
            style: const TextStyle(fontSize: 14, color: Colors.black54),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildMultilineInfoRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label:',
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 14, color: Colors.black54),
          maxLines: 3, // Maksimum 3 satır
          overflow: TextOverflow.ellipsis, // Gerekirse üç nokta ile kes
        ),
      ],
    );
  }

  Widget _buildStatusChip(String status) {
    final statusColor = status == 'Bekleniyor'
        ? Colors.orange
        : status == 'İşleniyor'
            ? Colors.blue
            : Colors.green;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      decoration: BoxDecoration(
        color: statusColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    return '${timestamp.day}/${timestamp.month}/${timestamp.year} ${timestamp.hour}:${timestamp.minute}';
  }
}
