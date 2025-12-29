import 'package:flutter/material.dart';
import '../../data/models/vendor_request_model.dart';

class RequestDetailScreen extends StatelessWidget {
  final VendorRequestModel request;
  const RequestDetailScreen({Key? key, required this.request})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    double titleSize = MediaQuery.of(context).size.width > 600 ? 24 : 18;

    return Scaffold(
      appBar: AppBar(title: const Text("Vendor Request Details")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Vendor Info Card
            Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundImage: NetworkImage(request.vendorImage),
                ),
                title: Text(
                  request.vendorName,
                  style: TextStyle(fontSize: titleSize),
                ),
                subtitle: const Text("Vendor ID: Verified"),
              ),
            ),
            const SizedBox(height: 20),

            // Product Request Details
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Request: ${request.requestType.toUpperCase()}",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    Image.network(
                      request.productImage,
                      height: 150,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      request.productName,
                      style: TextStyle(
                        fontSize: titleSize,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(request.productDescription),
                    const SizedBox(height: 10),
                    Text(
                      "Price: ${request.productPrice}",
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
