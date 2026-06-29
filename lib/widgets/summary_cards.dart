import 'package:financehub/controllers/transaction_controller.dart';
import 'package:flutter/material.dart';

class SummaryCards extends StatelessWidget {
  final TransactionsController controller;

  const SummaryCards({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    double receitas = 0;
    double despesas = 0;

    for (final t in controller.items) {
      if (t.type == "income") {
        receitas += t.amount;
      } else {
        despesas += t.amount;
      }
    }

    final saldo = receitas - despesas;

    return Row(
      children: [
        Expanded(
          child: _card("Saldo", saldo),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _card("Receitas", receitas),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _card("Despesas", despesas),
        ),
      ],
    );
  }

  Widget _card(String titulo, double valor) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(titulo),
            const SizedBox(height: 10),
            Text(
              "R\$ ${valor.toStringAsFixed(2)}",
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}