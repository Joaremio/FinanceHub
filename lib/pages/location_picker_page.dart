import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class TransactionLocationSelection {
  const TransactionLocationSelection({
    required this.point,
    required this.label,
    this.address,
  });

  final LatLng point;
  final String label;
  final String? address;
}

class LocationPickerPage extends StatefulWidget {
  const LocationPickerPage({super.key, this.initialSelection});

  final TransactionLocationSelection? initialSelection;

  @override
  State<LocationPickerPage> createState() => _LocationPickerPageState();
}

class _LocationPickerPageState extends State<LocationPickerPage> {
  static const _initialPoint = LatLng(-5.7945, -35.2110);
  static const _maxSearchDistanceMeters = 100000.0;

  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  final Distance _distance = const Distance();

  late LatLng _selectedPoint;
  late String _selectedLabel;
  String? _selectedAddress;
  List<_PlaceResult> _results = [];
  Timer? _searchDebounce;
  int _searchToken = 0;
  bool _isSearching = false;
  bool _isLocating = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialSelection;
    _selectedPoint = initial?.point ?? _initialPoint;
    _selectedLabel = initial?.label ?? 'Local selecionado no mapa';
    _selectedAddress = initial?.address;
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _selectPoint(LatLng point, String label, [String? address]) {
    setState(() {
      _selectedPoint = point;
      _selectedLabel = label;
      _selectedAddress = address;
      _message = null;
    });
    _mapController.move(point, 16);
  }

  void _searchChanged(String value) {
    _searchDebounce?.cancel();
    final query = value.trim();

    if (query.length < 2) {
      _searchToken++;
      setState(() {
        _results = [];
        _message = null;
        _isSearching = false;
      });
      return;
    }

    _searchDebounce = Timer(
      const Duration(milliseconds: 450),
      () => _searchPlaces(query),
    );
  }

  Future<void> _searchPlaces(String query) async {
    final token = ++_searchToken;
    setState(() {
      _isSearching = true;
      _message = null;
    });

    final results = await _fetchPhotonPlaces(query);
    if (results.isEmpty) {
      results.addAll(await _fetchNominatimPlaces(query));
    }

    results.sort(
      (a, b) => _distance(
        _selectedPoint,
        a.point,
      ).compareTo(_distance(_selectedPoint, b.point)),
    );

    if (!mounted || token != _searchToken) return;
    setState(() {
      _results = results.take(10).toList();
      _message = results.isEmpty ? 'Nenhum local encontrado.' : null;
      _isSearching = false;
    });
  }

  Future<List<_PlaceResult>> _fetchPhotonPlaces(String query) async {
    try {
      final uri = Uri.https('photon.komoot.io', '/api/', {
        'q': query,
        'limit': '10',
        'lang': 'pt',
        'lat': _selectedPoint.latitude.toString(),
        'lon': _selectedPoint.longitude.toString(),
      });
      final response = await http.get(
        uri,
        headers: const {'User-Agent': 'FinanceHub location picker'},
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode != 200) return [];

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final features = body['features'];
      if (features is! List) return [];

      return features
          .whereType<Map<String, dynamic>>()
          .map(_PlaceResult.fromPhoton)
          .whereType<_PlaceResult>()
          .where(_isBrazilOrNearMarker)
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<_PlaceResult>> _fetchNominatimPlaces(String query) async {
    try {
      final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
        'format': 'jsonv2',
        'q': query,
        'limit': '10',
        'addressdetails': '1',
        'accept-language': 'pt-BR',
        'countrycodes': 'br',
        'viewbox': _viewboxAroundMarker(),
        'bounded': '0',
      });
      final response = await http.get(
        uri,
        headers: const {'User-Agent': 'FinanceHub location picker'},
      ).timeout(const Duration(seconds: 6));

      if (response.statusCode != 200) return [];

      final body = jsonDecode(response.body) as List<dynamic>;
      return body
          .whereType<Map<String, dynamic>>()
          .map(_PlaceResult.fromNominatim)
          .whereType<_PlaceResult>()
          .where(_isBrazilOrNearMarker)
          .toList();
    } catch (_) {
      return [];
    }
  }

  bool _isBrazilOrNearMarker(_PlaceResult result) {
    return result.countryCode == 'BR' ||
        _distance(_selectedPoint, result.point) < _maxSearchDistanceMeters;
  }

  String _viewboxAroundMarker() {
    const radius = 0.12;
    final west = _selectedPoint.longitude - radius;
    final east = _selectedPoint.longitude + radius;
    final north = _selectedPoint.latitude + radius;
    final south = _selectedPoint.latitude - radius;
    return '$west,$north,$east,$south';
  }

  Future<void> _useCurrentLocation() async {
    if (_isLocating) return;
    setState(() {
      _isLocating = true;
      _message = null;
    });

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw StateError('Ative o GPS do dispositivo.');

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw StateError('Permissão de localização negada.');
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 10),
        ),
      );
      _selectPoint(
        LatLng(position.latitude, position.longitude),
        'Minha localização atual',
        'Obtida pelo GPS do dispositivo',
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _message = error.toString().replaceFirst('Bad state: ', ''));
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  void _selectSearchResult(_PlaceResult result) {
    _searchController.text = result.label;
    FocusScope.of(context).unfocus();
    setState(() => _results = []);
    _selectPoint(result.point, result.label, result.address);
  }

  void _zoomBy(double delta) {
    final camera = _mapController.camera;
    final nextZoom = (camera.zoom + delta).clamp(3.0, 16.0);
    _mapController.move(camera.center, nextZoom);
  }

  void _confirmSelection() {
    Navigator.pop(
      context,
      TransactionLocationSelection(
        point: _selectedPoint,
        label: _selectedLabel,
        address: _selectedAddress,
      ),
    );
  }

  String _distanceText(LatLng point) {
    final meters = _distance(_selectedPoint, point);
    if (meters < 1000) return '${meters.round()} m';
    return '${(meters / 1000).toStringAsFixed(1).replaceAll('.', ',')} km';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Escolher local'),
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _selectedPoint,
              initialZoom: widget.initialSelection == null ? 13 : 16,
              minZoom: 3,
              maxZoom: 16,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.drag | InteractiveFlag.flingAnimation,
              ),
              onTap: (_, point) => _selectPoint(point, 'Local selecionado no mapa'),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                maxNativeZoom: 16,
                keepBuffer: 1,
                panBuffer: 0,
                retinaMode: false,
                tileDisplay: const TileDisplay.instantaneous(),
                tileUpdateTransformer: TileUpdateTransformers.debounce(
                  const Duration(milliseconds: 350),
                ),
                userAgentPackageName: 'com.example.financehub',
              ),
              MarkerLayer(
                markers: [
                  ..._results.map(
                    (result) => Marker(
                      point: result.point,
                      width: 42,
                      height: 42,
                      child: IconButton.filledTonal(
                        onPressed: () => _selectSearchResult(result),
                        icon: const Icon(Icons.place_outlined, size: 18),
                      ),
                    ),
                  ),
                  Marker(
                    point: _selectedPoint,
                    width: 48,
                    height: 48,
                    child: Icon(
                      Icons.location_pin,
                      size: 44,
                      color: colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  _buildSearchPanel(colorScheme),
                  if (_message != null) ...[
                    const SizedBox(height: 8),
                    _buildMessage(colorScheme),
                  ],
                  const Spacer(),
                  _buildZoomControls(),
                  const SizedBox(height: 12),
                  _buildSelectionBar(colorScheme),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchPanel(ColorScheme colorScheme) {
    return Material(
      color: colorScheme.surface,
      elevation: 2,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _searchController,
            onChanged: _searchChanged,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Pesquisar lugar',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _isSearching
                  ? const Padding(
                      padding: EdgeInsets.all(14),
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : IconButton(
                      onPressed: _useCurrentLocation,
                      icon: _isLocating
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.my_location),
                    ),
              border: InputBorder.none,
            ),
            onSubmitted: (value) {
              final query = value.trim();
              if (query.length >= 2) unawaited(_searchPlaces(query));
            },
          ),
          if (_results.isNotEmpty)
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 260),
              child: ListView.separated(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: _results.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final result = _results[index];
                  return ListTile(
                    leading: const Icon(Icons.place_outlined),
                    title: Text(
                      result.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      result.address == null
                          ? _distanceText(result.point)
                          : '${_distanceText(result.point)} - ${result.address}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () => _selectSearchResult(result),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMessage(ColorScheme colorScheme) {
    return Material(
      color: colorScheme.errorContainer,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Text(
          _message!,
          style: TextStyle(color: colorScheme.onErrorContainer),
        ),
      ),
    );
  }

  Widget _buildZoomControls() {
    return Align(
      alignment: Alignment.centerRight,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.small(
            heroTag: 'location_zoom_in',
            onPressed: () => _zoomBy(1),
            child: const Icon(Icons.add),
          ),
          const SizedBox(height: 8),
          FloatingActionButton.small(
            heroTag: 'location_zoom_out',
            onPressed: () => _zoomBy(-1),
            child: const Icon(Icons.remove),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectionBar(ColorScheme colorScheme) {
    return Material(
      color: colorScheme.surface,
      elevation: 2,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(Icons.location_on_outlined, color: colorScheme.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _selectedLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    _selectedAddress ??
                        '${_selectedPoint.latitude.toStringAsFixed(5)}, ${_selectedPoint.longitude.toStringAsFixed(5)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            FilledButton(onPressed: _confirmSelection, child: const Text('Usar')),
          ],
        ),
      ),
    );
  }
}

class _PlaceResult {
  const _PlaceResult({
    required this.point,
    required this.label,
    this.address,
    this.countryCode,
  });

  final LatLng point;
  final String label;
  final String? address;
  final String? countryCode;

  static _PlaceResult? fromPhoton(Map<String, dynamic> json) {
    final geometry = json['geometry'];
    final properties = json['properties'];
    if (geometry is! Map<String, dynamic> ||
        properties is! Map<String, dynamic>) {
      return null;
    }

    final coordinates = geometry['coordinates'];
    if (coordinates is! List || coordinates.length < 2) return null;

    final lon = double.tryParse(coordinates[0].toString());
    final lat = double.tryParse(coordinates[1].toString());
    final name = properties['name']?.toString();
    if (lat == null || lon == null || name == null || name.isEmpty) {
      return null;
    }

    final address = [
      ?properties['street']?.toString(),
      ?properties['district']?.toString(),
      ?properties['city']?.toString(),
      ?properties['state']?.toString(),
    ].join(' - ');

    return _PlaceResult(
      point: LatLng(lat, lon),
      label: name,
      address: address.isEmpty ? null : address,
      countryCode: properties['countrycode']?.toString().toUpperCase(),
    );
  }

  static _PlaceResult? fromNominatim(Map<String, dynamic> json) {
    final lat = double.tryParse(json['lat']?.toString() ?? '');
    final lon = double.tryParse(json['lon']?.toString() ?? '');
    if (lat == null || lon == null) return null;

    final displayName = json['display_name']?.toString() ?? '';
    final name = json['name']?.toString();

    return _PlaceResult(
      point: LatLng(lat, lon),
      label: name == null || name.isEmpty
          ? displayName.split(',').first
          : name,
      address: displayName.isEmpty ? null : displayName,
      countryCode: json['country_code']?.toString().toUpperCase(),
    );
  }
}
