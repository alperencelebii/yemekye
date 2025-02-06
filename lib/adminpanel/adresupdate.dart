import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddressUpdateScreen extends StatefulWidget {
  @override
  _AddressUpdateScreenState createState() => _AddressUpdateScreenState();
}

class _AddressUpdateScreenState extends State<AddressUpdateScreen> {
  List<dynamic> _addressData = [];
  List<String> _cities = [];
  List<Map<String, dynamic>> _districts = [];
  List<Map<String, dynamic>> _neighborhoods = [];

  String? _selectedCity;
  String? _selectedDistrict;
  String? _selectedNeighborhood;
  TextEditingController _addressDetailsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadAddressData();
  }

  Future<void> _loadAddressData() async {
    String data = await rootBundle.loadString('assets/adresler.json');
    List<dynamic> jsonResult = json.decode(data);
    setState(() {
      _addressData = jsonResult;
      _cities = _addressData.map((e) => e["sehir_adi"].toString()).toList();
    });
  }

  void _selectCity(String? city) {
    if (city == null) return;
    var selectedCityData =
        _addressData.firstWhere((e) => e["sehir_adi"] == city);
    setState(() {
      _selectedCity = city;
      _selectedDistrict = null;
      _selectedNeighborhood = null;
      _districts = List<Map<String, dynamic>>.from(selectedCityData["ilceler"]);
      _neighborhoods = [];
      _addressDetailsController.clear();
    });
  }

  void _selectDistrict(String? district) {
    if (district == null) return;
    var selectedDistrictData =
        _districts.firstWhere((e) => e["ilce_adi"] == district);
    setState(() {
      _selectedDistrict = district;
      _selectedNeighborhood = null;
      _neighborhoods =
          List<Map<String, dynamic>>.from(selectedDistrictData["mahalleler"]);
      _addressDetailsController.clear();
    });
  }

  void _selectNeighborhood(String? neighborhood) {
    setState(() {
      _selectedNeighborhood = neighborhood;
      _addressDetailsController.clear();
    });
  }

  Future<void> _saveAddress() async {
    if (_selectedCity != null &&
        _selectedDistrict != null &&
        _selectedNeighborhood != null) {
      String fullAddress =
          "$_selectedNeighborhood, ${_addressDetailsController.text.toUpperCase()}, $_selectedDistrict, $_selectedCity";

      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('sellers')
          .doc(currentUser.uid)
          .get();

      if (!userDoc.exists || userDoc['shopid'] == null) return;

      String shopId = userDoc['shopid'];

      await FirebaseFirestore.instance
          .collection('shops')
          .doc(shopId)
          .update({'address': fullAddress});

      Navigator.pop(context, fullAddress);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Lütfen adresinizi tam seçiniz.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Adresi Güncelle"),
        backgroundColor: Colors.orange,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDropdown("Şehir Seç", _cities, _selectedCity, _selectCity),
            if (_selectedCity != null)
              _buildDropdown(
                  "İlçe Seç",
                  _districts.map((e) => e["ilce_adi"].toString()).toList(),
                  _selectedDistrict,
                  _selectDistrict),
            if (_selectedDistrict != null)
              _buildDropdown(
                  "Mahalle Seç",
                  _neighborhoods
                      .map((e) => e["mahalle_adi"].toString())
                      .toList(),
                  _selectedNeighborhood,
                  _selectNeighborhood),
            if (_selectedNeighborhood != null) _buildAddressDetailsField(),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveAddress,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text("Kaydet", style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown(String title, List<String> items, String? selectedItem,
      ValueChanged<String?> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
          value: selectedItem,
          hint: Text(title),
          isExpanded: true,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          ),
          items: items
              .map((item) => DropdownMenuItem(
                    value: item,
                    child: Text(item),
                  ))
              .toList(),
          onChanged: onChanged,
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _buildAddressDetailsField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Adres Detayları",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        TextField(
          controller: _addressDetailsController,
          decoration: InputDecoration(
            hintText: "Apartman, No, Kat...",
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }
}
