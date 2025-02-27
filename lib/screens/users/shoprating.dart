import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RatingDialog extends StatefulWidget {
  final String shopId;

  RatingDialog({required this.shopId});

  @override
  _RatingDialogState createState() => _RatingDialogState();
}

class _RatingDialogState extends State<RatingDialog> {
  double _serviceQualityRating = 0;
  double _freshnessRating = 0;
  double _hygieneRating = 0;

  void _submitRating() async {
    try {
      final firestore = FirebaseFirestore.instance;

      // Puanları Firestore'a kaydet
      await firestore.collection('ratings').add({
        'shopId': widget.shopId,
        'serviceQuality': _serviceQualityRating,
        'freshness': _freshnessRating,
        'hygiene': _hygieneRating,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Mağaza puanını güncelle
      await _updateShopRating();

      // Puanlama işlemi tamamlandığında kullanıcıyı bilgilendir
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Puanlama başarıyla kaydedildi')),
      );

      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Puanlama işlemi sırasında hata oluştu')),
      );
    }
  }

  Future<void> _updateShopRating() async {
    final firestore = FirebaseFirestore.instance;
    final ratingsSnapshot = await firestore
        .collection('ratings')
        .where('shopId', isEqualTo: widget.shopId)
        .get();

    double totalServiceQuality = 0;
    double totalFreshness = 0;
    double totalHygiene = 0;

    for (var doc in ratingsSnapshot.docs) {
      totalServiceQuality += doc['serviceQuality'] as double;
      totalFreshness += doc['freshness'] as double;
      totalHygiene += doc['hygiene'] as double;
    }

    int totalRatings = ratingsSnapshot.docs.length;

    double averageServiceQuality = totalRatings > 0
        ? totalServiceQuality / totalRatings
        : 0.0;
    double averageFreshness = totalRatings > 0 ? totalFreshness / totalRatings : 0.0;
    double averageHygiene = totalRatings > 0 ? totalHygiene / totalRatings : 0.0;

    double averageRating = (averageServiceQuality + averageFreshness + averageHygiene) / 3;

    // Mağazanın puanını güncelle
    await firestore.collection('shops').doc(widget.shopId).update({
      'rating': averageRating,
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Mağazayı Puanla'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildRatingRow('Hizmet Kalitesi', _serviceQualityRating,
              (rating) => setState(() => _serviceQualityRating = rating)),
          _buildRatingRow('Tazelik', _freshnessRating,
              (rating) => setState(() => _freshnessRating = rating)),
          _buildRatingRow('Hijyen', _hygieneRating,
              (rating) => setState(() => _hygieneRating = rating)),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('İptal'),
        ),
        ElevatedButton(
          onPressed: _submitRating,
          child: Text('Puanla'),
        ),
      ],
    );
  }

  Widget _buildRatingRow(String label, double rating, ValueChanged<double> onRatingChanged) {
    return Row(
      children: [
        Text(label),
        IconButton(
          icon: Icon(Icons.star, color: rating >= 1 ? Colors.yellow : Colors.grey),
          onPressed: () => onRatingChanged(1),
        ),
        IconButton(
          icon: Icon(Icons.star, color: rating >= 2 ? Colors.yellow : Colors.grey),
          onPressed: () => onRatingChanged(2),
        ),
        IconButton(
          icon: Icon(Icons.star, color: rating >= 3 ? Colors.yellow : Colors.grey),
          onPressed: () => onRatingChanged(3),
        ),
        IconButton(
          icon: Icon(Icons.star, color: rating >= 4 ? Colors.yellow : Colors.grey),
          onPressed: () => onRatingChanged(4),
        ),
        IconButton(
          icon: Icon(Icons.star, color: rating >= 5 ? Colors.yellow : Colors.grey),
          onPressed: () => onRatingChanged(5),
        ),
      ],
    );
  }
}