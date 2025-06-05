import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart';
import 'dart:convert';
import 'dart:math';

void main() {
  runApp(BitcoinDCAApp());
}

class BitcoinDCAApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bitcoin DCA Calculator',
      theme: ThemeData(
        primarySwatch: Colors.orange,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: DCACalculatorScreen(),
    );
  }
}

class DCACalculatorScreen extends StatefulWidget {
  @override
  _DCACalculatorScreenState createState() => _DCACalculatorScreenState();
}

class _DCACalculatorScreenState extends State<DCACalculatorScreen> {
  final _investmentController = TextEditingController(text: '100');
  String _frequency = 'Weekly';
  DateTime _startDate = DateTime.now().subtract(Duration(days: 365));
  DateTime _endDate = DateTime.now();
  
  List<DCAData> _dcaData = [];
  bool _isLoading = false;
  bool _hasCalculated = false;
  
  double _totalInvested = 0;
  double _totalBitcoin = 0;
  double _currentValue = 0;
  double _totalReturn = 0;
  double _returnPercentage = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Bitcoin DCA Calculator'),
        backgroundColor: Colors.orange,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            _buildInputCard(),
            SizedBox(height: 20),
            if (_hasCalculated) ...[
              _buildResultsCard(),
              SizedBox(height: 20),
              _buildChartCard(),
              SizedBox(height: 20),
              _buildStatisticsCard(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInputCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'DCA Settings',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            
            // Investment Amount
            TextField(
              controller: _investmentController,
              decoration: InputDecoration(
                labelText: 'Investment Amount (\$)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.attach_money),
              ),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 16),
            
            // Frequency Dropdown
            DropdownButtonFormField<String>(
              value: _frequency,
              decoration: InputDecoration(
                labelText: 'Frequency',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.schedule),
              ),
              items: ['Daily', 'Weekly', 'Monthly'].map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _frequency = newValue!;
                });
              },
            ),
            SizedBox(height: 16),
            
            // Date Pickers
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _selectStartDate(context),
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Start Date',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.date_range),
                      ),
                      child: Text(
                        '${_startDate.day}/${_startDate.month}/${_startDate.year}',
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: InkWell(
                    onTap: () => _selectEndDate(context),
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'End Date',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.date_range),
                      ),
                      child: Text(
                        '${_endDate.day}/${_endDate.month}/${_endDate.year}',
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            
            // Calculate Button
            ElevatedButton(
              onPressed: _isLoading ? null : _calculateDCA,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _isLoading
                  ? CircularProgressIndicator(color: Colors.white)
                  : Text(
                      'Calculate DCA',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'DCA Results',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildResultItem(
                    'Total Invested',
                    '\$${_totalInvested.toStringAsFixed(2)}',
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildResultItem(
                    'Current Value',
                    '\$${_currentValue.toStringAsFixed(2)}',
                    Colors.green,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildResultItem(
                    'Total Bitcoin',
                    '${_totalBitcoin.toStringAsFixed(6)} BTC',
                    Colors.orange,
                  ),
                ),
                Expanded(
                  child: _buildResultItem(
                    'Total Return',
                    '${_totalReturn >= 0 ? '+' : ''}\$${_totalReturn.toStringAsFixed(2)}',
                    _totalReturn >= 0 ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _returnPercentage >= 0 ? Colors.green.shade50 : Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _returnPercentage >= 0 ? Icons.trending_up : Icons.trending_down,
                    color: _returnPercentage >= 0 ? Colors.green : Colors.red,
                    size: 24,
                  ),
                  SizedBox(width: 8),
                  Text(
                    '${_returnPercentage >= 0 ? '+' : ''}${_returnPercentage.toStringAsFixed(2)}%',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: _returnPercentage >= 0 ? Colors.green : Colors.red,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildChartCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'Portfolio Growth',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Container(
              height: 300,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 60,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '\$${(value / 1000).toStringAsFixed(0)}k',
                            style: TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() < _dcaData.length) {
                            final date = _dcaData[value.toInt()].date;
                            return Text(
                              '${date.month}/${date.year.toString().substring(2)}',
                              style: TextStyle(fontSize: 10),
                            );
                          }
                          return Text('');
                        },
                      ),
                    ),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    // Invested Amount Line
                    LineChartBarData(
                      spots: _dcaData.asMap().entries.map((e) {
                        return FlSpot(e.key.toDouble(), e.value.totalInvested);
                      }).toList(),
                      isCurved: true,
                      color: Colors.blue,
                      barWidth: 2,
                      dotData: FlDotData(show: false),
                    ),
                    // Portfolio Value Line
                    LineChartBarData(
                      spots: _dcaData.asMap().entries.map((e) {
                        return FlSpot(e.key.toDouble(), e.value.portfolioValue);
                      }).toList(),
                      isCurved: true,
                      color: Colors.green,
                      barWidth: 3,
                      dotData: FlDotData(show: false),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem('Invested', Colors.blue),
                SizedBox(width: 20),
                _buildLegendItem('Portfolio Value', Colors.green),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildStatisticsCard() {
    if (_dcaData.isEmpty) return Container();
    
    final avgPrice = _totalInvested / _totalBitcoin;
    final currentPrice = _dcaData.last.bitcoinPrice;
    final bestEntry = _dcaData.reduce((a, b) => a.bitcoinPrice < b.bitcoinPrice ? a : b);
    final worstEntry = _dcaData.reduce((a, b) => a.bitcoinPrice > b.bitcoinPrice ? a : b);
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'Statistics',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Average Price',
                    '\$${avgPrice.toStringAsFixed(2)}',
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Current Price',
                    '\$${currentPrice.toStringAsFixed(2)}',
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Best Entry',
                    '\$${bestEntry.bitcoinPrice.toStringAsFixed(2)}',
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Worst Entry',
                    '\$${worstEntry.bitcoinPrice.toStringAsFixed(2)}',
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            _buildStatItem(
              'Total Purchases',
              '${_dcaData.length}',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Future<void> _selectStartDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2010),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _startDate) {
      setState(() {
        _startDate = picked;
      });
    }
  }

  Future<void> _selectEndDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: _startDate,
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _endDate) {
      setState(() {
        _endDate = picked;
      });
    }
  }

  Future<void> _calculateDCA() async {
    setState(() {
      _isLoading = true;
      _hasCalculated = false;
    });

    try {
      final investmentAmount = double.parse(_investmentController.text);
      final dcaData = await _fetchHistoricalDataAndCalculate(investmentAmount);
      
      setState(() {
        _dcaData = dcaData;
        _calculateTotals();
        _hasCalculated = true;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error calculating DCA: $e')),
      );
    }
  }

  Future<List<DCAData>> _fetchHistoricalDataAndCalculate(double investmentAmount) async {
    // Generate purchase dates based on frequency
    final purchaseDates = _generatePurchaseDates();
    final dcaData = <DCAData>[];
    
    double totalInvested = 0;
    double totalBitcoin = 0;
    
    for (int i = 0; i < purchaseDates.length; i++) {
      final date = purchaseDates[i];
      
      // For demo purposes, we'll simulate historical prices
      // In a real app, you'd fetch actual historical data
      final price = _simulateHistoricalPrice(date);
      
      totalInvested += investmentAmount;
      final bitcoinPurchased = investmentAmount / price;
      totalBitcoin += bitcoinPurchased;
      
      final currentPrice = i == purchaseDates.length - 1 
          ? price 
          : _simulateHistoricalPrice(DateTime.now());
      
      dcaData.add(DCAData(
        date: date,
        investmentAmount: investmentAmount,
        bitcoinPrice: price,
        bitcoinPurchased: bitcoinPurchased,
        totalInvested: totalInvested,
        totalBitcoin: totalBitcoin,
        portfolioValue: totalBitcoin * (i == purchaseDates.length - 1 ? price : currentPrice),
      ));
    }
    
    return dcaData;
  }

  List<DateTime> _generatePurchaseDates() {
    final dates = <DateTime>[];
    var currentDate = _startDate;
    
    while (currentDate.isBefore(_endDate) || currentDate.isAtSameMomentAs(_endDate)) {
      dates.add(currentDate);
      
      switch (_frequency) {
        case 'Daily':
          currentDate = currentDate.add(Duration(days: 1));
          break;
        case 'Weekly':
          currentDate = currentDate.add(Duration(days: 7));
          break;
        case 'Monthly':
          currentDate = DateTime(
            currentDate.year,
            currentDate.month + 1,
            currentDate.day,
          );
          break;
      }
    }
    
    return dates;
  }

  double _simulateHistoricalPrice(DateTime date) {
    // This is a simplified simulation of Bitcoin price
    // In a real app, you'd fetch actual historical data from an API
    final now = DateTime.now();
    final daysDiff = now.difference(date).inDays;
    
    // Base price around current Bitcoin price with some volatility
    final basePrice = 45000.0;
    final volatility = sin(daysDiff * 0.1) * 10000 + Random().nextDouble() * 5000;
    final trendGrowth = (daysDiff / 365) * 15000; // Simulated growth over time
    
    return max(1000, basePrice - trendGrowth + volatility);
  }

  void _calculateTotals() {
    if (_dcaData.isEmpty) return;
    
    final lastEntry = _dcaData.last;
    _totalInvested = lastEntry.totalInvested;
    _totalBitcoin = lastEntry.totalBitcoin;
    
    // Get current Bitcoin price for final calculation
    final currentPrice = lastEntry.bitcoinPrice;
    _currentValue = _totalBitcoin * currentPrice;
    _totalReturn = _currentValue - _totalInvested;
    _returnPercentage = (_totalReturn / _totalInvested) * 100;
    
    // Update portfolio values with current price
    for (var data in _dcaData) {
      data.portfolioValue = data.totalBitcoin * currentPrice;
    }
  }
}

class DCAData {
  final DateTime date;
  final double investmentAmount;
  final double bitcoinPrice;
  final double bitcoinPurchased;
  final double totalInvested;
  final double totalBitcoin;
  double portfolioValue;

  DCAData({
    required this.date,
    required this.investmentAmount,
    required this.bitcoinPrice,
    required this.bitcoinPurchased,
    required this.totalInvested,
    required this.totalBitcoin,
    required this.portfolioValue,
  });
}