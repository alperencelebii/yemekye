import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:yemekye/qrandsepet/user/sepet.dart';
import 'package:intl/intl.dart';

class ProductCard extends StatelessWidget {
  final String shopId;
  final String productId;
  final String productName;
  final double productPrice;
  final int piece;
  final bool isOpen;

  const ProductCard({
    Key? key,
    required this.shopId,
    required this.productId,
    required this.productName,
    required this.productPrice,
    required this.piece,
    required this.isOpen,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('campaigns')
          .where('productid', isEqualTo: productId)
          .snapshots(),
      builder: (context, snapshot) {
        bool hasCampaign = false;
        double? discountPrice;
        String? campaignLabel;
        DateTime? startTime;
        DateTime? endTime;

        if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
          var campaignData = snapshot.data!.docs.first;
          int discountPercent = campaignData['discount'];
          discountPrice = productPrice * (1 - discountPercent / 100);
          startTime = (campaignData['start_time'] as Timestamp).toDate();
          endTime = (campaignData['end_time'] as Timestamp).toDate();

          DateTime now = DateTime.now();
          hasCampaign = now.isAfter(startTime) && now.isBefore(endTime);

          if (endTime.isBefore(now)) {
            FirebaseFirestore.instance
                .collection('campaigns')
                .doc(campaignData.id)
                .delete();
          } else {
            campaignLabel = "İndirim! %$discountPercent";
          }
        }

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(50),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.3),
                  spreadRadius: 2,
                  blurRadius: 5,
                  offset: const Offset(0, 3),
                ),
              ],
              border: hasCampaign
                  ? Border.all(color: Colors.amber, width: 2)
                  : null,
            ),
            child: Stack(
              children: [
                Row(
                  children: [
                    const SizedBox(width: 10),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(50),
                        child: Image.asset(
                          'assets/images/images.jpeg',
                          width: 54,
                          height: 54,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            productName,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              fontFamily: 'BeVietnamPro',
                              color:
                                  piece == 0 ? Colors.red : Color(0xFF353535),
                              decoration: piece == 0
                                  ? TextDecoration.lineThrough
                                  : TextDecoration.none,
                            ),
                          ),
                          const SizedBox(height: 4),
                          hasCampaign
                              ? Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          "₺${productPrice.toStringAsFixed(2)}",
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey.shade600,
                                            decoration:
                                                TextDecoration.lineThrough,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          "₺${discountPrice!.toStringAsFixed(2)}",
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.red,
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (endTime != null)
                                      Text(
                                        "⏳ ${DateFormat('HH:mm').format(endTime)}'e kadar",
                                        style: TextStyle(
                                            color: Colors.black54,
                                            fontSize: 12),
                                      ),
                                  ],
                                )
                              : Text(
                                  "₺${productPrice.toStringAsFixed(2)}",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                        ],
                      ),
                    ),
                    Text(
                      piece == 0 ? 'Stok Kalmadı' : '$piece Adet Kaldı',
                      style: TextStyle(
                        fontFamily: 'BeVietnamPro',
                        fontSize: 13,
                        color: piece == 0 ? Colors.red : Color(0xFF353535),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (piece > 0)
                      GestureDetector(
                        onTap: () {
                          CartManager.addToCart(
                              shopId,
                              productId,
                              productName,
                              hasCampaign ? discountPrice! : productPrice,
                              piece,
                              context,
                              isOpen);
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF1D1D1D),
                            borderRadius: BorderRadius.circular(50),
                          ),
                          width: 40,
                          height: 40,
                          child: const Icon(
                            Icons.add_shopping_cart,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    const SizedBox(width: 16),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
