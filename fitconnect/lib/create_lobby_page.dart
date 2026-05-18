import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart' as geo;
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'dart:async';
import 'lobby_service.dart';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class CreateLobbyPage extends StatefulWidget {
  const CreateLobbyPage({super.key});

  @override
  State<CreateLobbyPage> createState() => _CreateLobbyPageState();
}

class _CreateLobbyPageState extends State<CreateLobbyPage> {
  final LobbyService _lobbyService = LobbyService();

  final _titleController = TextEditingController();
  final _venueController = TextEditingController();

  // Sports Dropdown Control State
  List<String> _sportsList = [];
  String? _selectedSport;
  bool _isFetchingSports = true;

  // Advanced Interactive Map Control States
  GoogleMapController? _mapController;
  LatLng _mapCenter = const LatLng(3.1390, 101.6869); // Default fallback (Kuala Lumpur)
  Timer? _debounceTimer; // Prevents spamming API lookups while typing

  // Match Capacity State
  int _maxParticipants = 10;

  // Skill Category State Management
  final List<String> _availableSkills = ['Beginner', 'Intermediate', 'Competitive', 'Pro'];
  final List<String> _selectedSkills = [];
  bool _isOpenToAll = true;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _determineUserPosition();
  }

  /// 1. Fetches sports dropdown catalog from Supabase with an unblocking safety net
  Future<void> _loadInitialData() async {
    try {
      final list = await _lobbyService.fetchSportsList();
      setState(() {
        _sportsList = list;
        if (_sportsList.isNotEmpty) {
          _selectedSport = _sportsList[0];
        }
      });
    } catch (e) {
      debugPrint("Error loading sports inside initState pipeline: $e");
    } finally {
      setState(() => _isFetchingSports = false);
    }
  }

  /// 2. Requests native hardware permissions and sets the map default view to user position
  Future<void> _determineUserPosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    if (permission == LocationPermission.deniedForever) return;

    // Pull current physical device position smoothly
    Position position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high)
    );

    LatLng userLatLng = LatLng(position.latitude, position.longitude);

    setState(() {
      _mapCenter = userLatLng;
    });

    // Move map viewport cleanly over to the native location match line
    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: userLatLng, zoom: 15.0),
      ),
    );
  }

  /// 3. Geocoding listener: Translates user typed selection into coordinates on the fly
  void _moveMapToLocation(String chosenVenue) async {
    // Append regional context to guarantee the geocoding engine accurately places the pin
    String optimizedSearchQuery = "$chosenVenue, Kuala Lumpur, Malaysia";

    try {
      List<geo.Location> locations = await geo.locationFromAddress(optimizedSearchQuery);
      if (locations.isNotEmpty) {
        geo.Location place = locations.first;
        LatLng selectedCoords = LatLng(place.latitude, place.longitude);

        setState(() {
          _mapCenter = selectedCoords;
        });

        // Glide the map viewport directly over the target sports center
        _mapController?.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(target: selectedCoords, zoom: 16.0),
          ),
        );
      }
    } catch (e) {
      debugPrint("Could not resolve specific coordinate bounds for choice: $e");
    }
  }

  void _toggleSkill(String skill) {
    setState(() {
      _isOpenToAll = false;
      if (_selectedSkills.contains(skill)) {
        _selectedSkills.remove(skill);
        if (_selectedSkills.isEmpty) _isOpenToAll = true;
      } else {
        _selectedSkills.add(skill);
      }
    });
  }

  void _setOpenToAll() {
    setState(() {
      _isOpenToAll = true;
      _selectedSkills.clear();
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _venueController.dispose();
    _debounceTimer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("LAUNCH EVENT", style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isFetchingSports
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFF39FF14)),
                  SizedBox(height: 16),
                  Text("Syncing Sports Catalog...", style: TextStyle(color: Colors.white38, fontSize: 14))
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- LOBBY TITLE FIELD ---
                  const Text("LOBBY TITLE", style: TextStyle(color: Color(0xFF39FF14), fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 0.5)),
                  TextField(
                    controller: _titleController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: "e.g., Friday Night Casual Futsal",
                      hintStyle: TextStyle(color: Colors.white24),
                      enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white10)),
                      focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF39FF14))),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // --- SPORTS CATEGORY SELECTION ---
                  const Text("SPORT CATEGORY", style: TextStyle(color: Color(0xFF39FF14), fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 0.5)),
                  const SizedBox(height: 5),
                  DropdownButtonFormField<String>(
                    dropdownColor: const Color(0xFF141414),
                    initialValue: _selectedSport,
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    decoration: const InputDecoration(enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white10))),
                    items: _sportsList.map((sport) => DropdownMenuItem(value: sport, child: Text(sport))).toList(),
                    onChanged: (val) => setState(() => _selectedSport = val),
                  ),
                  const SizedBox(height: 30),

                  // --- TARGET SKILL LEVELS CHIPS ---
                  const Text("TARGET SKILL LEVELS", style: TextStyle(color: Color(0xFF39FF14), fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 0.5)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FilterChip(
                        label: const Text("Open to All"),
                        labelStyle: TextStyle(color: _isOpenToAll ? Colors.black : Colors.white60, fontWeight: FontWeight.bold),
                        selected: _isOpenToAll,
                        selectedColor: const Color(0xFF39FF14),
                        checkmarkColor: Colors.black,
                        backgroundColor: Colors.white.withValues(alpha: 0.05),
                        onSelected: (_) => _setOpenToAll(),
                      ),
                      ..._availableSkills.map((skill) {
                        bool isSelected = _selectedSkills.contains(skill);
                        return FilterChip(
                          label: Text(skill),
                          labelStyle: TextStyle(color: isSelected ? Colors.black : Colors.white60, fontWeight: FontWeight.bold),
                          selected: isSelected,
                          selectedColor: const Color(0xFF39FF14),
                          checkmarkColor: Colors.black,
                          backgroundColor: Colors.white.withValues(alpha: 0.05),
                          onSelected: (_) => _toggleSkill(skill),
                        );
                      }),
                    ],
                  ),
                  const SizedBox(height: 30),

                  // --- VENUE INPUT LINKED TO AUTOCOMPLETE TYPEAHEAD OVAL ---
                  const Text("VENUE / LOCATION NAME", style: TextStyle(color: Color(0xFF39FF14), fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 0.5)),
                  const SizedBox(height: 5),
                  TypeAheadField<String>(
                    controller: _venueController,
                    builder: (context, controller, focusNode) {
                      return TextField(
                        controller: controller,
                        focusNode: focusNode,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          hintText: "Type venue name (e.g., Futsalhub Ampang)",
                          hintStyle: TextStyle(color: Colors.white24),
                          enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white10)),
                          focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF39FF14))),
                        ),
                      );
                    },
                    suggestionsCallback: (search) async {
                      if (search.trim().isEmpty) return [];

                      // ⚠️ CRITICAL: Ensure this string contains your actual Google Cloud Console API Key!
                      const String apiKey = "AIzaSyAZ7Acnl13fSeiAF9InEp0RpbFPd7tGSYA";

                      if (apiKey.contains("PASTE_YOUR")) {
                        debugPrint("⚠️ FitConnect Warning: Google Maps API key is missing or default placeholder.");
                        return ['Type a specific location address...'];
                      }

                      // Explicit target URL for Google Places Autocomplete Endpoint
                      final String url =
                          "https://maps.googleapis.com/maps/api/place/autocomplete/json"
                          "?input=${Uri.encodeComponent(search)}"
                          "&components=country:my" // Locks search queries strictly to Malaysia venues
                          "&types=establishment"   // Prioritizes actual businesses, stadiums, and sports clubs!
                          "&key=$apiKey";

                      try {
                        // Send a structured HTTP GET request with standard browser headers
                        final response = await http.get(
                          Uri.parse(url),
                          headers: {"Accept": "application/json"},
                        );

                        if (response.statusCode == 200) {
                          final data = json.decode(response.body);

                          // If Google rejected your API key, it returns a specific status string in the JSON payload
                          if (data['status'] == 'REQUEST_DENIED') {
                            debugPrint("❌ Google API Error: ${data['error_message']}");
                            return ['API Configuration Error'];
                          }

                          final predictions = data['predictions'] as List<dynamic>;

                          return predictions
                              .map((p) => p['description']?.toString() ?? '')
                              .where((text) => text.isNotEmpty)
                              .toList();
                        } else {
                          debugPrint("HTTP Connection Failure: ${response.statusCode}");
                          return [];
                        }
                      } catch (e) {
                        debugPrint("Google Places Connection Pipeline Failure: $e");
                        return [];
                      }
                    },
                    itemBuilder: (context, String venueSuggestion) {
                      return Container(
                        color: const Color(0xFF141414),
                        child: ListTile(
                          leading: const Icon(Icons.location_on, color: Color(0xFF39FF14), size: 20),
                          title: Text(venueSuggestion, style: const TextStyle(color: Colors.white, fontSize: 14)),
                        ),
                      );
                    },
                    onSelected: (String chosenVenue) {
                      _venueController.text = chosenVenue;
                      _moveMapToLocation(chosenVenue);
                    },
                  ),
                  const SizedBox(height: 30),

                  // --- GOOGLE MAP LOCATION PREVIEW LAYER ---
                  const Text("MAP PREVIEW (DRAG TO CORNER ADJUST)", style: TextStyle(color: Color(0xFF39FF14), fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 0.5)),
                  const SizedBox(height: 12),
                  Container(
                    height: 220,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF39FF14).withValues(alpha: 0.3)),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(19),
                      child: Stack(
                        children: [
                          GoogleMap(
                            initialCameraPosition: CameraPosition(target: _mapCenter, zoom: 14.0),
                            myLocationEnabled: true,
                            myLocationButtonEnabled: false,
                            zoomControlsEnabled: false,
                            onMapCreated: (controller) => _mapController = controller,
                            onCameraMove: (position) {
                              _mapCenter = position.target; // Seamless coordinate collection on viewport slide actions
                            },
                          ),
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.only(bottom: 24),
                              child: Icon(Icons.location_on, color: Color(0xFF39FF14), size: 42),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // --- DYNAMIC MAX PARTICIPANTS COUNTER ROW ---
                  const Text("MAX PARTICIPANTS", style: TextStyle(color: Color(0xFF39FF14), fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 0.5)),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.03),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Player Limit Count", style: TextStyle(color: Colors.white60, fontSize: 15, fontWeight: FontWeight.w500)),
                        Row(
                          children: [
                            IconButton(
                              onPressed: () {
                                if (_maxParticipants > 2) {
                                  setState(() => _maxParticipants--);
                                }
                              },
                              icon: const Icon(Icons.remove_circle_outline, color: Colors.white60, size: 28),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                "$_maxParticipants",
                                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900),
                              ),
                            ), // <-- Verified matching parenthesis and brace for Padding here
                            IconButton(
                              onPressed: () {
                                if (_maxParticipants < 30) {
                                  setState(() => _maxParticipants++);
                                }
                              },
                              icon: const Icon(Icons.add_circle_outline, color: Color(0xFF39FF14), size: 28),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),

                  // --- SUBMIT PAYLOAD BUTTON ---
                  GestureDetector(
                    onTap: _submitLobby,
                    child: Container(
                      height: 55,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFF39FF14), Color(0xFF00FF87)]),
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF39FF14).withValues(alpha: 0.2),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          )
                        ],
                      ),
                      child: const Center(
                        child: Text("LAUNCH LOBBY", style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
    );
  }

  /// Dispatches structured payloads directly to Supabase
  void _submitLobby() async {
      final title = _titleController.text.trim();
      final venue = _venueController.text.trim();

      // 1. CAPTURE THE MESSENGER STATE AT THE VERY START FOR SYNCHRONOUS CHECKS
      final messenger = ScaffoldMessenger.of(context);
      final navigator = Navigator.of(context);

      if (title.isEmpty || venue.isEmpty) {
        messenger.showSnackBar(
          const SnackBar(content: Text("Please fill in all layout blocks before launching."), backgroundColor: Colors.redAccent),
        );
        return;
      }

      final skillsToSubmit = _isOpenToAll ? ['Open to All'] : _selectedSkills;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator(color: Color(0xFF39FF14))),
      );

      try {
        // Async network transaction with Supabase Database
        await _lobbyService.createLobby(
          title: title,
          sport: _selectedSport ?? "Futsal",
          locationName: venue,
          lat: _mapCenter.latitude,
          lng: _mapCenter.longitude,
          skills: skillsToSubmit,
          maxParticipants: _maxParticipants,
        );

        // 2. USE THE MOUNTED GUARD WITH CAPTURED NAVIGATOR STATE ON SUCCESS
        if (mounted) {
          navigator.pop(); // Remove progress loader HUD
          navigator.pop(); // Return backwards to main dashboard screen
        }
      } catch (e) {
        // 3. SECURE FALLBACK LOGIC IF THE DB TRANSACTION FAILS
        if (mounted) {
          navigator.pop(); // Dismiss loading spinner cleanly
        }
        
        // Use the safely captured messenger reference here
        messenger.showSnackBar(
          SnackBar(content: Text("Database Insertion Error: $e"), backgroundColor: Colors.redAccent),
        );
      }
    }
}