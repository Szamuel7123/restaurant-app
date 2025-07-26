import 'package:flutter/material.dart';

class TransactionScreen extends StatelessWidget {
  const TransactionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final transactions = [
      {
        'date': '2024-06-01',
        'items': 'Jollof Rice, Kelewele',
        'total': 50.00,
        'status': 'Completed',
      },
      {
        'date': '2024-05-28',
        'items': 'Pizza (International)',
        'total': 60.00,
        'status': 'Completed',
      },
      {
        'date': '2024-05-25',
        'items': 'Waakye, Fried Rice & Chicken',
        'total': 68.00,
        'status': 'Pending',
      },
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Transactions')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: transactions.length,
        itemBuilder: (context, index) {
          final tx = transactions[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: ListTile(
              leading: Icon(
                tx['status'] == 'Completed' ? Icons.check_circle : Icons.hourglass_bottom,
                color: tx['status'] == 'Completed' ? Colors.green : Colors.orange,
              ),
              title: Text(tx['items'] as String),
              subtitle: Text('Date: ${tx['date']}'),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('₵${(tx['total'] as double).toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(tx['status'] as String, style: TextStyle(color: tx['status'] == 'Completed' ? Colors.green : Colors.orange)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
} 