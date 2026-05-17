// lib/pages/landing_page.dart
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math' as math;

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage>
    with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  bool _isScrolled = false;
  int _activeStep = 1;
  double _scrollOffset = 0.0; // for parallax
  bool _showBackToTop = false;

  // keys for fade-in sections
  final GlobalKey _fiturKey = GlobalKey();
  final GlobalKey _alurKey = GlobalKey();
  final GlobalKey _alatKey = GlobalKey();
  final GlobalKey _tentangKey = GlobalKey();
  final GlobalKey _statistikKey = GlobalKey();
  final GlobalKey _ctaKey = GlobalKey();

  final Set<String> _visibleSections = {};

  final ValueNotifier<double> _totalAlat = ValueNotifier(0);
  final ValueNotifier<double> _totalPinjam = ValueNotifier(0);
  final ValueNotifier<double> _totalQR = ValueNotifier(0);
  final ValueNotifier<double> _kalibrasiBulanIni = ValueNotifier(0);
  final ValueNotifier<double> _pengambilanBulanIni = ValueNotifier(0);

  late AnimationController _stepAnimController;
  late Animation<double> _stepFadeAnimation;

  // hover states for feature cards
  final Map<int, bool> _featureHovered = {};

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      final offset = _scrollController.offset;
      setState(() {
        _isScrolled = offset > 30;
        _scrollOffset = offset;
        _showBackToTop = offset > 500;
      });
      _checkVisibleSections();
    });

    _stepAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _stepFadeAnimation = CurvedAnimation(
      parent: _stepAnimController,
      curve: Curves.easeInOut,
    );
    _stepAnimController.forward();

    // Initialize hover map
    for (int i = 0; i < 6; i++) {
      _featureHovered[i] = false;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startCounter(_totalAlat, 102, 25);
      _startCounter(_totalPinjam, 28, 25);
      _startCounter(_totalQR, 102, 25);
      _startCounter(_kalibrasiBulanIni, 15, 25);
      _startCounter(_pengambilanBulanIni, 28, 25);
      // initial check
      _checkVisibleSections();
    });
  }

  void _startCounter(ValueNotifier<double> notifier, int target, int steps) {
    double current = 0;
    final step = target / steps;
    Timer.periodic(const Duration(milliseconds: 25), (timer) {
      current += step;
      if (current >= target) {
        notifier.value = target.toDouble();
        timer.cancel();
      } else {
        notifier.value = current;
      }
    });
  }

  void _changeStep(int newStep) {
    if (newStep == _activeStep) return;
    _stepAnimController.reverse().then((_) {
      setState(() => _activeStep = newStep);
      _stepAnimController.forward();
    });
  }

  void _checkVisibleSections() {
    final RenderObject? fiturRender = _fiturKey.currentContext
        ?.findRenderObject();
    final RenderObject? alurRender = _alurKey.currentContext
        ?.findRenderObject();
    final RenderObject? alatRender = _alatKey.currentContext
        ?.findRenderObject();
    final RenderObject? tentangRender = _tentangKey.currentContext
        ?.findRenderObject();
    final RenderObject? statistikRender = _statistikKey.currentContext
        ?.findRenderObject();
    final RenderObject? ctaRender = _ctaKey.currentContext?.findRenderObject();

    final screenHeight = MediaQuery.of(context).size.height;

    void check(GlobalKey key, String name, RenderObject? render) {
      if (render is RenderBox) {
        final offset = render.localToGlobal(Offset.zero);
        if (offset.dy < screenHeight * 0.8 && offset.dy > -100) {
          _visibleSections.add(name);
        } else {
          _visibleSections.remove(name);
        }
      }
    }

    check(_fiturKey, 'fitur', fiturRender);
    check(_alurKey, 'alur', alurRender);
    check(_alatKey, 'alat', alatRender);
    check(_tentangKey, 'tentang', tentangRender);
    check(_statistikKey, 'statistik', statistikRender);
    check(_ctaKey, 'cta', ctaRender);

    setState(() {}); // rebuild for AnimatedOpacity
  }

  void _scrollTo(double offset) {
    _scrollController.animateTo(
      offset,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _totalAlat.dispose();
    _totalPinjam.dispose();
    _totalQR.dispose();
    _kalibrasiBulanIni.dispose();
    _pengambilanBulanIni.dispose();
    _stepAnimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: _buildMobileDrawer(),
      body: Stack(
        children: [
          SingleChildScrollView(
            controller: _scrollController,
            child: Column(
              children: [
                _buildHeroSection(),
                _fadeInSection(_fiturKey, 'fitur', _buildFiturSection()),
                _fadeInSection(_alurKey, 'alur', _buildAlurSection()),
                _fadeInSection(_alatKey, 'alat', _buildAlatUnggulanSection()),
                _fadeInSection(_tentangKey, 'tentang', _buildTentangSection()),
                _fadeInSection(
                  _statistikKey,
                  'statistik',
                  _buildStatistikSection(),
                ),
                _fadeInSection(_ctaKey, 'cta', _buildCallToActionSection()),
                _buildFooter(),
              ],
            ),
          ),
          Positioned(top: 0, left: 0, right: 0, child: _buildNavbar()),
          if (_showBackToTop)
            Positioned(bottom: 24, right: 24, child: _buildBackToTopButton()),
        ],
      ),
    );
  }

  Widget _fadeInSection(GlobalKey key, String name, Widget child) {
    final visible = _visibleSections.contains(name);
    return AnimatedOpacity(
      key: key,
      duration: const Duration(milliseconds: 600),
      opacity: visible ? 1.0 : 0.0,
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 600),
        offset: visible ? Offset.zero : const Offset(0, 0.1),
        child: child,
      ),
    );
  }

  Widget _buildBackToTopButton() {
    return FloatingActionButton.small(
      backgroundColor: const Color(0xFFe6a817),
      onPressed: () {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      },
      child: const Icon(Icons.arrow_upward, color: Colors.white),
    );
  }

  // =============== NAVBAR ===============
  Widget _buildNavbar() {
    final isWide = MediaQuery.of(context).size.width > 768;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: EdgeInsets.symmetric(horizontal: isWide ? 24 : 12, vertical: 12),
      height: _isScrolled ? 60 : 72,
      decoration: BoxDecoration(
        color: _isScrolled
            ? Colors.white.withOpacity(0.95)
            : Colors.transparent,
        border: _isScrolled
            ? const Border(
                bottom: BorderSide(color: Color(0xFFFDE047), width: 1),
              )
            : null,
        boxShadow: _isScrolled
            ? [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          Row(
            children: [
              Container(
                height: 36,
                width: 36,
                decoration: BoxDecoration(
                  color: Colors.amber.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.scale, color: Color(0xFFa16207)),
              ),
              const SizedBox(width: 8),
              const Text(
                'Sismalat',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFa16207),
                ),
              ),
            ],
          ),
          const Spacer(),
          if (isWide) ..._buildDesktopNavItems(),
          if (!isWide)
            Builder(
              builder: (context) => IconButton(
                icon: Icon(
                  Icons.menu,
                  color: _isScrolled ? Colors.black87 : const Color(0xFFa16207),
                ),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMobileDrawer() {
    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFFEF3C7), Colors.amber.shade100],
                ),
              ),
              child: Row(
                children: [
                  Container(
                    height: 40,
                    width: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.scale, color: Color(0xFFa16207)),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Sismalat',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFa16207),
                    ),
                  ),
                ],
              ),
            ),
            _drawerItem('Beranda', 0),
            _drawerItem('Fitur', _sectionOffset('fitur')),
            _drawerItem('Alur', _sectionOffset('alur')),
            _drawerItem('Alat', _sectionOffset('alat')),
            _drawerItem('Tentang', _sectionOffset('tentang')),
            _drawerItem('Statistik', _sectionOffset('statistik')),
            _drawerItem('Kontak', _sectionOffset('cta') + 200), // approx
            const Divider(),
            ListTile(
              leading: const Icon(Icons.login),
              title: const Text('Masuk'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/login');
              },
            ),
          ],
        ),
      ),
    );
  }

  double _sectionOffset(String key) {
    // approximate offsets based on typical layout, will be updated by actual keys
    switch (key) {
      case 'fitur':
        return 600;
      case 'alur':
        return 1200;
      case 'alat':
        return 1800;
      case 'tentang':
        return 2400;
      case 'statistik':
        return 3000;
      case 'cta':
        return 3400;
      default:
        return 0;
    }
  }

  ListTile _drawerItem(String text, double offset) {
    return ListTile(
      title: Text(text),
      onTap: () {
        Navigator.pop(context);
        _scrollTo(offset);
      },
    );
  }

  List<Widget> _buildDesktopNavItems() {
    const style = TextStyle(
      color: Color(0xFF374151),
      fontWeight: FontWeight.w500,
      fontSize: 14,
    );
    return [
      _navButton('Beranda', 0, style),
      _navButton('Fitur', _sectionOffset('fitur'), style),
      _navButton('Alur', _sectionOffset('alur'), style),
      _navButton('Alat', _sectionOffset('alat'), style),
      _navButton('Tentang', _sectionOffset('tentang'), style),
      _navButton('Statistik', _sectionOffset('statistik'), style),
      _navButton('Kontak', _sectionOffset('cta') + 200, style),
      const SizedBox(width: 12),
      ElevatedButton(
        onPressed: () => Navigator.pushNamed(context, '/login'),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFe6a817),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        ),
        child: const Text('Masuk', style: TextStyle(fontSize: 14)),
      ),
    ];
  }

  Widget _navButton(String text, double offset, TextStyle style) {
    return TextButton(
      onPressed: () => _scrollTo(offset),
      child: Text(text, style: style),
    );
  }

  // =============== HERO with Parallax ===============
  Widget _buildHeroSection() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth > 768;
        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: isDesktop ? 32 : 16,
            vertical: isDesktop ? 100 : 80,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFFFEF9C3).withOpacity(0.4),
                Colors.white,
                Colors.blue.shade50,
              ],
            ),
          ),
          child: isDesktop
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(flex: 3, child: _buildHeroText(isDesktop)),
                    const SizedBox(width: 32),
                    Expanded(
                      flex: 2,
                      child: Transform.translate(
                        offset: Offset(0, -_scrollOffset * 0.05),
                        child: _buildHeroStatsCard(),
                      ),
                    ),
                  ],
                )
              : Column(
                  children: [
                    _buildHeroText(false),
                    const SizedBox(height: 24),
                    Transform.translate(
                      offset: Offset(0, -_scrollOffset * 0.03),
                      child: _buildHeroStatsCard(),
                    ),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildHeroText(bool isDesktop) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFFEF3C7),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text(
            'Unit Metrologi Disperindag Karawang',
            style: TextStyle(
              color: Color(0xFF92400E),
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
        const SizedBox(height: 16),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: 'Kelola Alat Ukur\n',
                style: TextStyle(
                  fontSize: isDesktop ? 40 : 30,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF111827),
                  height: 1.2,
                ),
              ),
              TextSpan(
                text: 'Lebih Cerdas & Akurat',
                style: TextStyle(
                  fontSize: isDesktop ? 40 : 30,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFFD97706),
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Sismalat adalah sistem manajemen alat ukur modern. Catat, pantau, dan kembalikan alat ukur dengan QR Code dalam satu platform terintegrasi.',
          style: TextStyle(fontSize: 15, color: Color(0xFF4B5563)),
        ),
        const SizedBox(height: 24),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            ElevatedButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/login'),
              icon: const Icon(Icons.arrow_forward, size: 20),
              label: const Text('Masuk ke Aplikasi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFe6a817),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                textStyle: const TextStyle(fontSize: 14),
              ),
            ),
            OutlinedButton.icon(
              onPressed: () => _scrollTo(_sectionOffset('fitur')),
              icon: const Icon(Icons.star, size: 20),
              label: const Text('Pelajari Fitur'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF374151),
                side: const BorderSide(color: Color(0xFFF59E0B)),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                textStyle: const TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHeroStatsCard() {
    return Card(
      elevation: 10,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _statItem(
              Icons.build,
              Colors.amber,
              'Total alat terdaftar',
              _totalAlat,
            ),
            const SizedBox(height: 16),
            _statItem(
              Icons.handshake,
              Colors.green,
              'Pengambilan bulan ini',
              _totalPinjam,
            ),
            const SizedBox(height: 16),
            _statItem(
              Icons.qr_code,
              Colors.blue,
              'QR Code Tergenerate',
              _totalQR,
            ),
          ],
        ),
      ),
    );
  }

  Widget _statItem(
    IconData icon,
    Color color,
    String label,
    ValueNotifier<double> notifier,
  ) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
              ValueListenableBuilder<double>(
                valueListenable: notifier,
                builder: (context, value, _) {
                  return Text(
                    value.toInt().toString(),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  // =============== FITUR with Hover Effects ===============
  Widget _buildFiturSection() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossCount = constraints.maxWidth > 768
            ? 3
            : (constraints.maxWidth > 480 ? 2 : 1);
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
          child: Column(
            children: [
              const Text(
                'Fitur Unggulan',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Semua yang Anda butuhkan untuk mengelola alat ukur dan kalibrasi dalam satu sistem.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 32),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossCount,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: crossCount == 1 ? 2.0 : 1.2,
                ),
                itemCount: 6,
                itemBuilder: (context, index) {
                  final features = [
                    {
                      'icon': Icons.inventory,
                      'title': 'Inventaris Alat',
                      'desc': 'Data lengkap, QR Code.',
                      'color': Colors.amber,
                    },
                    {
                      'icon': Icons.calendar_month,
                      'title': 'Kalibrasi Terjadwal',
                      'desc': 'Pantau jadwal, notifikasi.',
                      'color': Colors.green,
                    },
                    {
                      'icon': Icons.qr_code,
                      'title': 'QR Code & Mobile',
                      'desc': 'Scan QR ambil/kembalikan.',
                      'color': Colors.blue,
                    },
                    {
                      'icon': Icons.picture_as_pdf,
                      'title': 'Laporan & Cetak',
                      'desc': 'PDF resmi bertanda tangan.',
                      'color': Colors.purple,
                    },
                    {
                      'icon': Icons.group,
                      'title': 'Multi-Pengguna',
                      'desc': 'Admin, karyawan, super.',
                      'color': Colors.orange,
                    },
                    {
                      'icon': Icons.notifications,
                      'title': 'Notifikasi Cerdas',
                      'desc': 'Stok kritis, expired.',
                      'color': Colors.red,
                    },
                  ];
                  final f = features[index];
                  return _featureCard(
                    index,
                    f['icon'] as IconData,
                    f['title'] as String,
                    f['desc'] as String,
                    f['color'] as Color,
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _featureCard(
    int index,
    IconData icon,
    String title,
    String desc,
    Color color,
  ) {
    final isHovered = _featureHovered[index] ?? false;
    return MouseRegion(
      onEnter: (_) => setState(() => _featureHovered[index] = true),
      onExit: (_) => setState(() => _featureHovered[index] = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform: isHovered
            ? (Matrix4.identity()
                ..translate(0, -8)
                ..scale(1.03))
            : Matrix4.identity(),
        child: Card(
          elevation: isHovered ? 8 : 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {},
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0.9, end: 1.0),
                      duration: const Duration(milliseconds: 300),
                      builder: (context, value, child) {
                        return Transform.scale(scale: value, child: child);
                      },
                      child: Icon(icon, color: color, size: 30),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    desc,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // =============== ALUR (interaktif) ===============
  Widget _buildAlurSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 60),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFFEF9C3).withOpacity(0.5),
            Colors.yellow.shade50,
          ],
        ),
      ),
      child: Column(
        children: [
          const Text(
            'Bagaimana Cara Kerjanya?',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tiga langkah mudah menggunakan Sismalat. Tap untuk lihat panduan detail.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = constraints.maxWidth > 600;
              if (isDesktop) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: _buildStepCards(),
                );
              } else {
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(children: _buildStepCards()),
                );
              }
            },
          ),
          const SizedBox(height: 24),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _buildActiveStepDetail(key: ValueKey<int>(_activeStep)),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildStepCards() {
    return [
      _stepCard(1, 'Cari & Lihat Alat', Icons.search),
      const SizedBox(width: 12),
      _stepCard(2, 'Ambil Alat', Icons.handshake),
      const SizedBox(width: 12),
      _stepCard(3, 'Kembalikan Alat', Icons.undo),
    ];
  }

  Widget _stepCard(int step, String title, IconData icon) {
    final isActive = _activeStep == step;
    return GestureDetector(
      onTap: () => _changeStep(step),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: 130,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive ? const Color(0xFFe6a817) : Colors.grey.shade300,
            width: 2,
          ),
          boxShadow: isActive
              ? [BoxShadow(color: Colors.amber.withOpacity(0.3), blurRadius: 8)]
              : [],
        ),
        child: Column(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: isActive
                  ? const Color(0xFFFEF3C7)
                  : Colors.grey.shade100,
              child: Icon(
                icon,
                color: isActive ? const Color(0xFFc88a00) : Colors.grey,
                size: 28,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Langkah $step',
              style: TextStyle(
                color: isActive ? const Color(0xFFc88a00) : Colors.grey,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveStepDetail({Key? key}) {
    final detail = _getActiveStepDetail();
    return _detailCard(
      key: key,
      icon: detail.icon,
      title: detail.title,
      points: detail.points,
    );
  }

  ({IconData icon, String title, List<String> points}) _getActiveStepDetail() {
    switch (_activeStep) {
      case 1:
        return (
          icon: Icons.search,
          title: '1. Mencari & Melihat Detail Alat',
          points: [
            'Lihat daftar alat ukur dengan informasi ringkas (nama, merk, status kalibrasi).',
            'Gunakan pencarian dan filter berdasarkan kategori atau status.',
            'Klik Detail untuk melihat info lengkap: nomor seri, kapasitas, masa berlaku, foto, QR Code, dan riwayat kalibrasi.',
            'QR Code unik dapat ditampilkan langsung untuk identifikasi cepat.',
          ],
        );
      case 2:
        return (
          icon: Icons.handshake,
          title: '2. Mengambil Alat untuk Digunakan',
          points: [
            'Ambil alat dengan scan QR Code atau manual dari halaman detail.',
            'Isi formulir: jumlah alat, keperluan, dan nama pengambil.',
            'Sistem simpan catatan, stok alat otomatis diperbarui.',
            'Cetak bukti pengambilan PDF langsung dari aplikasi.',
          ],
        );
      case 3:
      default:
        return (
          icon: Icons.undo,
          title: '3. Mengembalikan Alat',
          points: [
            'Pengembalian melalui scan QR atau menu pengembalian.',
            'Pastikan jumlah sesuai, tambahkan catatan kondisi alat.',
            'Stok alat otomatis bertambah, status peminjaman menjadi Selesai.',
            'Admin dapat memantau semua riwayat pengembalian.',
          ],
        );
    }
  }

  Widget _detailCard({
    Key? key,
    required IconData icon,
    required String title,
    required List<String> points,
  }) {
    return Container(
      key: key,
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFDE047)),
        boxShadow: [
          BoxShadow(color: Colors.amber.withOpacity(0.1), blurRadius: 8),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: const Color(0xFFc88a00)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...points.map(
            (text) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• ', style: TextStyle(fontSize: 16)),
                  Expanded(
                    child: Text(
                      text,
                      style: const TextStyle(color: Color(0xFF374151)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =============== ALAT UNGGULAN ===============
  Widget _buildAlatUnggulanSection() {
    final tools = [
      {'name': 'Multimeter Digital', 'icon': Icons.bolt, 'color': Colors.blue},
      {
        'name': 'Timbangan Elektronik',
        'icon': Icons.scale,
        'color': Colors.green,
      },
      {
        'name': 'Termometer Infrared',
        'icon': Icons.thermostat,
        'color': Colors.red,
      },
      {
        'name': 'Jangka Sorong',
        'icon': Icons.straighten,
        'color': Colors.purple,
      },
      {'name': 'Pressure Gauge', 'icon': Icons.speed, 'color': Colors.orange},
      {
        'name': 'Stopwatch Kalibrasi',
        'icon': Icons.timer,
        'color': Colors.teal,
      },
    ];
    return Container(
      padding: const EdgeInsets.all(24),
      color: const Color(0xFFF9FAFB),
      child: Column(
        children: [
          const Text(
            'Alat yang Kami Kelola',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Berbagai alat ukur dan instrumen yang terdata dalam sistem.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: tools.map((tool) {
              return MouseRegion(
                cursor: SystemMouseCursors.click,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.95, end: 1.0),
                  duration: const Duration(milliseconds: 300),
                  builder: (context, value, child) {
                    return Transform.scale(scale: value, child: child);
                  },
                  child: SizedBox(
                    width: 110,
                    child: Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: [
                            CircleAvatar(
                              backgroundColor: (tool['color'] as Color)
                                  .withOpacity(0.1),
                              child: Icon(
                                tool['icon'] as IconData,
                                color: tool['color'] as Color,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              tool['name'] as String,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          TextButton.icon(
            onPressed: () => Navigator.pushNamed(context, '/login'),
            icon: const Icon(Icons.arrow_forward, size: 18),
            label: const Text('Lihat Semua Alat (Login)'),
          ),
        ],
      ),
    );
  }

  // =============== TENTANG ===============
  Widget _buildTentangSection() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth > 768;
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFFFEF3C7).withOpacity(0.5),
                Colors.yellow.shade50,
              ],
            ),
          ),
          child: isDesktop
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _tentangImage()),
                    const SizedBox(width: 24),
                    Expanded(child: _tentangText()),
                  ],
                )
              : Column(
                  children: [
                    _tentangImage(),
                    const SizedBox(height: 20),
                    _tentangText(),
                  ],
                ),
        );
      },
    );
  }

  Widget _tentangImage() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Image.network(
        'https://perindag.slemankab.go.id/wp-content/uploads/2025/09/Logo-Metrologi-Diedit.png',
        height: 150,
        errorBuilder: (_, __, ___) => const Icon(Icons.image, size: 100),
      ),
    );
  }

  Widget _tentangText() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text(
          'Tentang Unit Metrologi',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 12),
        Text(
          'Unit Metrologi Legal Dinas Perindustrian dan Perdagangan Kabupaten Karawang bertugas melaksanakan pelayanan tera, tera ulang, dan pengawasan alat‑alat ukur, takar, timbang, dan perlengkapannya (UTTP) sesuai peraturan perundangan. Kami memastikan keakuratan alat ukur yang digunakan masyarakat dan pelaku usaha.',
          style: TextStyle(color: Colors.black87),
        ),
        SizedBox(height: 8),
        Text(
          'Sismalat hadir sebagai sistem digital yang terintegrasi untuk mendukung operasional unit metrologi – mencatat inventaris alat, memantau kalibrasi, mencatat pengambilan dan pengembalian, serta memudahkan pelaporan.',
          style: TextStyle(color: Colors.black87),
        ),
      ],
    );
  }

  // =============== STATISTIK ===============
  Widget _buildStatistikSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Text(
            'Dalam Angka',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth > 500) {
                return Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  alignment: WrapAlignment.center,
                  children: _buildStatItems(),
                );
              } else {
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(children: _buildStatItems()),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  List<Widget> _buildStatItems() {
    return [
      _statBox('Alat Terdaftar', _totalAlat, const Color(0xFFe6a817)),
      _statBox('Kalibrasi Bulan Ini', _kalibrasiBulanIni, Colors.green),
      _statBox('Pengambilan Bulan Ini', _pengambilanBulanIni, Colors.blue),
      _statBox('Pelanggaran', ValueNotifier(0), Colors.purple),
    ];
  }

  Widget _statBox(String label, ValueNotifier<double> notifier, Color color) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 140,
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            ValueListenableBuilder<double>(
              valueListenable: notifier,
              builder: (context, value, _) {
                return Text(
                  value.toInt().toString(),
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Colors.black87),
            ),
          ],
        ),
      ),
    );
  }

  // =============== CALL TO ACTION ===============
  Widget _buildCallToActionSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFe6a817), Color(0xFFD97706)],
        ),
      ),
      child: Column(
        children: [
          const Text(
            'Siap Mengelola Alat Metrologi dengan Lebih Modern?',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Mulai sekarang, tingkatkan akurasi dan transparansi di unit metrologi Anda.',
            style: TextStyle(color: Colors.white70, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () => Navigator.pushNamed(context, '/login'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFFc88a00),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  textStyle: const TextStyle(fontSize: 14),
                ),
                child: const Text('Masuk ke Aplikasi'),
              ),
              OutlinedButton(
                onPressed: () => _scrollTo(_sectionOffset('fitur')),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  textStyle: const TextStyle(fontSize: 14),
                ),
                child: const Text('Fitur Lengkap'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // =============== FOOTER ===============
  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(24),
      color: const Color(0xFF111827),
      child: Column(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth > 600) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _footerColumns(),
                );
              } else {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _footerColumns()
                      .map(
                        (w) => Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: w,
                        ),
                      )
                      .toList(),
                );
              }
            },
          ),
          const SizedBox(height: 24),
          const Text(
            '© 2025 Dinas Perindustrian dan Perdagangan Kabupaten Karawang.',
            style: TextStyle(color: Colors.grey, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  List<Widget> _footerColumns() {
    return [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  height: 30,
                  width: 30,
                  decoration: BoxDecoration(
                    color: Colors.amber.shade100,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.scale, color: Color(0xFFa16207)),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Sismalat',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Sistem Manajemen Alat Ukur\nDinas Perindag Kab. Karawang.',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ],
        ),
      ),
      const SizedBox(width: 16),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Kontak',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Jl. Contoh No.123, Karawang',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            Text(
              '(0267) 123456',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            Text(
              'perindag@karawangkab.go.id',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ],
        ),
      ),
      const SizedBox(width: 16),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Navigasi',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            _footerLink('Beranda', 0),
            _footerLink('Fitur', _sectionOffset('fitur')),
            _footerLink('Alur', _sectionOffset('alur')),
            _footerLink('Alat', _sectionOffset('alat')),
            _footerLink('Tentang', _sectionOffset('tentang')),
            GestureDetector(
              onTap: () => Navigator.pushNamed(context, '/login'),
              child: const Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Text(
                  'Login',
                  style: TextStyle(color: Colors.amber, fontSize: 13),
                ),
              ),
            ),
          ],
        ),
      ),
    ];
  }

  Widget _footerLink(String text, double offset) {
    return GestureDetector(
      onTap: () => _scrollTo(offset),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Text(
          text,
          style: const TextStyle(color: Colors.grey, fontSize: 13),
        ),
      ),
    );
  }
}
