import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';

class TacticalCommandHub extends StatefulWidget {
  final String slotId;
  final String callsign;
  final String initialStatus;

  const TacticalCommandHub({
    super.key,
    required this.slotId,
    required this.callsign,
    required this.initialStatus,
  });

  @override
  State<TacticalCommandHub> createState() => _TacticalCommandHubState();
}

class _TacticalCommandHubState extends State<TacticalCommandHub> {
  int _tabIndex = 0;
  late String _currentStatus;
  late String _currentCallsign;
  StreamSubscription<Position>? _gpsSub;
  LatLng _myPos = const LatLng(10.8505, 76.2711);

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.initialStatus;
    _currentCallsign = widget.callsign;
    _startHighPrecisionGps();
  }

  Future<void> _startHighPrecisionGps() async {
    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.deniedForever) return;

    _gpsSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 2,
      ),
    ).listen((pos) {
      setState(() => _myPos = LatLng(pos.latitude, pos.longitude));
      FirebaseFirestore.instance.collection('squad').doc(widget.slotId).set({
        'slot': widget.slotId,
        'callsign': _currentCallsign,
        'status': _currentStatus,
        'lat': pos.latitude,
        'lng': pos.longitude,
        'speed': pos.speed,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  void _updateStatusOrCallsign() {
    final nameCtrl = TextEditingController(text: _currentCallsign);
    String tempStatus = _currentStatus;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF0E1318),
        title: const Text("UPDATE CALLSIGN & STATUS",
            style: TextStyle(fontFamily: 'monospace', fontSize: 14)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              style: const TextStyle(fontFamily: 'monospace'),
              decoration: const InputDecoration(labelText: "CALLSIGN"),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: tempStatus,
              dropdownColor: const Color(0xFF0E1318),
              items: ["IN POSITION", "MOVING", "ENGAGED", "OVERWATCH"]
                  .map((s) => DropdownMenuItem(
                      value: s,
                      child: Text(s, style: const TextStyle(fontFamily: 'monospace'))))
                  .toList(),
              onChanged: (v) => tempStatus = v ?? tempStatus,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _currentCallsign = nameCtrl.text.trim().toUpperCase();
                _currentStatus = tempStatus;
              });
              FirebaseFirestore.instance.collection('squad').doc(widget.slotId).update({
                'callsign': _currentCallsign,
                'status': _currentStatus,
              });
              Navigator.pop(context);
            },
            child: const Text("SAVE", style: TextStyle(color: Color(0xFF00F0FF))),
          )
        ],
      ),
    );
  }

  @override
  void dispose() {
    _gpsSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isWideScreen = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color(0xFF090C0F),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "TF-141 // $_currentCallsign [$_currentStatus]",
              style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 13,
                  color: Color(0xFFD0D8E0),
                  fontWeight: FontWeight.bold),
            ),
            Text(
              "LAT:${_myPos.latitude.toStringAsFixed(5)} LON:${_myPos.longitude.toStringAsFixed(5)}",
              style: const TextStyle(
                  fontFamily: 'monospace', fontSize: 10, color: Color(0xFF00F0FF)),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune, color: Color(0xFFD0D8E0)),
            onPressed: _updateStatusOrCallsign,
          ),
        ],
      ),
      body: isWideScreen
          ? Row(
              children: [
                Expanded(flex: 3, child: GodsEyeSatelliteMap(myPos: _myPos)),
                Container(width: 1, color: const Color(0xFF1F2B36)),
                Expanded(flex: 2, child: SquadCommsFeed(callsign: _currentCallsign)),
              ],
            )
          : (_tabIndex == 0
              ? GodsEyeSatelliteMap(myPos: _myPos)
              : SquadCommsFeed(callsign: _currentCallsign)),
      bottomNavigationBar: isWideScreen
          ? null
          : BottomNavigationBar(
              backgroundColor: const Color(0xFF090C0F),
              selectedItemColor: const Color(0xFF00F0FF),
              unselectedItemColor: const Color(0xFF6B7785),
              currentIndex: _tabIndex,
              onTap: (i) => setState(() => _tabIndex = i),
              items: const [
                BottomNavigationBarItem(
                    icon: Icon(Icons.public), label: "GOD'S EYE SAT"),
                BottomNavigationBarItem(
                    icon: Icon(Icons.forum), label: "SQUAD COMMS"),
              ],
            ),
    );
  }
}

class GodsEyeSatelliteMap extends StatefulWidget {
  final LatLng myPos;
  const GodsEyeSatelliteMap({super.key, required this.myPos});

  @override
  State<GodsEyeSatelliteMap> createState() => _GodsEyeSatelliteMapState();
}

class _GodsEyeSatelliteMapState extends State<GodsEyeSatelliteMap> {
  final MapController _mapCtrl = MapController();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('squad').snapshots(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];
        final markers = docs.map((d) {
          final data = d.data() as Map<String, dynamic>;
          final pos = LatLng(
            (data['lat'] ?? widget.myPos.latitude).toDouble(),
            (data['lng'] ?? widget.myPos.longitude).toDouble(),
          );
          final callsign = data['callsign'] ?? 'UNIT';
          final status = data['status'] ?? 'ONLINE';
          final isEngaged = status == 'ENGAGED';

          return Marker(
            point: pos,
            width: 140,
            height: 70,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.85),
                    border: Border.all(
                      color: isEngaged ? Colors.redAccent : const Color(0xFF00F0FF),
                    ),
                  ),
                  child: Text(
                    "$callsign\n[$status]",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isEngaged ? Colors.redAccent : const Color(0xFF00F0FF),
                      fontSize: 9,
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Icon(
                  Icons.my_location,
                  color: isEngaged ? Colors.redAccent : const Color(0xFF39FF14),
                  size: 24,
                ),
              ],
            ),
          );
        }).toList();

        return Stack(
          children: [
            FlutterMap(
              mapController: _mapCtrl,
              options: MapOptions(
                initialCenter: widget.myPos,
                initialZoom: 16.5,
                maxZoom: 20,
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://server.' + 'arcgisonline' + '.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
                  userAgentPackageName: 'com.tf141.tactical',
                ),
                TileLayer(
                  urlTemplate:
                      'https://services.' + 'arcgisonline' + '.com/ArcGIS/rest/services/Reference/World_Boundaries_and_Places/MapServer/tile/{z}/{y}/{x}',
                  userAgentPackageName: 'com.tf141.tactical',
                ),
                MarkerLayer(markers: markers),
              ],
            ),
            Positioned(
              top: 10,
              left: 10,
              right: 10,
              child: Container(
                padding: const EdgeInsets.all(8),
                color: Colors.black.withOpacity(0.82),
                child: Wrap(
                  spacing: 12,
                  children: docs.map((d) {
                    final data = d.data() as Map<String, dynamic>;
                    
