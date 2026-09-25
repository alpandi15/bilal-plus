import 'package:flutter/material.dart';

/// Kepala halaman dengan tombol kembali - padanan `SubHeader.tsx` di web.
class SubHeader extends StatelessWidget {
  const SubHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });
  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [Color(0xEBFFFBF3), Color(0xE0FFF4E0)],
        ),
        border: Border(bottom: BorderSide(color: Color(0x66FDE68A))),
        boxShadow: [
          BoxShadow(
            color: Color(0x1A785624),
            blurRadius: 30,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 56,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Material(
                  color: const Color(0xCCFFFFFF),
                  borderRadius: BorderRadius.circular(12),
                  elevation: 2,
                  shadowColor: const Color(0x1F785624),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => Navigator.of(context).maybePop(),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xB3FDE68A)),
                      ),
                      child: const Icon(
                        Icons.chevron_left_rounded,
                        size: 24,
                        color: Color(0xFF92400E),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.2,
                          color: Color(0xFF292524),
                        ),
                      ),
                      if (subtitle != null)
                        Text(
                          subtitle!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: Color(0xCCB45309),
                          ),
                        ),
                    ],
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
