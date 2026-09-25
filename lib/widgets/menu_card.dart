import 'package:flutter/material.dart';

/// Kartu menu beranda - padanan `Item` di `(home)/main.tsx` web: latar
/// gradasi lembut, lencana ikon bergradasi dengan glow di belakangnya.
class MenuCard extends StatelessWidget {
  const MenuCard({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.badge,
    required this.wash,
    required this.glow,
    required this.onTap,
  });

  final String title, description;
  final IconData icon;
  final List<Color> badge, wash;
  final Color glow;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(26),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: const Color(0xB3FFFFFF)),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: wash,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1A785624),
                blurRadius: 34,
                offset: Offset(0, 14),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(26),
            child: Stack(
              children: [
                Positioned(
                  right: -32,
                  top: -40,
                  child: IgnorePointer(
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [glow, glow.withOpacity(0)],
                          stops: const [0, 0.7],
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: badge,
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x40785624),
                              blurRadius: 24,
                              offset: Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Icon(icon, size: 26, color: Colors.white),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.2,
                                color: Color(0xFF1C1917),
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              description,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF0F766E),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: Color(0xFFA8A29E),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
