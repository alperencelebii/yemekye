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
        DateTime? endTime;

        if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
          var campaignData = snapshot.data!.docs.first;
          int discountPercent = campaignData['discount'];
          discountPrice = productPrice * (1 - discountPercent / 100);
          endTime = (campaignData['end_time'] as Timestamp).toDate();
          hasCampaign = endTime.isAfter(DateTime.now()); // Kampanya aktif mi?

          if (!hasCampaign) {
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
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              fontFamily: 'BeVietnamPro',
                              color: Color(0xFF353535),
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
                      '$piece Adet Kaldı',
                      style: const TextStyle(
                        fontFamily: 'BeVietnamPro',
                        fontSize: 13,
                        color: Color(0xFF353535),
                      ),
                    ),
                    const SizedBox(width: 8),
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

                // Kampanya etiketi
                if (hasCampaign)
                  Positioned(
                    top: 0,
                    left: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(50),
                          bottomRight: Radius.circular(12),
                        ),
                      ),
                      child: Text(
                        campaignLabel!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
