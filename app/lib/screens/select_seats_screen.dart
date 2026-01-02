import 'package:flutter/material.dart';
import '../models/flight_seat.dart';
import '../core/api/api_service.dart';

class SelectSeatsScreen extends StatefulWidget {
  final String flightId;

  const SelectSeatsScreen({super.key, required this.flightId});

  @override
  State<SelectSeatsScreen> createState() => _SelectSeatsScreenState();
}

class _SelectSeatsScreenState extends State<SelectSeatsScreen> {
  final List<FlightSeat> _seats = [];
  final List<String> _selectedSeats = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchSeats();
  }

  Future<void> _fetchSeats() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final api = ApiService();
      final data = await api.getFlightSeats(widget.flightId);
      final List seatsData = data['seats'];
      
      setState(() {
        _seats.clear();
        for (var s in seatsData) {
          _seats.add(FlightSeat(
            seatNumber: s['seat_number'],
            category: s['category'] == 'EXTRA_LEGROOM' 
                ? SeatCategory.extraLegroom 
                : SeatCategory.standard,
            status: s['is_available'] ? SeatStatus.available : SeatStatus.occupied,
          ));
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  void _toggleSeat(FlightSeat seat) {
    if (seat.status == SeatStatus.occupied) return;

    setState(() {
      if (seat.status == SeatStatus.selected) {
        seat.status = SeatStatus.available;
        _selectedSeats.remove(seat.seatNumber);
      } else {
        seat.status = SeatStatus.selected;
        _selectedSeats.add(seat.seatNumber);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Your Seats'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchSeats,
          ),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : _error != null
          ? Center(child: Text('Error: $_error', style: const TextStyle(color: Colors.red)))
          : Column(
              children: [
                _buildLegend(),
                const Divider(),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    // Grouping seats by row manually for display
                    itemCount: (_seats.length / 6).ceil(), 
                    itemBuilder: (context, index) {
                      final start = index * 6;
                      final end = (start + 6) > _seats.length ? _seats.length : (start + 6);
                      final rowSeats = _seats.sublist(start, end);
                      final rowNum = (start / 6).floor() + 1;
                      return _buildSeatRow(rowNum, rowSeats);
                    },
                  ),
                ),
                _buildBottomSummary(),
              ],
            ),
    );
  }

  Widget _buildLegend() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _LegendItem(color: Colors.grey.shade300, label: 'Available'),
          _LegendItem(color: Colors.blue, label: 'Selected'),
          _LegendItem(color: Colors.red.shade300, label: 'Occupied'),
          _LegendItem(color: Colors.amber.shade200, label: 'Extra Leg'),
        ],
      ),
    );
  }

  Widget _buildSeatRow(int rowNum, List<FlightSeat> rowSeats) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 24),
      child: Row(
        children: [
          SizedBox(width: 30, child: Text('$rowNum', style: const TextStyle(color: Colors.grey))),
          ...rowSeats.take(3).map((s) => _buildSeatBox(s)),
          const Spacer(),
          ...rowSeats.skip(3).map((s) => _buildSeatBox(s)),
        ],
      ),
    );
  }

  Widget _buildSeatBox(FlightSeat seat) {
    Color color = Colors.grey.shade300;
    if (seat.status == SeatStatus.selected) color = Colors.blue;
    if (seat.status == SeatStatus.occupied) color = Colors.red.shade200;
    if (seat.status == SeatStatus.available && seat.category == SeatCategory.extraLegroom) {
      color = Colors.amber.shade100;
    }

    return GestureDetector(
      onTap: () => _toggleSeat(seat),
      child: Container(
        width: 40,
        height: 40,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(6),
          border: seat.status == SeatStatus.selected ? Border.all(color: Colors.blue.shade800, width: 2) : null,
        ),
        child: Center(
          child: Text(
            seat.seatNumber.replaceAll(RegExp(r'[0-9]'), ''),
            style: TextStyle(
              fontSize: 12,
              color: seat.status == SeatStatus.selected ? Colors.white : Colors.black54,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomSummary() {
    if (_selectedSeats.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${_selectedSeats.length} Seats Selected', style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(_selectedSeats.join(', '), style: const TextStyle(color: Colors.blue)),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  '/booking',
                  arguments: {
                    'flightId': widget.flightId,
                    'selectedSeats': _selectedSeats,
                  },
                );
              },
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12)),
              child: const Text('CONFIRM'),
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 10)),
      ],
    );
  }
}
