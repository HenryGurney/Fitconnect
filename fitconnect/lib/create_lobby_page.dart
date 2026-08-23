import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart' as geo;
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'lobby_service.dart';
import 'models/models.dart';
import 'services/profile_service.dart';
import 'widgets/premium_upgrade_modal.dart';
import 'widgets/pro_badge_widget.dart';

class CreateLobbyPage extends StatefulWidget {
  const CreateLobbyPage({super.key});

  @override
  State<CreateLobbyPage> createState() => _CreateLobbyPageState();
}

class _CreateLobbyPageState extends State<CreateLobbyPage> {
  final LobbyService _lobbyService = LobbyService();
  final ProfileService _profileService = ProfileService();

  final _titleController = TextEditingController();
  final _venueController = TextEditingController();
  final _customFeeController = TextEditingController();

  // Profile & PRO State
  ProfileModel? _userProfile;
  bool _isSpotlight = false;

  // Sports Visual Selector State
  List<String> _sportsList = [];
  String _selectedSport = 'Futsal';
  bool _isFetchingSports = true;

  // Advanced Interactive Map Control States
  GoogleMapController? _mapController;
  LatLng _mapCenter = const LatLng(3.1390, 101.6869); // Default (Kuala Lumpur)
  Timer? _debounceTimer;
  bool _isLocating = false;

  // Date and Time Control States
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedTime = const TimeOfDay(hour: 20, minute: 0);

  // Match Capacity & Presets State
  int _maxParticipants = 10;

  // Gender Restriction State
  String _selectedGender = 'Mixed / All Welcome';
  final List<String> _genderOptions = const [
    'Mixed / All Welcome',
    'Male Only',
    'Female Only',
  ];

  // Court Fee Split State
  String _selectedFee = 'Free (Casual)';
  final List<String> _feeOptions = const [
    'Free (Casual)',
    'RM 5 / pax',
    'RM 10 / pax',
    'RM 15 / pax',
    'RM 20 / pax',
    'Custom',
  ];

  // Skill Category State Management
  final List<String> _availableSkills = ['Beginner', 'Intermediate', 'Competitive', 'Pro'];
  final List<String> _selectedSkills = [];
  bool _isOpenToAll = true;

  // Sports Icons Mapping
  static const Map<String, String> _sportIcons = {
    'Futsal': '⚽',
    'Football': '⚽',
    'Badminton': '🏸',
    'Tennis': '🎾',
    'Pickleball': '🏓',
    'Basketball': '🏀',
    'Volleyball': '🏐',
    'Running': '🏃',
  };

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _determineUserPosition();
  }

  Future<void> _loadInitialData() async {
    try {
      final prof = await _profileService.getCurrentProfile();
      final list = await _lobbyService.fetchSportsList();
      if (mounted) {
        setState(() {
          _userProfile = prof;
          _isSpotlight = prof?.isPremium ?? false;
          _sportsList = list;
          if (_sportsList.isNotEmpty) {
            _selectedSport = _sportsList[0];
            _applySportPlayerPreset(_selectedSport);
          }
        });
      }
    } catch (e) {
      debugPrint("Error loading initial data: $e");
    } finally {
      if (mounted) setState(() => _isFetchingSports = false);
    }
  }

  /// Sets smart team size default presets based on the chosen sport
  void _applySportPlayerPreset(String sport) {
    switch (sport) {
      case 'Pickleball':
      case 'Badminton':
      case 'Tennis':
        _maxParticipants = 4; // Doubles
        break;
      case 'Futsal':
        _maxParticipants = 10; // 5v5
        break;
      case 'Football':
        _maxParticipants = 14; // 7v7
        break;
      case 'Basketball':
        _maxParticipants = 6; // 3v3
        break;
      case 'Volleyball':
        _maxParticipants = 12; // 6v6
        break;
      case 'Running':
        _maxParticipants = 10;
        break;
      default:
        _maxParticipants = 10;
    }
  }

  List<int> _getPlayerPresetsForSport(String sport) {
    switch (sport) {
      case 'Pickleball':
      case 'Badminton':
      case 'Tennis':
        return [2, 4, 6, 8];
      case 'Futsal':
        return [10, 12, 14, 16];
      case 'Football':
        return [14, 16, 20, 22];
      case 'Basketball':
        return [6, 10, 12];
      case 'Volleyball':
        return [12, 14, 16];
      case 'Running':
        return [5, 10, 20, 30];
      default:
        return [4, 8, 10, 12];
    }
  }

  /// 1-Tap Auto Title Generator
  void _generateAutoTitle() {
    final now = DateTime.now();
    String dayPrefix;
    if (_selectedDate.day == now.day && _selectedDate.month == now.month) {
      dayPrefix = "Tonight's";
    } else if (_selectedDate.day == now.add(const Duration(days: 1)).day) {
      dayPrefix = "Tomorrow's";
    } else {
      const weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
      dayPrefix = weekdays[_selectedDate.weekday - 1];
    }

    String timeOfDay = "Session";
    if (_selectedTime.hour < 12) {
      timeOfDay = "Morning";
    } else if (_selectedTime.hour < 18) {
      timeOfDay = "Afternoon";
    } else {
      timeOfDay = "Night";
    }

    String title;
    switch (_selectedSport) {
      case 'Pickleball':
        title = "$dayPrefix $timeOfDay Pickleball Rally 🏓";
        break;
      case 'Futsal':
        title = "$dayPrefix $timeOfDay 5v5 Futsal ⚽";
        break;
      case 'Football':
        title = "$dayPrefix Casual Football Match ⚽";
        break;
      case 'Badminton':
        title = "$dayPrefix $timeOfDay Badminton Doubles 🏸";
        break;
      case 'Tennis':
        title = "$dayPrefix Tennis Rally & Drill 🎾";
        break;
      case 'Basketball':
        title = "$dayPrefix Pick-Up Basketball 🏀";
        break;
      case 'Volleyball':
        title = "$dayPrefix Friendly Volleyball 🏐";
        break;
      case 'Running':
        title = "$dayPrefix $timeOfDay Community Run 🏃";
        break;
      default:
        title = "$dayPrefix $_selectedSport Match";
    }

    setState(() {
      _titleController.text = title;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.auto_awesome, color: Color(0xFF39FF14), size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text("Generated: \"$title\"")),
          ],
        ),
        backgroundColor: const Color(0xFF1E1E1E),
        duration: const Duration(milliseconds: 1500),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// 1-Tap Locate Me & Auto-Fill Venue Address
  Future<void> _locateMeAndFillAddress() async {
    setState(() => _isLocating = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );

      final userLatLng = LatLng(position.latitude, position.longitude);
      setState(() => _mapCenter = userLatLng);

      _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(CameraPosition(target: userLatLng, zoom: 16.0)),
      );

      final placemarks = await geo.placemarkFromCoordinates(position.latitude, position.longitude);
      if (placemarks.isNotEmpty) {
        final p = placemarks[0];
        final name = p.name ?? '';
        final street = p.street ?? '';
        final locality = p.locality ?? p.subAdministrativeArea ?? 'Kuala Lumpur';

        final venueName = (name.isNotEmpty && !street.contains(name)) ? "$name, $street, $locality" : "$street, $locality";

        setState(() {
          _venueController.text = venueName;
        });
      }
    } catch (e) {
      debugPrint("Locate Me error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Could not retrieve current location.")),
        );
      }
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  Future<void> _determineUserPosition() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
        Position position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium),
        );
        final userLatLng = LatLng(position.latitude, position.longitude);
        if (mounted) {
          setState(() => _mapCenter = userLatLng);
          _mapController?.animateCamera(
            CameraUpdate.newCameraPosition(CameraPosition(target: userLatLng, zoom: 15.0)),
          );
        }
      }
    } catch (_) {}
  }

  void _moveMapToLocation(String chosenVenue) async {
    try {
      List<geo.Location> locations = await geo.locationFromAddress("$chosenVenue, Malaysia");
      if (locations.isNotEmpty) {
        geo.Location place = locations.first;
        LatLng selectedCoords = LatLng(place.latitude, place.longitude);
        setState(() => _mapCenter = selectedCoords);
        _mapController?.animateCamera(
          CameraUpdate.newCameraPosition(CameraPosition(target: selectedCoords, zoom: 16.0)),
        );
      }
    } catch (e) {
      debugPrint("Geocoding lookup error: $e");
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF39FF14),
              onPrimary: Colors.black,
              surface: Color(0xFF141414),
              onSurface: Colors.white,
            ),
            dialogTheme: const DialogThemeData(backgroundColor: Color(0xFF141414)),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF39FF14),
              onPrimary: Colors.black,
              surface: Color(0xFF141414),
              onSurface: Colors.white,
            ),
            dialogTheme: const DialogThemeData(backgroundColor: Color(0xFF141414)),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedTime) {
      setState(() => _selectedTime = picked);
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
    _customFeeController.dispose();
    _debounceTimer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String formattedDate = "${_selectedDate.day.toString().padLeft(2, '0')}/${_selectedDate.month.toString().padLeft(2, '0')}/${_selectedDate.year}";
    final String formattedTime = _selectedTime.format(context);
    final isPro = _userProfile?.isPremium ?? false;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("HOST MATCH LOBBY", style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (isPro)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Center(child: ProBadgeWidget(isCompact: true)),
            ),
        ],
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
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. VISUAL SPORT CATEGORY SELECTOR CHIPS
                  const Text(
                    "1. SELECT SPORT",
                    style: TextStyle(color: Color(0xFF39FF14), fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 0.8),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 48,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _sportsList.length,
                      itemBuilder: (context, idx) {
                        final sport = _sportsList[idx];
                        final isSelected = sport == _selectedSport;
                        final icon = _sportIcons[sport] ?? '⚡';

                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(icon, style: const TextStyle(fontSize: 16)),
                                const SizedBox(width: 6),
                                Text(sport),
                              ],
                            ),
                            selected: isSelected,
                            onSelected: (selected) {
                              if (selected) {
                                setState(() {
                                  _selectedSport = sport;
                                  _applySportPlayerPreset(sport);
                                });
                              }
                            },
                            selectedColor: const Color(0xFF39FF14),
                            backgroundColor: const Color(0xFF141414),
                            side: BorderSide(
                              color: isSelected ? const Color(0xFF39FF14) : Colors.white.withValues(alpha: 0.08),
                              width: isSelected ? 1.5 : 1,
                            ),
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.black : Colors.white70,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 2. LOBBY TITLE & 1-TAP MAGIC AUTO TITLE
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Flexible(
                        child: Text(
                          "2. LOBBY TITLE",
                          style: TextStyle(color: Color(0xFF39FF14), fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 0.8),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      GestureDetector(
                        onTap: _generateAutoTitle,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF39FF14).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF39FF14).withValues(alpha: 0.3)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.auto_awesome, color: Color(0xFF39FF14), size: 13),
                              SizedBox(width: 4),
                              Text("AUTO TITLE", style: TextStyle(color: Color(0xFF39FF14), fontSize: 10, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  TextField(
                    controller: _titleController,
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      hintText: "e.g., Friday Night Casual $_selectedSport",
                      hintStyle: const TextStyle(color: Colors.white24),
                      enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white10)),
                      focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF39FF14))),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 3. GENDER REQUIREMENT (MALE ONLY / FEMALE ONLY / MIXED)
                  const Text(
                    "3. GENDER PREFERENCE",
                    style: TextStyle(color: Color(0xFF39FF14), fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 0.8),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _genderOptions.map((gender) {
                      final isSelected = _selectedGender == gender;
                      return ChoiceChip(
                        label: Text(gender),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _selectedGender = gender);
                          }
                        },
                        selectedColor: const Color(0xFF39FF14),
                        backgroundColor: const Color(0xFF141414),
                        side: BorderSide(
                          color: isSelected ? const Color(0xFF39FF14) : Colors.white.withValues(alpha: 0.08),
                        ),
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.black : Colors.white70,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  // 4. MATCH SCHEDULE (DATE & TIME)
                  const Text(
                    "4. MATCH SCHEDULE",
                    style: TextStyle(color: Color(0xFF39FF14), fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 0.8),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: _selectDate,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF141414),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today_rounded, color: Color(0xFF39FF14), size: 18),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text("DATE", style: TextStyle(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 2),
                                      Text(formattedDate, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13), overflow: TextOverflow.ellipsis),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: GestureDetector(
                          onTap: _selectTime,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF141414),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.access_time_rounded, color: Color(0xFF39FF14), size: 18),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text("TIME", style: TextStyle(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 2),
                                      Text(formattedTime, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13), overflow: TextOverflow.ellipsis),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // 5. COURT FEE SPLIT (COST / PAX)
                  const Text(
                    "5. COURT FEE SPLIT (PER PLAYER)",
                    style: TextStyle(color: Color(0xFF39FF14), fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 0.8),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _feeOptions.map((fee) {
                      final isSelected = _selectedFee == fee;
                      return ChoiceChip(
                        label: Text(fee),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _selectedFee = fee);
                          }
                        },
                        selectedColor: const Color(0xFF39FF14),
                        backgroundColor: const Color(0xFF141414),
                        side: BorderSide(
                          color: isSelected ? const Color(0xFF39FF14) : Colors.white.withValues(alpha: 0.08),
                        ),
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.black : Colors.white70,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      );
                    }).toList(),
                  ),
                  if (_selectedFee == 'Custom') ...[
                    const SizedBox(height: 8),
                    TextField(
                      controller: _customFeeController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: "Enter custom fee (e.g. RM 25 / pax)",
                        hintStyle: TextStyle(color: Colors.white24),
                        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white10)),
                        focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF39FF14))),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),

                  // 6. TARGET SKILL LEVELS
                  const Text(
                    "6. TARGET SKILL LEVELS",
                    style: TextStyle(color: Color(0xFF39FF14), fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 0.8),
                  ),
                  const SizedBox(height: 10),
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
                  const SizedBox(height: 24),

                  // 7. VENUE INPUT & TYPEAHEAD
                  const Text(
                    "7. VENUE / LOCATION NAME",
                    style: TextStyle(color: Color(0xFF39FF14), fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 0.8),
                  ),
                  const SizedBox(height: 4),
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
                      const String apiKey = "AIzaSyAZ7Acnl13fSeiAF9InEp0RpbFPd7tGSYA";
                      final String url =
                          "https://maps.googleapis.com/maps/api/place/autocomplete/json"
                          "?input=${Uri.encodeComponent(search)}"
                          "&components=country:my"
                          "&types=establishment"
                          "&key=$apiKey";

                      try {
                        final response = await http.get(Uri.parse(url), headers: {"Accept": "application/json"});
                        if (response.statusCode == 200) {
                          final data = json.decode(response.body);
                          if (data['status'] == 'OK') {
                            final predictions = data['predictions'] as List<dynamic>;
                            return predictions.map((p) => p['description']?.toString() ?? '').where((t) => t.isNotEmpty).toList();
                          }
                        }
                        return [];
                      } catch (_) {
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
                  const SizedBox(height: 14),

                  // 8. GOOGLE MAP PREVIEW WITH 1-TAP "LOCATE ME" BUTTON
                  Stack(
                    children: [
                      Container(
                        height: 200,
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
                                  _mapCenter = position.target;
                                },
                              ),
                              const Center(
                                child: Padding(
                                  padding: EdgeInsets.only(bottom: 24),
                                  child: Icon(Icons.location_on, color: Color(0xFF39FF14), size: 40),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 10,
                        right: 10,
                        child: GestureDetector(
                          onTap: _isLocating ? null : _locateMeAndFillAddress,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF121212),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: const Color(0xFF39FF14), width: 1.5),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.6),
                                  blurRadius: 10,
                                )
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _isLocating
                                    ? const SizedBox(
                                        width: 14,
                                        height: 14,
                                        child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF39FF14)),
                                      )
                                    : const Icon(Icons.my_location, color: Color(0xFF39FF14), size: 15),
                                const SizedBox(width: 6),
                                const Text("LOCATE ME", style: TextStyle(color: Color(0xFF39FF14), fontSize: 11, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // 9. MAX PARTICIPANTS & SPORT PRESETS
                  const Text(
                    "9. MAX PARTICIPANTS",
                    style: TextStyle(color: Color(0xFF39FF14), fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 0.8),
                  ),
                  const SizedBox(height: 8),
                  // Quick team size preset chips
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _getPlayerPresetsForSport(_selectedSport).map((count) {
                      final isSelected = _maxParticipants == count;
                      return ChoiceChip(
                        label: Text("$count Players"),
                        selected: isSelected,
                        onSelected: (sel) {
                          if (sel) setState(() => _maxParticipants = count);
                        },
                        selectedColor: const Color(0xFF39FF14),
                        backgroundColor: const Color(0xFF141414),
                        side: BorderSide(color: isSelected ? const Color(0xFF39FF14) : Colors.white10),
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.black : Colors.white70,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.03),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Flexible(
                          child: Text("Custom Count", style: TextStyle(color: Colors.white60, fontSize: 14), overflow: TextOverflow.ellipsis),
                        ),
                        Row(
                          children: [
                            IconButton(
                              onPressed: () {
                                if (_maxParticipants > 2) setState(() => _maxParticipants--);
                              },
                              icon: const Icon(Icons.remove_circle_outline, color: Colors.white60, size: 24),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: Text(
                                "$_maxParticipants",
                                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900),
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                                if (_maxParticipants < 40) setState(() => _maxParticipants++);
                              },
                              icon: const Icon(Icons.add_circle_outline, color: Color(0xFF39FF14), size: 24),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 10. PRO SPOTLIGHT PINNED LOBBY TOGGLE
                  GestureDetector(
                    onTap: () {
                      if (!isPro) {
                        PremiumUpgradeModal.show(context, onUpgradeSuccess: () => _loadInitialData());
                      } else {
                        setState(() => _isSpotlight = !_isSpotlight);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFFFFD700).withValues(alpha: 0.12),
                            const Color(0xFFFFA500).withValues(alpha: 0.06),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: _isSpotlight ? const Color(0xFFFFD700) : const Color(0xFFFFD700).withValues(alpha: 0.3),
                          width: _isSpotlight ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFFFFD700).withValues(alpha: 0.2),
                            ),
                            child: const Icon(Icons.push_pin_rounded, color: Color(0xFFFFD700), size: 18),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        "SPOTLIGHT PIN TO TOP",
                                        style: TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 0.5),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    SizedBox(width: 4),
                                    ProBadgeWidget(isCompact: true),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  isPro
                                      ? "Your lobby stays pinned at top of everyone's feed."
                                      : "PRO hosts get 3x more players by pinning lobbies.",
                                  style: const TextStyle(color: Colors.white60, fontSize: 10),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: _isSpotlight,
                            activeThumbColor: const Color(0xFFFFD700),
                            activeTrackColor: const Color(0xFFFFD700).withValues(alpha: 0.4),
                            inactiveThumbColor: Colors.white24,
                            inactiveTrackColor: Colors.black26,
                            onChanged: (val) {
                              if (!isPro) {
                                PremiumUpgradeModal.show(context, onUpgradeSuccess: () => _loadInitialData());
                              } else {
                                setState(() => _isSpotlight = val);
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // 11. SUBMIT / LAUNCH BUTTON
                  GestureDetector(
                    onTap: _submitLobby,
                    child: Container(
                      height: 54,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFF39FF14), Color(0xFF00FF87)]),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF39FF14).withValues(alpha: 0.3),
                            blurRadius: 18,
                            offset: const Offset(0, 6),
                          )
                        ],
                      ),
                      child: const Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.rocket_launch_rounded, color: Colors.black, size: 20),
                            SizedBox(width: 8),
                            Text(
                              "LAUNCH MATCH LOBBY",
                              style: TextStyle(color: Colors.black, fontSize: 15, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 36),
                ],
              ),
            ),
    );
  }

  void _submitLobby() async {
    final title = _titleController.text.trim();
    final venue = _venueController.text.trim();

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    if (title.isEmpty || venue.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text("Please provide a title and venue location to launch."),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final List<String> tags = [];
    if (_selectedGender.contains("Male Only")) {
      tags.add("[Male Only]");
    } else if (_selectedGender.contains("Female Only")) {
      tags.add("[Female Only]");
    }

    final feeText = _selectedFee == 'Custom' ? _customFeeController.text.trim() : _selectedFee;
    if (feeText.isNotEmpty && feeText != 'Free (Casual)') {
      tags.add("[$feeText]");
    }

    final feeAndGender = tags.join(" • ");

    final skillsToSubmit = _isOpenToAll ? ['Open to All'] : _selectedSkills;
    final formattedDate = "${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}";
    final formattedTime = _selectedTime.format(context);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: Color(0xFF39FF14))),
    );

    try {
      await _lobbyService.createLobby(
        title: title,
        sport: _selectedSport,
        locationName: venue,
        lat: _mapCenter.latitude,
        lng: _mapCenter.longitude,
        skills: skillsToSubmit,
        maxParticipants: _maxParticipants,
        matchDate: formattedDate,
        matchTime: formattedTime,
        courtFee: feeAndGender.trim().isNotEmpty ? feeAndGender.trim() : null,
        isSpotlight: _isSpotlight,
      );

      if (mounted) {
        navigator.pop(); // Dismiss loader
        navigator.pop(); // Return to previous screen
        messenger.showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Color(0xFF39FF14)),
                const SizedBox(width: 8),
                Expanded(child: Text("Lobby '$title' launched successfully! ⚡")),
              ],
            ),
            backgroundColor: const Color(0xFF1A1A1A),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) navigator.pop();
      messenger.showSnackBar(
        SnackBar(content: Text("Error creating lobby: $e"), backgroundColor: Colors.redAccent),
      );
    }
  }
}