import 'dart:io';

import 'package:flutter/material.dart';

import '../../controllers/theme_controller.dart';
import '../widgets/toast.dart';

/// 个性化设置页面：全局皮肤配色 + 自定义背景图。
class PersonalizationSettingsPage extends StatefulWidget {
  const PersonalizationSettingsPage({super.key, required this.themeController});

  final ThemeController themeController;

  @override
  State<PersonalizationSettingsPage> createState() =>
      _PersonalizationSettingsPageState();
}

class _PersonalizationSettingsPageState
    extends State<PersonalizationSettingsPage> {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('个性化')),
      body: AnimatedBuilder(
        animation: widget.themeController,
        builder: (context, _) {
          final tc = widget.themeController;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              // ===== 配色方案 =====
              _SectionHeader(title: '配色方案'),
              const SizedBox(height: 8),
              _SettingsCard(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                    child: Wrap(
                      spacing: 14,
                      runSpacing: 14,
                      children: ThemeController.presetColors.map((preset) {
                        final selected = tc.seedColor == preset.color;
                        return _ColorDot(
                          color: preset.color,
                          label: preset.name,
                          selected: selected,
                          onTap: () => tc.setSeedColor(preset.color),
                        );
                      }).toList(),
                    ),
                  ),
                  const _SettingsDivider(),
                  _SettingsTile(
                    icon: Icons.color_lens_rounded,
                    iconColor: colorScheme.primary,
                    title: '自定义配色',
                    subtitle: tc.hasCustomSeedColor
                        ? '当前已使用自定义颜色'
                        : '打开颜色选择器，手动挑选主题色',
                    onTap: () => _pickCustomSeedColor(),
                  ),
                  if (tc.hasCustomSeedColor) ...[
                    const _SettingsDivider(),
                    _SettingsTile(
                      icon: Icons.refresh_rounded,
                      iconColor: colorScheme.primary,
                      title: '恢复默认配色',
                      onTap: () => tc.setSeedColor(ThemeController.defaultSeedColor),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 24),
              // ===== 自定义背景图 =====
              _SectionHeader(title: '全局背景图'),
              const SizedBox(height: 8),
              _SettingsCard(
                children: [
                  _SettingsSwitchTile(
                    icon: Icons.image_rounded,
                    iconColor: colorScheme.primary,
                    title: '启用自定义背景',
                    subtitle: '在所有页面上方显示自定义背景图',
                    value: tc.backgroundEnabled,
                    onChanged: tc.backgroundImagePath == null
                        ? null
                        : (value) => tc.setBackgroundEnabled(value),
                  ),
                  const _SettingsDivider(),
                  _SettingsTile(
                    icon: Icons.photo_library_rounded,
                    iconColor: colorScheme.primary,
                    title: '选择背景图',
                    subtitle: tc.backgroundImagePath == null
                        ? '点击从相册选择图片'
                        : '已选择背景图',
                    onTap: () => _pickImage(),
                  ),
                  if (tc.backgroundImagePath != null) ...[
                    const _SettingsDivider(),
                    _SettingsTile(
                      icon: Icons.visibility_rounded,
                      iconColor: colorScheme.primary,
                      title: '背景预览',
                      subtitle: '点击查看当前背景效果',
                      onTap: () => _showPreview(context, tc.backgroundImagePath!),
                    ),
                    const _SettingsDivider(),
                    _BackgroundOpacitySlider(
                      value: tc.backgroundOpacity,
                      onChanged: (v) => tc.setBackgroundOpacity(v),
                    ),
                    const _SettingsDivider(),
                    _SettingsTile(
                      icon: Icons.delete_outline_rounded,
                      iconColor: colorScheme.error,
                      title: '移除背景图',
                      titleColor: colorScheme.error,
                      onTap: () => _confirmRemove(context),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 24),
              // ===== 背景预览区域 =====
              if (tc.backgroundImagePath != null) ...[
                _SectionHeader(title: '当前背景预览'),
                const SizedBox(height: 8),
                _BackgroundPreviewCard(imagePath: tc.backgroundImagePath!),
              ],
            ],
          );
        },
      ),
    );
  }

  Future<void> _pickImage() async {
    try {
      final success = await widget.themeController.pickAndSetBackgroundImage();
      if (!mounted) return;
      if (success) {
        Toast.success('背景图已设置');
      }
    } catch (error) {
      if (!mounted) return;
      Toast.error('选择图片失败：$error');
    }
  }

  Future<void> _pickCustomSeedColor() async {
    final pickedColor = await showDialog<Color>(
      context: context,
      builder: (context) => _CustomSeedColorDialog(
        initialColor: widget.themeController.seedColor,
      ),
    );
    if (pickedColor == null || !mounted) return;
    await widget.themeController.setSeedColor(pickedColor);
    if (!mounted) return;
    Toast.success('已应用自定义配色');
  }

  void _showPreview(BuildContext context, String path) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _FullBackgroundPreview(
          imagePath: path,
          opacity: widget.themeController.backgroundOpacity,
        ),
        fullscreenDialog: true,
      ),
    );
  }

  Future<void> _confirmRemove(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('移除背景图'),
        content: const Text('确定要移除自定义背景图吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('移除'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await widget.themeController.clearBackgroundImage();
      if (mounted) Toast.success('已移除背景图');
    }
  }
}

// ===== 颜色选择圆点 =====

class _ColorDot extends StatelessWidget {
  const _ColorDot({
    required this.color,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final Color color;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: selected
                  ? Border.all(color: Theme.of(context).colorScheme.onSurface, width: 3)
                  : null,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: .35),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: selected
                ? const Icon(Icons.check_rounded, color: Colors.white, size: 24)
                : null,
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                ),
          ),
        ],
      ),
    );
  }
}

// ===== 背景透明度滑块 =====

class _BackgroundOpacitySlider extends StatefulWidget {
  const _BackgroundOpacitySlider({
    required this.value,
    required this.onChanged,
  });

  final double value;
  final ValueChanged<double> onChanged;

  @override
  State<_BackgroundOpacitySlider> createState() => _BackgroundOpacitySliderState();
}

class _BackgroundOpacitySliderState extends State<_BackgroundOpacitySlider> {
  late double _current;

  @override
  void initState() {
    super.initState();
    _current = widget.value;
  }

  @override
  void didUpdateWidget(covariant _BackgroundOpacitySlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _current = widget.value;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Icon(Icons.opacity_rounded, size: 22, color: colorScheme.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '背景透明度',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const Spacer(),
                    Text(
                      '${(_current * 100).round()}%',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Slider(
                  value: _current,
                  min: 0.0,
                  max: 0.8,
                  divisions: 80,
                  label: '${(_current * 100).round()}%',
                  onChanged: (v) => setState(() => _current = v),
                  onChangeEnd: widget.onChanged,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ===== 自定义主题色选择器 =====

class _CustomSeedColorDialog extends StatefulWidget {
  const _CustomSeedColorDialog({required this.initialColor});

  final Color initialColor;

  @override
  State<_CustomSeedColorDialog> createState() => _CustomSeedColorDialogState();
}

class _CustomSeedColorDialogState extends State<_CustomSeedColorDialog> {
  late double _hue;
  late double _saturation;
  late double _value;

  @override
  void initState() {
    super.initState();
    final hsv = HSVColor.fromColor(widget.initialColor);
    _hue = hsv.hue;
    _saturation = hsv.saturation;
    _value = hsv.value;
  }

  Color get _color => HSVColor.fromAHSV(1.0, _hue, _saturation, _value).toColor();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final previewColor = _color;
    final previewOnColor = previewColor.computeLuminance() > 0.54
        ? Colors.black
        : Colors.white;

    return AlertDialog(
      title: const Text('自定义配色'),
      content: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: previewColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '主题预览',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: previewOnColor,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _hexColor(previewColor),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: previewOnColor.withValues(alpha: .9),
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _SliderField(
                label: '色相',
                valueLabel: '${_hue.round()}°',
                value: _hue,
                min: 0,
                max: 360,
                onChanged: (value) => setState(() => _hue = value),
              ),
              const SizedBox(height: 10),
              _SliderField(
                label: '饱和度',
                valueLabel: '${(_saturation * 100).round()}%',
                value: _saturation,
                min: 0,
                max: 1,
                onChanged: (value) => setState(() => _saturation = value),
              ),
              const SizedBox(height: 10),
              _SliderField(
                label: '明度',
                valueLabel: '${(_value * 100).round()}%',
                value: _value,
                min: 0,
                max: 1,
                onChanged: (value) => setState(() => _value = value),
              ),
            ],
          ),
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(ThemeController.defaultSeedColor),
          child: const Text('恢复默认'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(previewColor),
          child: const Text('应用'),
        ),
      ],
    );
  }

  String _hexColor(Color color) {
    final rgb = color.toARGB32() & 0x00FFFFFF;
    return '#${rgb.toRadixString(16).toUpperCase().padLeft(6, '0')}';
  }
}

class _SliderField extends StatelessWidget {
  const _SliderField({
    required this.label,
    required this.valueLabel,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final String label;
  final String valueLabel;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const Spacer(),
            Text(
              valueLabel,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: max == 1 ? 100 : 360,
          label: valueLabel,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

// ===== 背景预览卡片 =====

class _BackgroundPreviewCard extends StatelessWidget {
  const _BackgroundPreviewCard({required this.imagePath});

  final String imagePath;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        height: 160,
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.file(
                File(imagePath),
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  color: colorScheme.surfaceContainerHighest,
                  child: const Center(child: Icon(Icons.broken_image_rounded, size: 40)),
                ),
              ),
            ),
            Positioned.fill(
              child: ColoredBox(
                color: (isDark ? const Color(0xFF06070A) : Colors.white)
                    .withValues(alpha: 1 - 0.15),
              ),
            ),
            Positioned(
              left: 16,
              bottom: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '预览效果（透明度 15%）',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: colorScheme.onPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ===== 全屏背景预览 =====

class _FullBackgroundPreview extends StatelessWidget {
  const _FullBackgroundPreview({required this.imagePath, required this.opacity});

  final String imagePath;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('背景预览')),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.file(
              File(imagePath),
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Container(
                color: colorScheme.surfaceContainerHighest,
              ),
            ),
          ),
          Positioned.fill(
            child: ColoredBox(
              color: (isDark ? const Color(0xFF06070A) : Colors.white)
                  .withValues(alpha: 1 - opacity),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainer,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '背景透明度 ${(opacity * 100).round()}%',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '这是实际使用时的背景效果。内容卡片会叠加在背景图上方，透明度越高背景图越明显。',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
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
}

// ===== Shared widgets (mirrors settings_page.dart style) =====

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Column(children: children),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    this.iconColor,
    this.titleColor,
    this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final Color? iconColor;
  final String title;
  final Color? titleColor;
  final String? subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            SizedBox(
              width: 32,
              child: Icon(icon, size: 22, color: iconColor ?? colorScheme.primary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: titleColor,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ],
              ),
            ),
            if (onTap != null)
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: colorScheme.outline,
              ),
          ],
        ),
      ),
    );
  }
}

class _SettingsSwitchTile extends StatelessWidget {
  const _SettingsSwitchTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
    this.iconColor,
    this.subtitle,
  });

  final IconData icon;
  final Color? iconColor;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Icon(icon, size: 22, color: iconColor ?? colorScheme.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ],
            ),
          ),
          Switch.adaptive(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _SettingsDivider extends StatelessWidget {
  const _SettingsDivider();

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      indent: 62,
      color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: .4),
    );
  }
}
