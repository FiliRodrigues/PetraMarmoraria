import 'package:flutter_test/flutter_test.dart';
import 'package:petra_erp/models/models.dart';
import 'package:petra_erp/pdf/os_pdf_generator.dart';
import 'package:petra_erp/core/constants/os_status.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Service Order PDF Generator Tests', () {
    final order = ServiceOrder(
      id: 'test-os-id-1234',
      displayNumber: 14,
      customerId: 'test-customer-id',
      customerName: 'Test Client',
      description: 'Test service order description with some custom notes.',
      status: OSStatus.aprovado,
      material: 'Granito Preto São Gabriel',
      edgeType: 'Meia Cana',
      totalValue: 1500.0,
      measurements: const {
        'items': [
          {
            'width': '1.20',
            'height': '0.60',
            'thickness': '2.0',
            'format': 'Retangular',
            'details': 'Bancada Cozinha',
          }
        ]
      },
      statusChangedAt: DateTime(2026, 5, 26, 12, 0),
      createdAt: DateTime(2026, 5, 26, 10, 0),
      updatedAt: DateTime(2026, 5, 26, 12, 0),
    );

    final customer = Customer(
      id: 'test-customer-id',
      name: 'Test Client',
      phone: '(11) 98765-4321',
      address: 'Rua das Flores, 123',
      city: 'São Paulo',
      state: 'SP',
      createdAt: DateTime(2026, 5, 1),
    );

    final assignments = [
      OrderAssignment(
        id: 'assign-1',
        orderId: 'test-os-id-1234',
        stage: 'corte',
        employeeId: 'emp-corte-id',
        employeeName: 'Carlos Cortador',
        assignedAt: DateTime(2026, 5, 26, 11, 0),
      ),
    ];

    final history = [
      StatusHistory(
        id: 'hist-1',
        orderId: 'test-os-id-1234',
        toStatus: OSStatus.aprovado,
        changedBy: 'user-seller-id',
        changedByName: 'Valdir Vendedor',
        changedAt: DateTime(2026, 5, 26, 10, 0),
      ),
    ];

    final profiles = [
      Profile(
        id: 'user-seller-id',
        email: 'valdir@petra.com.br',
        name: 'Valdir Vendedor',
        roles: const ['vendedor'],
        createdAt: DateTime(2026, 5, 1),
      ),
    ];

    test('generateServiceOrderPdf runs successfully and returns bytes', () async {
      final pdfBytes = await generateServiceOrderPdf(
        order: order,
        customer: customer,
        assignments: assignments,
        history: history,
        profiles: profiles,
      );

      expect(pdfBytes, isNotNull);
      expect(pdfBytes.length, greaterThan(0));
    });
  });
}
