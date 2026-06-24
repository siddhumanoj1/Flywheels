import 'package:flywheels/app/app_scope.dart';
import 'package:flywheels/core/theme/app_theme.dart';
import 'package:flywheels/core/utils/formatters.dart';
import 'package:flywheels/models/app_models.dart';
import 'package:flywheels/services/car_media_service.dart';
import 'package:flywheels/widgets/app_image.dart';
import 'package:flywheels/widgets/app_inner_tabs.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

enum _WheelsSort { newest, nearest, priceLow, priceHigh, mileageLow }

extension _WheelsSortX on _WheelsSort {
  String get label {
    switch (this) {
      case _WheelsSort.newest:
        return 'Newest';
      case _WheelsSort.nearest:
        return 'Nearest location';
      case _WheelsSort.priceLow:
        return 'Price low to high';
      case _WheelsSort.priceHigh:
        return 'Price high to low';
      case _WheelsSort.mileageLow:
        return 'Lowest mileage';
    }
  }
}

class _WheelsFilters {
  const _WheelsFilters({
    this.minBudget,
    this.maxBudget,
    this.makeModel = '',
    this.modelYear,
    this.maxKms,
    this.fuel,
    this.bodyType,
    this.transmission,
    this.color = '',
    this.features = '',
    this.seats,
    this.owners,
    this.rto = '',
  });

  final double? minBudget;
  final double? maxBudget;
  final String makeModel;
  final int? modelYear;
  final int? maxKms;
  final String? fuel;
  final String? bodyType;
  final String? transmission;
  final String color;
  final String features;
  final int? seats;
  final int? owners;
  final String rto;

  bool get isActive =>
      minBudget != null ||
      maxBudget != null ||
      makeModel.trim().isNotEmpty ||
      modelYear != null ||
      maxKms != null ||
      fuel != null ||
      bodyType != null ||
      transmission != null ||
      color.trim().isNotEmpty ||
      features.trim().isNotEmpty ||
      seats != null ||
      owners != null ||
      rto.trim().isNotEmpty;
}

class WheelsMarketplaceTab extends StatefulWidget {
  const WheelsMarketplaceTab({super.key, this.allowSubmit = true});

  final bool allowSubmit;

  @override
  State<WheelsMarketplaceTab> createState() => _WheelsMarketplaceTabState();
}

class _WheelsMarketplaceTabState extends State<WheelsMarketplaceTab> {
  final _picker = ImagePicker();
  _WheelsFilters _filters = const _WheelsFilters();
  _WheelsSort _sort = _WheelsSort.newest;

  @override
  Widget build(BuildContext context) {
    final controller = FlywheelsScope.of(context);
    final listings = _filteredListings(controller.saleListings);

    return Stack(
      children: [
        Positioned.fill(
          child: listings.isEmpty
              ? const _WheelsEmptyState()
              : PageView.builder(
                  scrollDirection: Axis.vertical,
                  itemCount: listings.length,
                  itemBuilder: (context, index) {
                    final listing = listings[index];
                    return _WheelsReelItem(
                      listing: listing,
                      onTap: () => _showListingDetails(context, listing),
                    );
                  },
                ),
        ),
        Positioned(
          left: 12,
          right: 12,
          top: 12,
          child: SafeArea(
            bottom: false,
            child: Row(
              children: [
                _WheelsTopButton(
                  icon: Icons.tune_rounded,
                  label: 'Filters',
                  active: _filters.isActive,
                  onPressed: _showFilters,
                ),
                const SizedBox(width: 8),
                _WheelsTopButton(
                  icon: Icons.sort_rounded,
                  label: 'Sort',
                  active: _sort != _WheelsSort.newest,
                  onPressed: _showSort,
                ),
                const Spacer(),
                if (widget.allowSubmit)
                  IconButton.filled(
                    tooltip: 'Submit car',
                    style: IconButton.styleFrom(
                      backgroundColor: AppPalette.red,
                      foregroundColor: AppPalette.white,
                    ),
                    onPressed: () =>
                        showWheelsListingSheet(context, picker: _picker),
                    icon: const Icon(Icons.add_rounded),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<CarSaleListing> _filteredListings(List<CarSaleListing> source) {
    final filtered = source.where((listing) {
      final query = _filters.makeModel.trim().toLowerCase();
      final color = _filters.color.trim().toLowerCase();
      final features = _filters.features.trim().toLowerCase();
      final rto = _filters.rto.trim().toLowerCase();
      final featureText = listing.features.join(' ').toLowerCase();

      return (_filters.minBudget == null ||
              listing.price >= _filters.minBudget!) &&
          (_filters.maxBudget == null ||
              listing.price <= _filters.maxBudget!) &&
          (query.isEmpty ||
              listing.title.toLowerCase().contains(query) ||
              listing.model.toLowerCase().contains(query)) &&
          (_filters.modelYear == null || listing.year == _filters.modelYear) &&
          (_filters.maxKms == null || listing.odometerKm <= _filters.maxKms!) &&
          (_filters.fuel == null ||
              listing.fuelType.toLowerCase() == _filters.fuel!.toLowerCase()) &&
          (_filters.bodyType == null ||
              listing.bodyType.toLowerCase() ==
                  _filters.bodyType!.toLowerCase()) &&
          (_filters.transmission == null ||
              listing.transmission.toLowerCase() ==
                  _filters.transmission!.toLowerCase()) &&
          (color.isEmpty || listing.color.toLowerCase().contains(color)) &&
          (features.isEmpty || featureText.contains(features)) &&
          (_filters.seats == null || listing.seats == _filters.seats) &&
          (_filters.owners == null || listing.ownerCount <= _filters.owners!) &&
          (rto.isEmpty || listing.rto.toLowerCase().contains(rto));
    }).toList();

    switch (_sort) {
      case _WheelsSort.newest:
        filtered.sort(
          (left, right) => right.createdAt.compareTo(left.createdAt),
        );
        break;
      case _WheelsSort.nearest:
        filtered.sort(
          (left, right) => _locationRank(
            left.location,
          ).compareTo(_locationRank(right.location)),
        );
        break;
      case _WheelsSort.priceLow:
        filtered.sort((left, right) => left.price.compareTo(right.price));
        break;
      case _WheelsSort.priceHigh:
        filtered.sort((left, right) => right.price.compareTo(left.price));
        break;
      case _WheelsSort.mileageLow:
        filtered.sort(
          (left, right) => left.odometerKm.compareTo(right.odometerKm),
        );
        break;
    }

    return filtered;
  }

  int _locationRank(String location) {
    final value = location.toLowerCase();
    const priority = [
      'madhapur',
      'gachibowli',
      'kondapur',
      'hitech',
      'jubilee',
      'banjara',
      'secunderabad',
      'hyderabad',
    ];
    final index = priority.indexWhere((item) => value.contains(item));
    return index == -1 ? priority.length : index;
  }

  void _showFilters() {
    final minBudgetController = TextEditingController(
      text: _filters.minBudget?.toStringAsFixed(0) ?? '',
    );
    final maxBudgetController = TextEditingController(
      text: _filters.maxBudget?.toStringAsFixed(0) ?? '',
    );
    final makeModelController = TextEditingController(text: _filters.makeModel);
    final modelYearController = TextEditingController(
      text: _filters.modelYear?.toString() ?? '',
    );
    final colorController = TextEditingController(text: _filters.color);
    final featuresController = TextEditingController(text: _filters.features);
    final rtoController = TextEditingController(text: _filters.rto);
    String? fuel = _filters.fuel;
    String? bodyType = _filters.bodyType;
    String? transmission = _filters.transmission;
    int? maxKm = _filters.maxKms;
    int? seats = _filters.seats;
    int? owners = _filters.owners;

    int? parseInt(String value) {
      final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
      return digits.isEmpty ? null : int.tryParse(digits);
    }

    double? parseDouble(String value) {
      final digits = value.replaceAll(RegExp(r'[^0-9.]'), '');
      return digits.isEmpty ? null : double.tryParse(digits);
    }

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                18,
                20,
                MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: SafeArea(
                top: false,
                child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.78,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Filters',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: ListView(
                          children: [
                            Text(
                              'Budget',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: minBudgetController,
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(
                                      labelText: 'Minimum',
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: TextField(
                                    controller: maxBudgetController,
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(
                                      labelText: 'Maximum',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            TextField(
                              controller: makeModelController,
                              decoration: const InputDecoration(
                                labelText: 'Make & Model',
                              ),
                            ),
                            const SizedBox(height: 10),
                            TextField(
                              controller: modelYearController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Model Year',
                              ),
                            ),
                            const SizedBox(height: 10),
                            DropdownButtonFormField<int?>(
                              initialValue: maxKm,
                              decoration: const InputDecoration(
                                labelText: 'Kms Driven',
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: null,
                                  child: Text('Any kms'),
                                ),
                                DropdownMenuItem(
                                  value: 20000,
                                  child: Text('Up to 20,000 km'),
                                ),
                                DropdownMenuItem(
                                  value: 50000,
                                  child: Text('Up to 50,000 km'),
                                ),
                                DropdownMenuItem(
                                  value: 100000,
                                  child: Text('Up to 1,00,000 km'),
                                ),
                              ],
                              onChanged: (value) =>
                                  setSheetState(() => maxKm = value),
                            ),
                            const SizedBox(height: 10),
                            DropdownButtonFormField<String?>(
                              initialValue: fuel,
                              decoration: const InputDecoration(
                                labelText: 'Fuel',
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: null,
                                  child: Text('All fuel types'),
                                ),
                                DropdownMenuItem(
                                  value: 'Petrol',
                                  child: Text('Petrol'),
                                ),
                                DropdownMenuItem(
                                  value: 'Diesel',
                                  child: Text('Diesel'),
                                ),
                                DropdownMenuItem(
                                  value: 'CNG',
                                  child: Text('CNG'),
                                ),
                                DropdownMenuItem(
                                  value: 'Electric',
                                  child: Text('Electric'),
                                ),
                              ],
                              onChanged: (value) =>
                                  setSheetState(() => fuel = value),
                            ),
                            const SizedBox(height: 10),
                            DropdownButtonFormField<String?>(
                              initialValue: bodyType,
                              decoration: const InputDecoration(
                                labelText: 'Body Type',
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: null,
                                  child: Text('All body types'),
                                ),
                                DropdownMenuItem(
                                  value: 'SUV',
                                  child: Text('SUV'),
                                ),
                                DropdownMenuItem(
                                  value: 'Sedan',
                                  child: Text('Sedan'),
                                ),
                                DropdownMenuItem(
                                  value: 'Hatchback',
                                  child: Text('Hatchback'),
                                ),
                                DropdownMenuItem(
                                  value: 'MUV',
                                  child: Text('MUV'),
                                ),
                              ],
                              onChanged: (value) =>
                                  setSheetState(() => bodyType = value),
                            ),
                            const SizedBox(height: 10),
                            DropdownButtonFormField<String?>(
                              initialValue: transmission,
                              decoration: const InputDecoration(
                                labelText: 'Transmission',
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: null,
                                  child: Text('Any transmission'),
                                ),
                                DropdownMenuItem(
                                  value: 'Manual',
                                  child: Text('Manual'),
                                ),
                                DropdownMenuItem(
                                  value: 'Automatic',
                                  child: Text('Automatic'),
                                ),
                              ],
                              onChanged: (value) =>
                                  setSheetState(() => transmission = value),
                            ),
                            const SizedBox(height: 10),
                            TextField(
                              controller: colorController,
                              decoration: const InputDecoration(
                                labelText: 'Color',
                              ),
                            ),
                            const SizedBox(height: 10),
                            TextField(
                              controller: featuresController,
                              decoration: const InputDecoration(
                                labelText: 'Features',
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: DropdownButtonFormField<int?>(
                                    initialValue: seats,
                                    decoration: const InputDecoration(
                                      labelText: 'Seats',
                                    ),
                                    items: const [
                                      DropdownMenuItem(
                                        value: null,
                                        child: Text('Any seats'),
                                      ),
                                      DropdownMenuItem(
                                        value: 4,
                                        child: Text('4'),
                                      ),
                                      DropdownMenuItem(
                                        value: 5,
                                        child: Text('5'),
                                      ),
                                      DropdownMenuItem(
                                        value: 6,
                                        child: Text('6'),
                                      ),
                                      DropdownMenuItem(
                                        value: 7,
                                        child: Text('7'),
                                      ),
                                    ],
                                    onChanged: (value) =>
                                        setSheetState(() => seats = value),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: DropdownButtonFormField<int?>(
                                    initialValue: owners,
                                    decoration: const InputDecoration(
                                      labelText: 'Owners',
                                    ),
                                    items: const [
                                      DropdownMenuItem(
                                        value: null,
                                        child: Text('Any owners'),
                                      ),
                                      DropdownMenuItem(
                                        value: 1,
                                        child: Text('1 or fewer'),
                                      ),
                                      DropdownMenuItem(
                                        value: 2,
                                        child: Text('2 or fewer'),
                                      ),
                                      DropdownMenuItem(
                                        value: 3,
                                        child: Text('3 or fewer'),
                                      ),
                                    ],
                                    onChanged: (value) =>
                                        setSheetState(() => owners = value),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            TextField(
                              controller: rtoController,
                              textCapitalization: TextCapitalization.characters,
                              decoration: const InputDecoration(
                                labelText: 'RTO',
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                setState(
                                  () => _filters = const _WheelsFilters(),
                                );
                                Navigator.of(context).pop();
                              },
                              icon: const Icon(Icons.restart_alt_rounded),
                              label: const Text('Reset'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: () {
                                setState(() {
                                  _filters = _WheelsFilters(
                                    minBudget: parseDouble(
                                      minBudgetController.text,
                                    ),
                                    maxBudget: parseDouble(
                                      maxBudgetController.text,
                                    ),
                                    makeModel: makeModelController.text,
                                    modelYear: parseInt(
                                      modelYearController.text,
                                    ),
                                    maxKms: maxKm,
                                    fuel: fuel,
                                    bodyType: bodyType,
                                    transmission: transmission,
                                    color: colorController.text,
                                    features: featuresController.text,
                                    seats: seats,
                                    owners: owners,
                                    rto: rtoController.text,
                                  );
                                });
                                Navigator.of(context).pop();
                              },
                              icon: const Icon(Icons.check_rounded),
                              label: const Text('Apply'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    ).whenComplete(() {
      minBudgetController.dispose();
      maxBudgetController.dispose();
      makeModelController.dispose();
      modelYearController.dispose();
      colorController.dispose();
      featuresController.dispose();
      rtoController.dispose();
    });
  }

  void _showSort() {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
                  child: Text(
                    'Sort',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                ..._WheelsSort.values.map((sort) {
                  final selected = sort == _sort;
                  return ListTile(
                    leading: Icon(
                      selected
                          ? Icons.radio_button_checked_rounded
                          : Icons.radio_button_off_rounded,
                      color: selected ? AppPalette.red : AppPalette.black,
                    ),
                    title: Text(sort.label),
                    onTap: () {
                      setState(() => _sort = sort);
                      Navigator.of(context).pop();
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _WheelsTopButton extends StatelessWidget {
  const _WheelsTopButton({
    required this.icon,
    required this.label,
    required this.active,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      style: FilledButton.styleFrom(
        backgroundColor: active ? AppPalette.red : AppPalette.black,
        foregroundColor: AppPalette.white,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
    );
  }
}

class _WheelsReelItem extends StatelessWidget {
  const _WheelsReelItem({required this.listing, required this.onTap});

  final CarSaleListing listing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppPalette.black,
      child: InkWell(
        onTap: onTap,
        child: Stack(
          fit: StackFit.expand,
          children: [
            _ListingMediaView(
              media: listing.primaryMedia,
              fallbackModel: listing.model,
              fallbackYear: listing.year,
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x33000000),
                    Color(0x11000000),
                    Color(0xDD000000),
                  ],
                  stops: [0, 0.44, 1],
                ),
              ),
            ),
            Positioned(
              left: 20,
              right: 20,
              bottom: 28,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (listing.isGarageVerified)
                        const _OverlayBadge(
                          icon: Icons.verified_rounded,
                          label: 'Garage verified',
                        ),
                      if (listing.videoCount > 0)
                        _OverlayBadge(
                          icon: Icons.play_circle_outline_rounded,
                          label: '${listing.videoCount} video',
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    listing.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: AppPalette.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  _ListingPriceText(
                    listing: listing,
                    suffix: ' | ${listing.year} | ${listing.bodyType}',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppPalette.white,
                      fontWeight: FontWeight.w900,
                    ),
                    oldStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppPalette.white.withValues(alpha: 0.62),
                      decoration: TextDecoration.lineThrough,
                      decorationColor: AppPalette.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Posted ${formatShortDate(listing.createdAt)} | ${listing.fuelType} | ${listing.odometerKm} km | ${listing.location}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: AppPalette.white.withValues(alpha: 0.86),
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Icon(
                        Icons.keyboard_arrow_up_rounded,
                        color: AppPalette.white,
                        size: 30,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ListingMediaView extends StatelessWidget {
  const _ListingMediaView({
    required this.media,
    required this.fallbackModel,
    required this.fallbackYear,
    this.borderRadius,
  });

  final CarSaleMedia? media;
  final String fallbackModel;
  final int fallbackYear;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final item = media;
    if (item == null) {
      return AppImage(
        path: CarMediaService.imageForModel(fallbackModel, year: fallbackYear),
        width: double.infinity,
        height: double.infinity,
        borderRadius: borderRadius,
      );
    }
    if (item.type == CarSaleMediaType.video) {
      return _VideoMediaView(caption: item.caption, borderRadius: borderRadius);
    }
    return AppImage(
      path: item.path,
      width: double.infinity,
      height: double.infinity,
      borderRadius: borderRadius,
    );
  }
}

class _ListingPriceText extends StatelessWidget {
  const _ListingPriceText({
    required this.listing,
    required this.style,
    required this.oldStyle,
    this.suffix = '',
  });

  final CarSaleListing listing;
  final TextStyle? style;
  final TextStyle? oldStyle;
  final String suffix;

  @override
  Widget build(BuildContext context) {
    final previous = listing.previousPrice;
    final showPrevious = previous != null && previous != listing.price;
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: formatCurrency(listing.price), style: style),
          if (showPrevious)
            TextSpan(text: ' ${formatCurrency(previous)}', style: oldStyle),
          if (suffix.isNotEmpty) TextSpan(text: suffix, style: style),
        ],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}

class _VideoMediaView extends StatelessWidget {
  const _VideoMediaView({required this.caption, this.borderRadius});

  final String? caption;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final child = Container(
      color: AppPalette.black,
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.play_circle_fill_rounded,
            color: AppPalette.white,
            size: 58,
          ),
          const SizedBox(height: 8),
          Text(
            caption == null || caption!.isEmpty ? 'Video' : caption!,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppPalette.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );

    if (borderRadius == null) return child;
    return ClipRRect(borderRadius: borderRadius!, child: child);
  }
}

class _OverlayBadge extends StatelessWidget {
  const _OverlayBadge({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppPalette.black.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: AppPalette.white.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppPalette.white, size: 15),
          const SizedBox(width: 5),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppPalette.white,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}

class _WheelsEmptyState extends StatelessWidget {
  const _WheelsEmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppPalette.soft,
      padding: const EdgeInsets.fromLTRB(20, 96, 20, 20),
      child: Center(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.directions_car_filled_rounded, size: 44),
                const SizedBox(height: 12),
                Text(
                  'No cars found',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 6),
                Text(
                  'Try another fuel type, mileage range, or sort order.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

void _showListingDetails(BuildContext context, CarSaleListing listing) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (context) {
      return SafeArea(
        top: false,
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.86,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Pictures and videos',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 286,
                child: PageView.builder(
                  itemCount: listing.media.isEmpty ? 1 : listing.media.length,
                  itemBuilder: (context, index) {
                    final media = listing.media.isEmpty
                        ? listing.primaryMedia
                        : listing.media[index];
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _ListingMediaView(
                        media: media,
                        fallbackModel: listing.model,
                        fallbackYear: listing.year,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      listing.title,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ),
                  if (listing.isGarageVerified)
                    const Icon(Icons.verified_rounded, color: AppPalette.red),
                ],
              ),
              const SizedBox(height: 6),
              _ListingPriceText(
                listing: listing,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppPalette.red,
                  fontWeight: FontWeight.w900,
                ),
                oldStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppPalette.muted,
                  decoration: TextDecoration.lineThrough,
                  decorationColor: AppPalette.muted,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _DetailChip(
                    icon: Icons.local_gas_station,
                    label: listing.fuelType,
                  ),
                  _DetailChip(
                    icon: Icons.speed_rounded,
                    label: '${listing.odometerKm} km',
                  ),
                  _DetailChip(
                    icon: Icons.calendar_month_outlined,
                    label: listing.year.toString(),
                  ),
                  _DetailChip(
                    icon: Icons.settings_outlined,
                    label: listing.transmission,
                  ),
                  _DetailChip(
                    icon: Icons.location_on_outlined,
                    label: listing.location,
                  ),
                  _DetailChip(
                    icon: Icons.directions_car_filled_outlined,
                    label: listing.bodyType,
                  ),
                  _DetailChip(
                    icon: Icons.palette_outlined,
                    label: listing.color,
                  ),
                  _DetailChip(
                    icon: Icons.airline_seat_recline_normal_rounded,
                    label: '${listing.seats} seats',
                  ),
                  _DetailChip(
                    icon: Icons.person_search_outlined,
                    label: '${listing.ownerCount} owner',
                  ),
                  _DetailChip(icon: Icons.pin_outlined, label: listing.rto),
                  _DetailChip(
                    icon: Icons.event_available_outlined,
                    label: 'Posted ${formatShortDate(listing.createdAt)}',
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text('Details', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(listing.description),
              if (listing.features.isNotEmpty) ...[
                const SizedBox(height: 18),
                Text(
                  'Features',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: listing.features
                      .map(
                        (feature) => _DetailChip(
                          icon: Icons.check_circle_outline_rounded,
                          label: feature,
                        ),
                      )
                      .toList(),
                ),
              ],
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    final sent = FlywheelsScope.read(
                      context,
                    ).sendBuyingInterest(listing);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          sent
                              ? 'Interest sent to owner.'
                              : 'Only customers can contact the owner here.',
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.chat_bubble_outline_rounded),
                  label: const Text('Contact'),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _DetailChip extends StatelessWidget {
  const _DetailChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppPalette.soft,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppPalette.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppPalette.black,
              fontWeight: FontWeight.w800,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}

class OwnerWheelsMarketplaceTab extends StatelessWidget {
  const OwnerWheelsMarketplaceTab({super.key, this.picker});

  final ImagePicker? picker;

  @override
  Widget build(BuildContext context) {
    final controller = FlywheelsScope.of(context);
    final pending = controller.pendingSaleListings;
    final active = controller.activeSaleListings;
    final sold = controller.soldSaleListings;

    return AppInnerTabs(
      title: 'Wheels marketplace',
      subtitle:
          '${pending.length} pending, ${active.length} live, ${sold.length} sold',
      trailing: IconButton.filled(
        tooltip: 'Post or approve',
        style: IconButton.styleFrom(
          backgroundColor: AppPalette.red,
          foregroundColor: AppPalette.white,
        ),
        onPressed: () => _showOwnerWheelsActions(context),
        icon: const Icon(Icons.add_rounded),
      ),
      tabs: [
        AppInnerTab(
          label: 'Pending Approval',
          child: _OwnerWheelsSection(
            key: const PageStorageKey('owner-wheels-pending'),
            title: 'Pending approval',
            emptyText: 'No customer submissions waiting right now.',
            listings: pending,
            actionsBuilder: (listing) => [
              OutlinedButton.icon(
                onPressed: () => controller.rejectSaleListing(listing.id),
                icon: const Icon(Icons.close_rounded),
                label: const Text('Reject'),
              ),
              FilledButton.icon(
                onPressed: () => controller.approveSaleListing(listing.id),
                icon: const Icon(Icons.check_rounded),
                label: const Text('Approve'),
              ),
            ],
          ),
        ),
        AppInnerTab(
          label: 'Live Cars',
          child: _OwnerWheelsSection(
            key: const PageStorageKey('owner-wheels-live'),
            title: 'Live cars',
            emptyText: 'No live sale cars yet.',
            listings: active,
            actionsBuilder: (listing) => [
              OutlinedButton.icon(
                onPressed: () => showWheelsListingSheet(
                  context,
                  picker: picker ?? ImagePicker(),
                  editingListing: listing,
                ),
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Edit'),
              ),
              OutlinedButton.icon(
                onPressed: () => controller.markSaleListingSold(listing.id),
                icon: const Icon(Icons.sell_rounded),
                label: const Text('Mark sold'),
              ),
            ],
          ),
        ),
        AppInnerTab(
          label: 'Sold Cars',
          child: _OwnerWheelsSection(
            key: const PageStorageKey('owner-wheels-sold'),
            title: 'Sold cars',
            emptyText: 'Sold cars will appear here.',
            listings: sold,
            actionsBuilder: (_) => const [],
          ),
        ),
      ],
    );
  }

  void _showOwnerWheelsActions(BuildContext context) {
    final controller = FlywheelsScope.read(context);
    final pending = controller.pendingSaleListings;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          top: false,
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.78,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Post or approve',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        showWheelsListingSheet(
                          context,
                          picker: picker ?? ImagePicker(),
                        );
                      },
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Post car for sale'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Customer submissions',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: pending.isEmpty
                        ? const _WheelsEmptyApprovalState()
                        : ListView.separated(
                            itemCount: pending.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final listing = pending[index];
                              return _OwnerSaleListingCard(
                                listing: listing,
                                actions: [
                                  OutlinedButton.icon(
                                    onPressed: () {
                                      controller.rejectSaleListing(listing.id);
                                      Navigator.of(context).pop();
                                    },
                                    icon: const Icon(Icons.close_rounded),
                                    label: const Text('Reject'),
                                  ),
                                  FilledButton.icon(
                                    onPressed: () {
                                      controller.approveSaleListing(listing.id);
                                      Navigator.of(context).pop();
                                    },
                                    icon: const Icon(Icons.check_rounded),
                                    label: const Text('Approve'),
                                  ),
                                ],
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _OwnerWheelsSection extends StatelessWidget {
  const _OwnerWheelsSection({
    super.key,
    required this.title,
    required this.emptyText,
    required this.listings,
    required this.actionsBuilder,
  });

  final String title;
  final String emptyText;
  final List<CarSaleListing> listings;
  final List<Widget> Function(CarSaleListing listing) actionsBuilder;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            Text(
              listings.length.toString(),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppPalette.red,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (listings.isEmpty)
          Text(emptyText, style: Theme.of(context).textTheme.bodySmall),
        ...listings.map(
          (listing) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _OwnerSaleListingCard(
              listing: listing,
              actions: actionsBuilder(listing),
            ),
          ),
        ),
      ],
    );
  }
}

class _OwnerSaleListingCard extends StatelessWidget {
  const _OwnerSaleListingCard({required this.listing, required this.actions});

  final CarSaleListing listing;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppPalette.soft,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppPalette.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              SizedBox(
                width: 82,
                height: 62,
                child: _ListingMediaView(
                  media: listing.primaryMedia,
                  fallbackModel: listing.model,
                  fallbackYear: listing.year,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      listing.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 3),
                    _ListingPriceText(
                      listing: listing,
                      suffix:
                          ' | ${listing.odometerKm} km | ${listing.status.label}',
                      style: Theme.of(context).textTheme.bodySmall,
                      oldStyle: Theme.of(context).textTheme.labelSmall
                          ?.copyWith(
                            color: AppPalette.muted,
                            decoration: TextDecoration.lineThrough,
                            decorationColor: AppPalette.muted,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Posted ${formatShortDate(listing.createdAt)} | ${listing.fuelType} | ${listing.location}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (actions.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(spacing: 8, runSpacing: 8, children: actions),
          ],
        ],
      ),
    );
  }
}

class _WheelsEmptyApprovalState extends StatelessWidget {
  const _WheelsEmptyApprovalState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'No submitted cars need approval.',
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );
  }
}

Future<void> showWheelsListingSheet(
  BuildContext context, {
  ImagePicker? picker,
  CarProfile? sourceCar,
  CarSaleListing? editingListing,
}) async {
  final controller = FlywheelsScope.read(context);
  final localPicker = picker ?? ImagePicker();
  final isEditing = editingListing != null;

  String numberText(num value) {
    if (value is double && value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }
    return value.toString();
  }

  final cars = controller.cars;
  final titleController = TextEditingController(
    text: editingListing?.title ?? '',
  );
  final carNumberController = TextEditingController(
    text: editingListing?.carNumber ?? '',
  );
  final modelController = TextEditingController(
    text: editingListing?.model ?? '',
  );
  final fuelController = TextEditingController(
    text: editingListing?.fuelType ?? 'Petrol',
  );
  final yearController = TextEditingController(
    text: (editingListing?.year ?? DateTime.now().year).toString(),
  );
  final priceController = TextEditingController(
    text: editingListing == null ? '' : numberText(editingListing.price),
  );
  final odometerController = TextEditingController(
    text: editingListing == null ? '' : numberText(editingListing.odometerKm),
  );
  final transmissionController = TextEditingController(
    text: editingListing?.transmission ?? 'Manual',
  );
  final locationController = TextEditingController(
    text: editingListing?.location ?? 'Hyderabad',
  );
  final descriptionController = TextEditingController(
    text: editingListing?.description ?? '',
  );
  final bodyTypeController = TextEditingController(
    text: editingListing?.bodyType ?? 'SUV',
  );
  final colorController = TextEditingController(
    text: editingListing?.color ?? 'White',
  );
  final featuresController = TextEditingController(
    text: editingListing?.features.join(', ') ?? '',
  );
  final seatsController = TextEditingController(
    text: (editingListing?.seats ?? 5).toString(),
  );
  final ownersController = TextEditingController(
    text: (editingListing?.ownerCount ?? 1).toString(),
  );
  final rtoController = TextEditingController(
    text: editingListing?.rto ?? 'TS',
  );
  final media = <CarSaleMedia>[...?editingListing?.media];
  var selectedCar = isEditing
      ? null
      : sourceCar ?? (cars.isEmpty ? null : cars.first);
  var useExistingCar = !isEditing && selectedCar != null;

  void fillFromCar(CarProfile car) {
    titleController.text = '${car.year} ${car.model}';
    carNumberController.text = car.carNumber;
    modelController.text = car.model;
    fuelController.text = car.fuelType;
    yearController.text = car.year.toString();
  }

  if (!isEditing && selectedCar != null) {
    fillFromCar(selectedCar);
  }

  int parseInt(TextEditingController textController) {
    final digits = textController.text.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(digits) ?? 0;
  }

  double parsePrice() {
    final digits = priceController.text.replaceAll(RegExp(r'[^0-9.]'), '');
    return double.tryParse(digits) ?? 0;
  }

  List<String> parseFeatures() {
    return featuresController.text
        .split(',')
        .map((feature) => feature.trim())
        .where((feature) => feature.isNotEmpty)
        .toList(growable: false);
  }

  try {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final isOwner = controller.session?.role.isOwner ?? false;
            return SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  20,
                  18,
                  20,
                  MediaQuery.of(context).viewInsets.bottom + 18,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isEditing
                            ? 'Edit car post'
                            : isOwner
                            ? 'Post car for sale'
                            : 'Submit car for sale',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 14),
                      if (!isEditing && cars.isNotEmpty) ...[
                        SegmentedButton<bool>(
                          segments: [
                            ButtonSegment(
                              value: true,
                              icon: const Icon(Icons.garage_outlined),
                              label: Text(isOwner ? 'Garage car' : 'My car'),
                            ),
                            const ButtonSegment(
                              value: false,
                              icon: Icon(Icons.add_road_outlined),
                              label: Text('New car'),
                            ),
                          ],
                          selected: {useExistingCar},
                          onSelectionChanged: (selection) {
                            setSheetState(() {
                              useExistingCar = selection.first;
                              if (useExistingCar) {
                                selectedCar ??= cars.first;
                                fillFromCar(selectedCar!);
                              } else {
                                selectedCar = null;
                                titleController.clear();
                                carNumberController.clear();
                                modelController.clear();
                                fuelController.text = 'Petrol';
                                yearController.text = DateTime.now().year
                                    .toString();
                              }
                            });
                          },
                        ),
                        const SizedBox(height: 12),
                      ],
                      if (!isEditing && useExistingCar && cars.isNotEmpty)
                        DropdownButtonFormField<CarProfile>(
                          initialValue: selectedCar,
                          decoration: const InputDecoration(labelText: 'Car'),
                          items: cars
                              .map(
                                (car) => DropdownMenuItem(
                                  value: car,
                                  child: Text(
                                    '${car.carNumber} | ${car.model}',
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            if (value == null) return;
                            setSheetState(() {
                              selectedCar = value;
                              fillFromCar(value);
                            });
                          },
                        ),
                      if (!isEditing && useExistingCar && cars.isNotEmpty)
                        const SizedBox(height: 12),
                      TextField(
                        controller: titleController,
                        decoration: const InputDecoration(
                          labelText: 'Listing title',
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (isEditing || !useExistingCar) ...[
                        TextField(
                          controller: carNumberController,
                          textCapitalization: TextCapitalization.characters,
                          decoration: const InputDecoration(
                            labelText: 'Car number',
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: modelController,
                          decoration: const InputDecoration(
                            labelText: 'Model / variant',
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: fuelController,
                              decoration: const InputDecoration(
                                labelText: 'Fuel type',
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: yearController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Year',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: priceController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Expected price',
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: odometerController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Mileage driven',
                                suffixText: 'km',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: transmissionController,
                              decoration: const InputDecoration(
                                labelText: 'Transmission',
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: locationController,
                              decoration: const InputDecoration(
                                labelText: 'Location',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: descriptionController,
                        minLines: 3,
                        maxLines: 5,
                        decoration: const InputDecoration(
                          labelText: 'Detailed information',
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: bodyTypeController,
                              decoration: const InputDecoration(
                                labelText: 'Body Type',
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: colorController,
                              decoration: const InputDecoration(
                                labelText: 'Color',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: featuresController,
                        decoration: const InputDecoration(
                          labelText: 'Features',
                          hintText: 'Sunroof, camera, alloy wheels',
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: seatsController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Seats',
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: ownersController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Owners',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: rtoController,
                        textCapitalization: TextCapitalization.characters,
                        decoration: const InputDecoration(labelText: 'RTO'),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Pictures and videos',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      if (media.isNotEmpty)
                        SizedBox(
                          height: 88,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: media.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(width: 8),
                            itemBuilder: (context, index) {
                              final item = media[index];
                              return Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  SizedBox(
                                    width: 96,
                                    height: 78,
                                    child: _ListingMediaView(
                                      media: item,
                                      fallbackModel: modelController.text,
                                      fallbackYear:
                                          int.tryParse(yearController.text) ??
                                          DateTime.now().year,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  Positioned(
                                    right: -8,
                                    top: -8,
                                    child: IconButton.filled(
                                      iconSize: 16,
                                      visualDensity: VisualDensity.compact,
                                      style: IconButton.styleFrom(
                                        backgroundColor: AppPalette.black,
                                        foregroundColor: AppPalette.white,
                                      ),
                                      onPressed: () => setSheetState(
                                        () => media.removeAt(index),
                                      ),
                                      icon: const Icon(Icons.close_rounded),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          OutlinedButton.icon(
                            onPressed: () async {
                              final image = await localPicker.pickImage(
                                source: ImageSource.gallery,
                                imageQuality: 85,
                              );
                              if (image == null) return;
                              setSheetState(() {
                                media.add(
                                  CarSaleMedia(
                                    path: image.path,
                                    type: CarSaleMediaType.image,
                                    caption: 'Sale photo',
                                  ),
                                );
                              });
                            },
                            icon: const Icon(Icons.photo_outlined),
                            label: const Text('Add picture'),
                          ),
                          OutlinedButton.icon(
                            onPressed: () async {
                              final video = await localPicker.pickVideo(
                                source: ImageSource.gallery,
                              );
                              if (video == null) return;
                              setSheetState(() {
                                media.add(
                                  CarSaleMedia(
                                    path: video.path,
                                    type: CarSaleMediaType.video,
                                    caption: 'Sale video',
                                  ),
                                );
                              });
                            },
                            icon: const Icon(Icons.videocam_outlined),
                            label: const Text('Add video'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () {
                            final year =
                                int.tryParse(yearController.text.trim()) ??
                                DateTime.now().year;
                            if (isEditing) {
                              if (modelController.text.trim().isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Add the model before saving.',
                                    ),
                                  ),
                                );
                                return;
                              }
                              controller.updateSaleListing(
                                listingId: editingListing.id,
                                carNumber: carNumberController.text,
                                title: titleController.text,
                                model: modelController.text,
                                fuelType: fuelController.text,
                                year: year,
                                price: parsePrice(),
                                odometerKm: parseInt(odometerController),
                                transmission: transmissionController.text,
                                location: locationController.text,
                                description: descriptionController.text,
                                media: List<CarSaleMedia>.from(media),
                                bodyType: bodyTypeController.text,
                                color: colorController.text,
                                features: parseFeatures(),
                                seats: parseInt(seatsController),
                                ownerCount: parseInt(ownersController),
                                rto: rtoController.text,
                              );
                              Navigator.of(context).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Car post updated.'),
                                ),
                              );
                              return;
                            }

                            final existingCar = selectedCar;
                            if (useExistingCar && existingCar != null) {
                              controller.addSaleListingFromCar(
                                carId: existingCar.id,
                                price: parsePrice(),
                                odometerKm: parseInt(odometerController),
                                transmission: transmissionController.text,
                                location: locationController.text,
                                description: descriptionController.text,
                                media: List<CarSaleMedia>.from(media),
                                bodyType: bodyTypeController.text,
                                color: colorController.text,
                                features: parseFeatures(),
                                seats: parseInt(seatsController),
                                ownerCount: parseInt(ownersController),
                                rto: rtoController.text,
                              );
                            } else {
                              if (modelController.text.trim().isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Add the model before posting.',
                                    ),
                                  ),
                                );
                                return;
                              }
                              controller.addSaleListing(
                                carNumber: carNumberController.text,
                                title: titleController.text,
                                model: modelController.text,
                                fuelType: fuelController.text,
                                year: year,
                                price: parsePrice(),
                                odometerKm: parseInt(odometerController),
                                transmission: transmissionController.text,
                                location: locationController.text,
                                description: descriptionController.text,
                                media: List<CarSaleMedia>.from(media),
                                bodyType: bodyTypeController.text,
                                color: colorController.text,
                                features: parseFeatures(),
                                seats: parseInt(seatsController),
                                ownerCount: parseInt(ownersController),
                                rto: rtoController.text,
                              );
                            }
                            Navigator.of(context).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  isOwner
                                      ? 'Car posted to Wheels.'
                                      : 'Car submitted for owner approval.',
                                ),
                              ),
                            );
                          },
                          icon: Icon(
                            isEditing
                                ? Icons.save_outlined
                                : Icons.publish_rounded,
                          ),
                          label: Text(
                            isEditing
                                ? 'Save changes'
                                : isOwner
                                ? 'Post to Wheels'
                                : 'Submit for approval',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  } finally {
    titleController.dispose();
    carNumberController.dispose();
    modelController.dispose();
    fuelController.dispose();
    yearController.dispose();
    priceController.dispose();
    odometerController.dispose();
    transmissionController.dispose();
    locationController.dispose();
    descriptionController.dispose();
    bodyTypeController.dispose();
    colorController.dispose();
    featuresController.dispose();
    seatsController.dispose();
    ownersController.dispose();
    rtoController.dispose();
  }
}
