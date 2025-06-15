import 'investment_summary_dto.dart';
import 'investment_detail_dto.dart';

abstract class InvestmentRepository {
  Future<List<InvestmentSummaryDto>> fetchInvestments();
  Future<InvestmentDetailDto> createInvestment({
    required DateTime date,
    required String asset,
    required String amount,
  });
  Future<InvestmentDetailDto> updateInvestment({
    required int id,
    required DateTime date,
    required String asset,
    required String amount,
  });
  Future<InvestmentDetailDto> fetchInvestmentById(int id);
  Future<void> deleteInvestment(int id);
}
