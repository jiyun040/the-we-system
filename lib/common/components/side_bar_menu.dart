import 'side_bar_dependencies.dart';

class SideBarMenuSection extends StatelessWidget {
  const SideBarMenuSection({
    super.key,
    required this.title,
    required this.children,
    required this.isCompact,
  });

  final String title;
  final List<Widget> children;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!isCompact)
          Padding(
            padding: const EdgeInsets.only(
              left: TheWeSpacing.sm,
              bottom: TheWeSpacing.sm,
            ),
            child: Text(
              title,
              style: TheWeTextStyle.section.copyWith(
                color: TheWeColor.black500,
              ),
            ),
          ),
        ...children,
      ],
    );
  }
}

class SideBarMenuItem extends StatelessWidget {
  const SideBarMenuItem({
    super.key,
    required this.icon,
    required this.label,
    required this.isCompact,
    this.count,
    this.selected = false,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isCompact;
  final int? count;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = selected ? TheWeColor.blue300 : TheWeColor.black900;
    final isPhone = MediaQuery.sizeOf(context).width < 520;

    return Tooltip(
      message: isCompact ? label : '',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(TheWeRadius.md),
        child: Container(
          height: isPhone ? 38 : 42,
          margin: const EdgeInsets.only(bottom: TheWeSpacing.xxs),
          padding: EdgeInsets.symmetric(
            horizontal: isPhone ? 8 : (isCompact ? 10 : 12),
          ),
          decoration: BoxDecoration(
            color: selected
                ? TheWeColor.blue100.withValues(alpha: 0.45)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(TheWeRadius.md),
          ),
          child: Row(
            mainAxisAlignment: isCompact
                ? MainAxisAlignment.center
                : MainAxisAlignment.start,
            children: [
              Icon(icon, size: 18, color: foreground),
              if (!isCompact) ...[
                TheWeGaps.horizontalMd,
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TheWeTextStyle.body.copyWith(color: foreground),
                  ),
                ),
                if (count != null)
                  Text(
                    '$count',
                    style: TheWeTextStyle.caption.copyWith(
                      color: selected
                          ? TheWeColor.blue300
                          : TheWeColor.black500,
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
