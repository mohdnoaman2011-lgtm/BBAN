import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';

void main() => runApp(const BbanApp());

// ───────────────────────── Theme ─────────────────────────
class C {
  static const mint = Color(0xFF34D399);
  static const ink = Color(0xFF0B1F17);
  static const muted = Color(0xFF55695F);
  static const surface = Color(0xFFF3F7F5);
  static const line = Color(0xFFDCE6E0);
  static const deep = Color(0xFF0B7A55);
  static const onMint = Color(0xFF05231A);
  static const tint = Color(0xFFE6F6EE);
  static const tintLine = Color(0xFFBFE3D1);
  static const glow = Color(0x3834D399);
}

class BbanApp extends StatelessWidget {
  const BbanApp({super.key});

  @override
  Widget build(BuildContext context) {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: C.mint, surface: Colors.white),
      scaffoldBackgroundColor: Colors.white,
    );
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'BBAN',
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: base.copyWith(
        textTheme: GoogleFonts.ibmPlexSansArabicTextTheme(base.textTheme)
            .apply(bodyColor: C.ink, displayColor: C.ink),
      ),
      home: const ConverterScreen(),
    );
  }
}

// ───────────────────────── Model ─────────────────────────
class Bank {
  final String name;
  final String code; // رمز البنك (3 أرقام)
  final int digits; // عدد أرقام الحساب
  final String suffix; // اللاحقة
  const Bank({
    required this.name,
    required this.code,
    required this.digits,
    this.suffix = kDefaultSuffix,
  });
}

class _EditBank {
  final Bank bank;
  const _EditBank(this.bank);
}

const kAccountLength = 10; // أقصى عدد أرقام مسموح لرقم الحساب
const kDefaultSuffix = '0001'; // اللاحقة الافتراضية

String buildAccountPart(String account) => account; // بدون حشو بالأصفار
String buildBban(Bank b, String account) =>
    '${b.code}${buildAccountPart(account)}${b.suffix}';

// ───────────────────────── Converter screen ─────────────────────────
class ConverterScreen extends StatefulWidget {
  const ConverterScreen({super.key});

  @override
  State<ConverterScreen> createState() => _ConverterScreenState();
}

class _ConverterScreenState extends State<ConverterScreen> {
  final List<Bank> _banks = [
    const Bank(name: 'بنك الخرطوم · بنكك', code: '040', digits: 7, suffix: '0001'),
  ];
  late Bank _bank = _banks.first;
  final _ctrl = TextEditingController();

  bool get _ready => _ctrl.text.length == _bank.digits;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _pickBank() async {
    final picked = await showModalBottomSheet<Object>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (_) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          children: [
            for (final b in _banks)
              ListTile(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                leading: const _BankIcon(size: 38),
                title: Text(b.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text('${b.digits} أرقام'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (b == _bank) const Icon(Icons.check_circle, color: C.deep),
                    IconButton(
                      tooltip: 'تعديل',
                      icon: const Icon(Icons.edit_outlined, color: C.muted),
                      onPressed: () => Navigator.pop(context, _EditBank(b)),
                    ),
                  ],
                ),
                onTap: () => Navigator.pop(context, b),
              ),
            ListTile(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              leading: const Icon(Icons.add_circle_outline, color: C.deep),
              title: const Text('إضافة بنك جديد',
                  style: TextStyle(fontWeight: FontWeight.w600, color: C.deep)),
              onTap: () => Navigator.pop(context, 'add'),
            ),
          ],
        ),
      ),
    );

    if (!mounted || picked == null) return;
    if (picked is Bank) {
      setState(() {
        _bank = picked;
        _ctrl.clear();
      });
    } else if (picked is _EditBank) {
      final updated = await Navigator.push<Bank>(
        context,
        MaterialPageRoute(builder: (_) => AddBankScreen(initial: picked.bank)),
      );
      if (updated != null && mounted) {
        setState(() {
          final i = _banks.indexOf(picked.bank);
          final wasSelected = _bank == picked.bank;
          _banks[i] = updated;
          if (wasSelected) {
            _bank = updated;
            if (_ctrl.text.length > updated.digits) {
              _ctrl.text = _ctrl.text.substring(0, updated.digits);
            }
          }
        });
      }
    } else if (picked == 'add') {
      final created = await Navigator.push<Bank>(
        context,
        MaterialPageRoute(builder: (_) => const AddBankScreen()),
      );
      if (created != null && mounted) {
        setState(() {
          _banks.add(created);
          _bank = created;
          _ctrl.clear();
        });
      }
    }
  }

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: buildBban(_bank, _ctrl.text)));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم نسخ رقم BBAN'), behavior: SnackBarBehavior.floating),
    );
  }

  void _share() => Share.share('BBAN: ${buildBban(_bank, _ctrl.text)}');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const _GlowBlob(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _TopBar(title: 'تحويل رقم الحساب إلى BBAN', canPop: false),
                  const SizedBox(height: 28),
                  const _Label('البنك'),
                  _BankSelector(name: _bank.name, onTap: _pickBank),
                  const SizedBox(height: 20),
                  const _Label('رقم الحساب'),
                  _AccountField(
                    controller: _ctrl,
                    maxLength: _bank.digits,
                    onChanged: (_) => setState(() {}),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 8, right: 4),
                    child: Text(
                      'رقم الحساب في ${_bank.name} عادةً ${_bank.digits} أرقام',
                      style: const TextStyle(fontSize: 12.5, color: C.muted),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _BbanCard(bank: _bank, account: _ctrl.text, ready: _ready),
                  const Spacer(),
                  _PrimaryButton(label: 'نسخ الرقم', icon: Icons.copy_rounded, onPressed: _ready ? _copy : null),
                  const SizedBox(height: 12),
                  _OutlineButton(label: 'مشاركة', icon: Icons.ios_share_rounded, onPressed: _ready ? _share : null),
                  const SizedBox(height: 14),
                  const Text(
                    'راجع اسم المستفيد في تطبيق البنك قبل التأكيد',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12.5, color: C.muted),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ───────────────────────── Add bank screen ─────────────────────────
class AddBankScreen extends StatefulWidget {
  final Bank? initial; // عند تمريره تعمل الشاشة كشاشة تعديل
  const AddBankScreen({super.key, this.initial});

  @override
  State<AddBankScreen> createState() => _AddBankScreenState();
}

class _AddBankScreenState extends State<AddBankScreen> {
  late final _name = TextEditingController(text: widget.initial?.name ?? '');
  late final _code = TextEditingController(text: widget.initial?.code ?? '');
  late final _suffix = TextEditingController(text: widget.initial?.suffix ?? kDefaultSuffix);
  late int _digits = widget.initial?.digits ?? 7;
  bool get _isEdit => widget.initial != null;
  static const _presets = [7, 10, 13, 16];

  bool get _valid =>
      _name.text.trim().isNotEmpty && _code.text.length == 3 && _suffix.text.isNotEmpty;

  @override
  void dispose() {
    _name.dispose();
    _code.dispose();
    _suffix.dispose();
    super.dispose();
  }

  void _setDigits(int v) => setState(() => _digits = v.clamp(4, kAccountLength));

  void _save() => Navigator.pop(
        context,
        Bank(name: _name.text.trim(), code: _code.text, digits: _digits, suffix: _suffix.text),
      );

  @override
  Widget build(BuildContext context) {
    final name = _name.text.trim().isEmpty ? 'اسم البنك' : _name.text.trim();
    return Scaffold(
      body: Stack(
        children: [
          const _GlowBlob(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _TopBar(title: _isEdit ? 'تعديل بنك' : 'إضافة بنك جديد', canPop: true),
                  const SizedBox(height: 14),
                  const Text(
                    'أدخل بيانات البنك ليظهر التنبيه الصحيح للمستخدم.',
                    style: TextStyle(fontSize: 14, height: 1.7, color: C.muted),
                  ),
                  const SizedBox(height: 22),
                  const _Label('اسم البنك'),
                  _InputShell(
                    focused: true,
                    leading: const _BankIcon(size: 38, filled: true),
                    child: TextField(
                      controller: _name,
                      onChanged: (_) => setState(() {}),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      decoration: const InputDecoration(border: InputBorder.none, hintText: 'مثال: بنك الخرطوم'),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const _Label('رمز البنك (3 أرقام)'),
                            _InputShell(
                              child: TextField(
                                controller: _code,
                                onChanged: (_) => setState(() {}),
                                keyboardType: TextInputType.number,
                                textDirection: TextDirection.ltr,
                                textAlign: TextAlign.right,
                                inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(3)],
                                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, letterSpacing: 3),
                                decoration: const InputDecoration(border: InputBorder.none, hintText: '040', counterText: ''),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const _Label('رقم اللاحقة'),
                            _InputShell(
                              child: TextField(
                                controller: _suffix,
                                onChanged: (_) => setState(() {}),
                                keyboardType: TextInputType.number,
                                textDirection: TextDirection.ltr,
                                textAlign: TextAlign.right,
                                inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
                                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, letterSpacing: 3),
                                decoration: const InputDecoration(border: InputBorder.none, hintText: '0001', counterText: ''),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  const _Label('عدد أرقام الحساب'),
                  Container(
                    height: 72,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: C.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: C.line),
                    ),
                    child: Directionality(
                      textDirection: TextDirection.ltr,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _RoundBtn(icon: Icons.remove, filled: false, onTap: () => _setDigits(_digits - 1)),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text('$_digits', style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w700)),
                              const SizedBox(width: 8),
                              const Text('أرقام', style: TextStyle(fontSize: 14, color: C.muted)),
                            ],
                          ),
                          _RoundBtn(icon: Icons.add, filled: true, onTap: () => _setDigits(_digits + 1)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final p in _presets.where((p) => p <= kAccountLength))
                        ChoiceChip(
                          label: Text('$p'),
                          selected: _digits == p,
                          showCheckmark: false,
                          selectedColor: C.mint,
                          backgroundColor: Colors.white,
                          side: const BorderSide(color: C.line),
                          shape: const StadiumBorder(),
                          labelStyle: TextStyle(fontWeight: FontWeight.w700, color: _digits == p ? C.onMint : C.ink),
                          onSelected: (_) => _setDigits(p),
                        ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: C.tintLine),
                      gradient: const LinearGradient(colors: [C.tint, Colors.white], begin: Alignment.topRight, end: Alignment.bottomLeft),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('معاينة ما سيراه المستخدم',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF0B5A3B))),
                        const SizedBox(height: 8),
                        Text('رقم الحساب في $name عادةً $_digits أرقام',
                            style: const TextStyle(fontSize: 13.5, color: C.muted)),
                      ],
                    ),
                  ),
                  const Spacer(),
                  _PrimaryButton(label: _isEdit ? 'حفظ التعديلات' : 'حفظ البنك', onPressed: _valid ? _save : null),
                  const SizedBox(height: 12),
                  _OutlineButton(label: 'إلغاء', onPressed: () => Navigator.pop(context)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ───────────────────────── Shared widgets ─────────────────────────
class _GlowBlob extends StatelessWidget {
  const _GlowBlob();
  @override
  Widget build(BuildContext context) => const Positioned(
        top: -120,
        left: -80,
        child: IgnorePointer(
          child: SizedBox(
            width: 320,
            height: 320,
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [C.glow, Color(0x0034D399)]),
              ),
            ),
          ),
        ),
      );
}

class _TopBar extends StatelessWidget {
  final String title;
  final bool canPop;
  const _TopBar({required this.title, required this.canPop});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          if (canPop) ...[
            Material(
              color: C.surface,
              shape: const CircleBorder(side: BorderSide(color: C.line)),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () => Navigator.maybePop(context),
                child: const SizedBox(
                  width: 44,
                  height: 44,
                  child: Icon(Icons.arrow_forward_rounded, size: 20),
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
          ),
        ],
      );
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: C.muted)),
      );
}

class _BankIcon extends StatelessWidget {
  final double size;
  final bool filled;
  const _BankIcon({required this.size, this.filled = true});
  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(color: C.mint, shape: BoxShape.circle),
        child: const Icon(Icons.account_balance_outlined, size: 20, color: C.onMint),
      );
}

class _InputShell extends StatelessWidget {
  final Widget child;
  final Widget? leading;
  final Widget? trailing;
  final bool focused;
  const _InputShell({required this.child, this.leading, this.trailing, this.focused = false});

  @override
  Widget build(BuildContext context) => Container(
        height: 58,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: C.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: focused ? C.mint : C.line, width: focused ? 1.5 : 1),
          boxShadow: focused ? const [BoxShadow(color: C.glow, spreadRadius: 4)] : null,
        ),
        child: Row(
          children: [
            if (leading != null) ...[leading!, const SizedBox(width: 12)],
            Expanded(child: child),
            if (trailing != null) trailing!,
          ],
        ),
      );
}

class _BankSelector extends StatelessWidget {
  final String name;
  final VoidCallback onTap;
  const _BankSelector({required this.name, required this.onTap});

  @override
  Widget build(BuildContext context) => InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: _InputShell(
          leading: const _BankIcon(size: 38),
          trailing: const Icon(Icons.keyboard_arrow_down_rounded, color: C.muted),
          child: Text(name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        ),
      );
}

class _AccountField extends StatelessWidget {
  final TextEditingController controller;
  final int maxLength;
  final ValueChanged<String> onChanged;
  const _AccountField({required this.controller, required this.maxLength, required this.onChanged});

  @override
  Widget build(BuildContext context) => _InputShell(
        focused: true,
        trailing: Directionality(
          textDirection: TextDirection.ltr,
          child: Text('${controller.text.length} / $maxLength',
              style: const TextStyle(fontSize: 13, color: C.muted)),
        ),
        child: TextField(
          controller: controller,
          onChanged: onChanged,
          keyboardType: TextInputType.number,
          textDirection: TextDirection.ltr,
          textAlign: TextAlign.right,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(maxLength)],
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600, letterSpacing: 3),
          decoration: const InputDecoration(border: InputBorder.none, hintText: '1234567'),
        ),
      );
}

class _BbanCard extends StatelessWidget {
  final Bank bank;
  final String account;
  final bool ready;
  const _BbanCard({required this.bank, required this.account, required this.ready});

  @override
  Widget build(BuildContext context) => AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: ready ? C.tintLine : C.line),
          gradient: LinearGradient(
            colors: ready ? const [C.tint, Colors.white] : const [C.surface, Colors.white],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
          ),
          boxShadow: ready
              ? const [BoxShadow(color: Color(0x59107A55), blurRadius: 36, offset: Offset(0, 16), spreadRadius: -16)]
              : null,
        ),
        child: Column(
          children: [
            Row(
              children: [
                const Text('رقم BBAN', style: TextStyle(fontSize: 13, color: C.muted)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: ready ? C.mint : C.line,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    ready ? 'جاهز' : 'بانتظار رقم الحساب',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: ready ? C.onMint : C.muted),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Directionality(
              textDirection: TextDirection.ltr,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _Segment(value: bank.code, label: 'رمز البنك', accent: true),
                  _Segment(value: ready ? buildAccountPart(account) : '•' * bank.digits, label: 'رقم الحساب'),
                  _Segment(value: bank.suffix, label: 'اللاحقة', accent: true),
                ],
              ),
            ),
          ],
        ),
      );
}

class _Segment extends StatelessWidget {
  final String value, label;
  final bool accent;
  const _Segment({required this.value, required this.label, this.accent = false});

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Text(value,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: accent ? C.deep : C.ink)),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 12, color: C.muted)),
        ],
      );
}

class _RoundBtn extends StatelessWidget {
  final IconData icon;
  final bool filled;
  final VoidCallback onTap;
  const _RoundBtn({required this.icon, required this.filled, required this.onTap});

  @override
  Widget build(BuildContext context) => Material(
        color: filled ? C.mint : Colors.white,
        shape: CircleBorder(side: filled ? BorderSide.none : const BorderSide(color: C.tintLine)),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(width: 48, height: 48, child: Icon(icon, color: filled ? C.onMint : C.deep)),
        ),
      );
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  const _PrimaryButton({required this.label, this.icon, this.onPressed});

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 58,
        child: FilledButton.icon(
          onPressed: onPressed,
          icon: icon == null ? const SizedBox.shrink() : Icon(icon, size: 20),
          label: Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          style: FilledButton.styleFrom(
            backgroundColor: C.mint,
            foregroundColor: C.onMint,
            disabledBackgroundColor: C.line,
            disabledForegroundColor: C.muted,
            shape: const StadiumBorder(),
          ),
        ),
      );
}

class _OutlineButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  const _OutlineButton({required this.label, this.icon, this.onPressed});

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 58,
        child: OutlinedButton.icon(
          onPressed: onPressed,
          icon: icon == null ? const SizedBox.shrink() : Icon(icon, size: 20),
          label: Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          style: OutlinedButton.styleFrom(
            foregroundColor: C.ink,
            disabledForegroundColor: C.muted,
            side: const BorderSide(color: C.tintLine),
            shape: const StadiumBorder(),
          ),
        ),
      );
}
