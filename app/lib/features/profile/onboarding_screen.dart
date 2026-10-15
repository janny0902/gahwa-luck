import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/hanji_background.dart';
import '../auth/auth_providers.dart';
import 'hanja_name_section.dart';
import 'profile_models.dart';
import 'profile_pickers.dart';
import 'user_repository.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key, this.initial});

  final MyProfile? initial;

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  late final TextEditingController _name;
  late String _hanja;
  String _gender = '남성';
  String _mbti = '모름';
  String _hourLabel = '모름';
  DateTime _birth = DateTime(1990, 1, 1);
  bool _isLunar = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final p = widget.initial ?? const MyProfile();
    _name = TextEditingController(text: p.name);
    _hanja = p.hanja;
    if (p.gender.isNotEmpty && ProfilePickers.genders.contains(p.gender)) {
      _gender = p.gender;
    }
    if (p.mbti.isNotEmpty && ProfilePickers.mbtis.contains(p.mbti)) {
      _mbti = p.mbti;
    }
    _isLunar = p.isLunar;
    _birth = ProfilePickers.parseBirth(p.birthDate, fallback: _birth);
    _hourLabel = ProfilePickers.hourLabelOf(p.birthTime);
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _birth,
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
      helpText: '생년월일 선택',
    );
    if (picked != null) setState(() => _birth = picked);
  }

  Future<void> _save() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    final name = _name.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('이름을 입력해 주세요')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final birthDate = ProfilePickers.formatBirth(_birth);
      final profile = MyProfile(
        name: name,
        hanja: _hanja.trim(),
        gender: _gender,
        birthDate: birthDate,
        birthTime: _hourLabel == '모름' ? '' : _hourLabel,
        isLunar: _isLunar,
        mbti: _mbti == '모름' ? '' : _mbti,
      );
      await ref.read(userRepositoryProvider).saveMyProfile(user.id, profile);
      ref.invalidate(appUserProvider);
      if (!mounted) return;
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('프로필을 저장했습니다')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('저장 실패: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return HanjiBackground(
      calm: true,
      child: Scaffold(
      appBar: AppBar(title: const Text('프로필')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            '운세·궁합에 쓰일 기본 정보입니다. 가능한 한 선택으로 입력해 주세요.',
            style: TextStyle(color: AppColors.inkSoft),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _name,
            decoration: const InputDecoration(
              labelText: '이름',
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          HanjaNameSection(
            name: _name.text,
            initialHanja: widget.initial?.hanja ?? '',
            onChanged: (hanja, skipped) => _hanja = skipped ? '' : hanja,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue:
                ProfilePickers.genders.contains(_gender) ? _gender : '남성',
            decoration: const InputDecoration(
              labelText: '성별',
              border: OutlineInputBorder(),
            ),
            items: ProfilePickers.genders
                .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                .toList(),
            onChanged: (v) => setState(() => _gender = v ?? _gender),
          ),
          const SizedBox(height: 12),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('생년월일'),
            subtitle: Text(
              '${_birth.year}년 ${_birth.month}월 ${_birth.day}일',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            trailing: const Icon(Icons.calendar_month),
            onTap: _pickDate,
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('음력으로 입력'),
            value: _isLunar,
            activeThumbColor: AppColors.crimson,
            onChanged: (v) => setState(() => _isLunar = v),
          ),
          DropdownButtonFormField<String>(
            initialValue: _hourLabel,
            decoration: const InputDecoration(
              labelText: '태어난 시',
              border: OutlineInputBorder(),
            ),
            items: ProfilePickers.hours
                .map((h) => DropdownMenuItem(value: h, child: Text(h)))
                .toList(),
            onChanged: (v) => setState(() => _hourLabel = v ?? _hourLabel),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _mbti,
            decoration: const InputDecoration(
              labelText: 'MBTI',
              border: OutlineInputBorder(),
            ),
            items: ProfilePickers.mbtis
                .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                .toList(),
            onChanged: (v) => setState(() => _mbti = v ?? _mbti),
          ),
          const SizedBox(height: 28),
          ElevatedButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    widget.initial?.isComplete == true
                        ? '저장'
                        : '저장하고 시작하기',
                  ),
          ),
        ],
      ),
      ),
    );
  }
}
