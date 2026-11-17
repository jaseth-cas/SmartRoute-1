import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smartroute_flutter/nucleo/constantes/app_constants.dart';
import 'package:smartroute_flutter/nucleo/modelos/models.dart';
import 'package:smartroute_flutter/nucleo/tema/colors.dart';
import 'package:smartroute_flutter/nucleo/utilidades/validators.dart';

/// Selector inteligente de colegios con búsqueda por aproximación y opción comodín
/// "Otro (especificar)" para colegios aún no registrados en el catálogo.
class SchoolSelectorField extends StatefulWidget {
  final String label;
  final String initialValue;
  final ValueChanged<String> onChanged;
  final FormFieldValidator<String>? validator;

  const SchoolSelectorField({
    super.key,
    this.label = 'Colegio de destino',
    required this.initialValue,
    required this.onChanged,
    this.validator,
  });

  @override
  State<SchoolSelectorField> createState() => _SchoolSelectorFieldState();
}

class _SchoolSelectorFieldState extends State<SchoolSelectorField> {
  static const String _otherOptionKey = '__OTHER__';

  late TextEditingController _customSchoolCtrl;
  late String _selectedSchool;
  bool _isOtherSelected = false;

  @override
  void initState() {
    super.initState();
    _customSchoolCtrl = TextEditingController();
    _syncFromValue(widget.initialValue);
  }

  @override
  void didUpdateWidget(covariant SchoolSelectorField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialValue != widget.initialValue &&
        widget.initialValue != _effectiveValue) {
      _syncFromValue(widget.initialValue);
    }
  }

  void _syncFromValue(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      _selectedSchool = AppConstants.penonomeSchools.first.name;
      _isOtherSelected = false;
      _customSchoolCtrl.text = '';
      return;
    }

    final matched = _findCatalogMatch(trimmed);
    if (matched != null) {
      _selectedSchool = matched.name;
      _isOtherSelected = false;
      _customSchoolCtrl.text = '';
    } else {
      _selectedSchool = _otherOptionKey;
      _isOtherSelected = true;
      _customSchoolCtrl.text = trimmed;
    }
  }

  SchoolLocation? _findCatalogMatch(String query) {
    final lower = query.toLowerCase();
    for (final s in AppConstants.penonomeSchools) {
      if (s.name.toLowerCase() == lower || s.shortName.toLowerCase() == lower) {
        return s;
      }
    }
    return null;
  }

  String get _effectiveValue =>
      _isOtherSelected ? _customSchoolCtrl.text.trim() : _selectedSchool;

  @override
  void dispose() {
    _customSchoolCtrl.dispose();
    super.dispose();
  }

  Future<void> _openSearchModal(FormFieldState<String> fieldState) async {
    final picked = await showDialog<String>(
      context: context,
      builder: (_) => _SchoolSearchDialog(selectedSchool: _selectedSchool),
    );

    if (picked == null || !mounted) return;

    setState(() {
      if (picked.startsWith('$_otherOptionKey:')) {
        final prefill = picked.substring('$_otherOptionKey:'.length);
        _selectedSchool = _otherOptionKey;
        _isOtherSelected = true;
        if (prefill.isNotEmpty) {
          _customSchoolCtrl.text = prefill;
        }
      } else {
        _selectedSchool = picked;
        _isOtherSelected = false;
      }
    });
    final nextVal = _effectiveValue;
    fieldState.didChange(nextVal);
    widget.onChanged(nextVal);
  }

  @override
  Widget build(BuildContext context) {
    return FormField<String>(
      initialValue: _effectiveValue,
      validator: widget.validator ??
          (v) => Validators.validateRequired(v, fieldName: 'El colegio'),
      builder: (fieldState) {
        final displayLabel = _isOtherSelected
            ? 'Otro (especificar colegio)'
            : _selectedSchool;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.label.toUpperCase(),
              style: GoogleFonts.jetBrainsMono(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.9,
                color: SmartColors.deepPetrol,
              ),
            ),
            const SizedBox(height: 8),
            InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => _openSearchModal(fieldState),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                  color: SmartColors.neuInset,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: fieldState.hasError
                        ? SmartColors.smartRed
                        : SmartColors.deepBlue.withValues(alpha: 0.16),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.school_outlined,
                      size: 20,
                      color: SmartColors.deepBlue,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        displayLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: SmartColors.deepBlack,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: SmartColors.deepPetrol,
                    ),
                  ],
                ),
              ),
            ),
            if (_isOtherSelected) ...[
              const SizedBox(height: 10),
              TextFormField(
                controller: _customSchoolCtrl,
                decoration: InputDecoration(
                  labelText: 'Nombre del colegio personalizado',
                  hintText: 'Ej. Escuela Nuevo Horizonte',
                  prefixIcon: const Icon(Icons.edit_location_alt_outlined),
                  filled: true,
                  fillColor: SmartColors.neuSurface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onChanged: (val) {
                  fieldState.didChange(val);
                  widget.onChanged(val);
                },
              ),
            ],
            if (fieldState.hasError)
              Padding(
                padding: const EdgeInsets.only(top: 6, left: 4),
                child: Text(
                  fieldState.errorText!,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5,
                    color: SmartColors.smartRed,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Diálogo con estado propio para gestionar el `TextEditingController` de búsqueda
/// de forma segura durante toda la animación de cierre y adaptarse al teclado virtual.
class _SchoolSearchDialog extends StatefulWidget {
  final String selectedSchool;

  const _SchoolSearchDialog({required this.selectedSchool});

  @override
  State<_SchoolSearchDialog> createState() => _SchoolSearchDialogState();
}

class _SchoolSearchDialogState extends State<_SchoolSearchDialog> {
  static const String _otherOptionKey = '__OTHER__';
  late final TextEditingController _searchCtrl;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    final viewInsetsBottom = MediaQuery.viewInsetsOf(context).bottom;
    final availableHeight = (screenHeight - viewInsetsBottom - 170).clamp(160.0, 380.0);

    final normalizedQuery = _query.trim().toLowerCase();
    final matches = AppConstants.penonomeSchools.where((school) {
      if (normalizedQuery.isEmpty) return true;
      return school.name.toLowerCase().contains(normalizedQuery) ||
          school.shortName.toLowerCase().contains(normalizedQuery) ||
          school.address.toLowerCase().contains(normalizedQuery) ||
          (school.code?.toLowerCase().contains(normalizedQuery) ?? false);
    }).toList();

    return AlertDialog(
      backgroundColor: SmartColors.neuSurface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
      ),
      title: Text(
        'SELECCIONAR COLEGIO',
        style: GoogleFonts.jetBrainsMono(
          fontSize: 13,
          fontWeight: FontWeight.w800,
          color: SmartColors.deepBlack,
        ),
      ),
      content: SizedBox(
        width: 420,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: availableHeight),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _searchCtrl,
                decoration: InputDecoration(
                  hintText: 'Buscar por nombre, siglas o sector...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  filled: true,
                  fillColor: SmartColors.neuInset,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (val) => setState(() => _query = val),
              ),
              const SizedBox(height: 10),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    ...matches.map(
                      (school) => ListTile(
                        dense: true,
                        leading: const Icon(
                          Icons.school_rounded,
                          color: SmartColors.deepBlue,
                          size: 20,
                        ),
                        title: Text(
                          school.name,
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: SmartColors.deepBlack,
                          ),
                        ),
                        subtitle: Text(
                          '${school.type} • ${school.address}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: SmartColors.smartGray,
                          ),
                        ),
                        trailing: widget.selectedSchool == school.name
                            ? const Icon(
                                Icons.check_circle_rounded,
                                color: SmartColors.smartGreen,
                                size: 18,
                              )
                            : null,
                        onTap: () => Navigator.of(context).pop(school.name),
                      ),
                    ),
                    const Divider(),
                    ListTile(
                      dense: true,
                      leading: const Icon(
                        Icons.add_business_rounded,
                        color: SmartColors.vibrantCyan,
                        size: 20,
                      ),
                      title: Text(
                        'Otro (especificar colegio)',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          color: SmartColors.deepBlue,
                        ),
                      ),
                      subtitle: Text(
                        normalizedQuery.isNotEmpty
                            ? 'Usar "$normalizedQuery" o escribir otro nombre'
                            : 'Si el colegio no aparece en el catálogo',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: SmartColors.smartGray,
                        ),
                      ),
                      onTap: () => Navigator.of(context).pop(
                        '$_otherOptionKey:${_searchCtrl.text.trim()}',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'CANCELAR',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: SmartColors.smartGray,
            ),
          ),
        ),
      ],
    );
  }
}
