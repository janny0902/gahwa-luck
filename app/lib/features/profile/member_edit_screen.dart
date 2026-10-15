import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/hanji_background.dart';
import '../auth/auth_providers.dart';
import 'hanja_name_section.dart';
import 'member_repository.dart';
import 'profile_models.dart';
import 'profile_pickers.dart';

class MemberEditScreen extends ConsumerStatefulWidget {
  const MemberEditScreen({super.key, this.existing, this.initialKind});

  final Member? existing;
  final String? initialKind;

  @override
  ConsumerState<MemberEditScreen> createState() => _MemberEditScreenState();
}

class _MemberEditScreenState extends ConsumerState<MemberEditScreen> {
  late final TextEditingController _name;
  late String _hanja;
  late String _gender;
  late String _mbti;
  late String _hourLabel;
  late String _kind;
  late String _relation;
  late DateTime _birth;
  late bool _isLunar;
  late List<String> _relations;
  bool _saving = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final m = widget.existing;
    _name = TextEditingController(text: m?.name ?? '');
    _hanja = m?.hanja ?? '';
    _gender = (m != null && ProfilePickers.genders.contains(m.gender))
        ? m.gender
        : '남성';
    _mbti = (m != null && ProfilePickers.mbtis.contains(m.mbti))
        ? m.mbti
        : '모름';
    _hourLabel = ProfilePickers.hourLabelOf(m?.birthTime ?? '');
    final kind = m?.kind ?? widget.initialKind ?? 'family';
    _kind = ProfilePickers.kinds.any((k) => k.$1 == kind) ? kind : 'family';
    _isLunar = m?.isLunar ?? false;
    _birth = ProfilePickers.parseBirth(m?.birthDate ?? '');
    _relations = [
      ...ProfilePickers.relations,
      if (m != null &&
          m.relation.isNotEmpty &&
          !ProfilePickers.relations.contains(m.relation))
        m.relation,
    ];
    _relation = (m?.relation.isNotEmpty ?? false) ? m!.relation : '기타';
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
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('로그인이 필요합니다')),
      );
      return;
    }
    final name = _name.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('이름을 입력해 주세요')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final draft = Member(
        id: widget.existing?.id ?? '',
        userId: user.id,
        name: name,
        hanja: _hanja.trim(),
        relation: _relation,
        priority: widget.existing?.priority ?? 0,
        birthDate: ProfilePickers.formatBirth(_birth),
        birthTime: _hourLabel == '모름' ? '' : _hourLabel,
        isLunar: _isLunar,
        gender: _gender,
        mbti: _mbti == '모름' ? '' : _mbti,
        kind: _kind,
      );
      final repo = ref.read(memberRepositoryProvider);
      if (_isEdit) {
        await repo.update(draft);
      } else {
        await repo.add(user.id, draft);
      }
      ref.invalidate(membersProvider);
      if (mounted) Navigator.of(context).pop();
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
      appBar: AppBar(title: Text(_isEdit ? '가족·지인 수정' : '가족·지인 추가')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            '궁합에 불러올 사람입니다. 가능한 한 선택으로 입력해 주세요.',
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
            initialHanja: widget.existing?.hanja ?? '',
            onChanged: (hanja, skipped) => _hanja = skipped ? '' : hanja,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _kind,
            decoration: const InputDecoration(
              labelText: '구분',
              border: OutlineInputBorder(),
            ),
            items: [
              for (final k in ProfilePickers.kinds)
                DropdownMenuItem(value: k.$1, child: Text(k.$2)),
            ],
            onChanged: (v) => setState(() => _kind = v ?? _kind),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _relations.contains(_relation) ? _relation : '기타',
            decoration: const InputDecoration(
              labelText: '관계',
              border: OutlineInputBorder(),
            ),
            items: [
              for (final r in _relations)
                DropdownMenuItem(value: r, child: Text(r)),
            ],
            onChanged: (v) => setState(() => _relation = v ?? _relation),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _gender,
            decoration: const InputDecoration(
              labelText: '성별',
              border: OutlineInputBorder(),
            ),
            items: [
              for (final g in ProfilePickers.genders)
                DropdownMenuItem(value: g, child: Text(g)),
            ],
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
            items: [
              for (final h in ProfilePickers.hours)
                DropdownMenuItem(value: h, child: Text(h)),
            ],
            onChanged: (v) => setState(() => _hourLabel = v ?? _hourLabel),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: ProfilePickers.mbtis.contains(_mbti) ? _mbti : '모름',
            decoration: const InputDecoration(
              labelText: 'MBTI',
              border: OutlineInputBorder(),
            ),
            items: [
              for (final m in ProfilePickers.mbtis)
                DropdownMenuItem(value: m, child: Text(m)),
            ],
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
                : Text(_isEdit ? '저장' : '추가하기'),
          ),
        ],
      ),
      ),
    );
  }
}
