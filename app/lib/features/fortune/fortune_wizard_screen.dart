import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/hanji_background.dart';
import '../profile/member_edit_screen.dart';
import '../profile/member_repository.dart';
import '../profile/profile_models.dart';
import '../profile/profile_pickers.dart';
import '../profile/user_repository.dart';
import 'dream_symbols.dart';
import 'fortune_models.dart';
import 'fortune_runner.dart';

class FortuneWizardScreen extends ConsumerStatefulWidget {
  const FortuneWizardScreen({super.key, required this.category});

  final FortuneCategory category;

  @override
  ConsumerState<FortuneWizardScreen> createState() => _FortuneWizardScreenState();
}

class _FortuneWizardScreenState extends ConsumerState<FortuneWizardScreen> {
  String _period = '오늘';
  String _theme = '전체';
  final Set<String> _memberIds = {};

  String _purpose = '결혼';
  final _otherPurpose = TextEditingController();
  String? _partnerId;
  final _babyName = TextEditingController();
  bool _babyNameUndecided = true;
  String _babyGender = '모름';
  DateTime _dueDate = DateTime.now().add(const Duration(days: 90));
  final Set<String> _companionIds = {};
  String _country = '국내';
  final _city = TextEditingController();
  String _range = '연·월·일';
  String _year = '상관없음';
  String _month = '상관없음';

  String _namingGender = '여성';
  String _birthStatus = '예정일';
  DateTime _eventDate = DateTime.now();
  final List<TextEditingController> _candidates = [TextEditingController()];
  bool _noCandidate = false;

  String _thingKind = '강아지';
  String _thingMood = '귀여움';
  final _thingOther = TextEditingController();

  Set<String> _pickedSymbols = {};
  String _who = '나 혼자';
  String _action = '바라봄';
  String _mood = '모름';
  String _outcome = '잠에서 깸';
  String _dreamTime = '밤';
  String _place = '집';
  final _story = TextEditingController();
  String _reason = '그냥 궁금해서';
  final _reasonOther = TextEditingController();

  bool _busy = false;

  static const _periods = ['오늘', '이번 주', '이번 달', '올해'];
  static const _themes = ['전체', '재물·사업', '직장·이직', '연애·애정', '건강·휴식'];
  static const _purposes = ['결혼', '출산', '여행', '이사', '개업', '기타'];
  static const _ranges = ['연·월·일', '월·일', '일'];
  static const _countries = ['국내', '일본', '중국', '동남아', '미국', '유럽', '그 외'];
  static const _moods = ['기쁨', '불안', '무서움', '평온', '슬픔', '모름'];
  static const _times = ['낮', '밤', '새벽', '모름'];
  static const _places = ['집', '산', '물가', '길', '직장', '모름'];
  static const _whos = ['나 혼자', '가족', '친구·지인', '모르는 사람', '돌아가신 분', '모름'];
  static const _actions = ['바라봄', '받음', '주움', '먹음', '쫓김', '쫓아감', '싸움', '날아감', '빠짐', '잃어버림', '이야기함'];
  static const _outcomes = ['잘 끝남', '도망침', '잡힘', '잠에서 깸', '기억 안 남'];
  static const _reasons = ['그냥 궁금해서', '태몽 같아서', '마음이 불안해서', '좋은 일이 있을까 해서', '같은 꿈을 자꾸 꿔서', '기타'];
  static const _thingKinds = ['강아지', '고양이', '자동차', '그 외'];
  static const _thingMoods = ['귀여움', '든든', '발랄', '시크', '웃김'];

  String get _id => widget.category.id;

  @override
  void dispose() {
    _otherPurpose.dispose();
    _babyName.dispose();
    _city.dispose();
    for (final c in _candidates) {
      c.dispose();
    }
    _thingOther.dispose();
    _story.dispose();
    _reasonOther.dispose();
    super.dispose();
  }

  Future<DateTime?> _pickDate(DateTime initial, {DateTime? first, DateTime? last}) {
    return showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first ?? DateTime(1920),
      lastDate: last ?? DateTime(2100),
      helpText: '날짜 선택',
    );
  }

  Future<void> _addMember(String kind) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => MemberEditScreen(initialKind: kind)),
    );
    ref.invalidate(membersProvider);
  }

  String _dreamStoryDraft() {
    final symbols = _pickedSymbols.isEmpty ? '기억나는 것 없음' : _pickedSymbols.join(', ');
    return '$_dreamTime, $_place에서 꾼 꿈입니다. '
        '나온 것: $symbols. '
        '함께 나온 사람: $_who. '
        '꿈에서 한 일: $_action. '
        '그때 기분: $_mood. '
        '끝은: $_outcome.';
  }

  Future<void> _submit() async {
    final user = ref.read(appUserProvider).asData?.value;
    if (user == null) return;
    final profile = user.myProfile;
    if (!profile.isComplete) {
      _toast('프로필의 이름, 성별, 생년월일을 먼저 저장해 주세요');
      return;
    }
    final members = ref.read(membersProvider).asData?.value ?? const <Member>[];
    Member? byId(String? id) {
      for (final m in members) {
        if (m.id == id) return m;
      }
      return null;
    }

    final chosen = members.where((m) => _memberIds.contains(m.id)).toList();
    if (_id == 'family' || _id == 'colleague') {
      if (chosen.isEmpty) return _toast('사람을 한 명 이상 선택해 주세요');
      if (chosen.any((m) => m.birthDate.isEmpty)) {
        return _toast('생년월일이 없는 사람은 궁합에 넣을 수 없습니다');
      }
    }

    Map<String, dynamic>? purposeDetail;
    if (_id == 'date_pick') {
      switch (_purpose) {
        case '결혼':
          final partner = byId(_partnerId);
          if (partner == null) return _toast('배우자를 고르거나 추가해 주세요');
          if (partner.birthDate.isEmpty) return _toast('배우자의 생년월일을 먼저 넣어 주세요');
          purposeDetail = {'partner': personInput(partner)};
        case '출산':
          purposeDetail = {
            'baby_name': _babyNameUndecided ? '미정' : _babyName.text.trim(),
            'due_date': ProfilePickers.formatBirth(_dueDate),
            'baby_gender': _babyGender,
          };
        case '여행':
          purposeDetail = {
            'companions': [
              for (final m in members.where((m) => _companionIds.contains(m.id))) personInput(m),
            ],
            'country': _country,
            'city': _city.text.trim(),
          };
        case '기타':
          final other = _otherPurpose.text.trim();
          if (other.isEmpty) return _toast('어떤 날을 받을지 적어 주세요');
          purposeDetail = {'other_purpose': other};
      }
    }

    final candidates = _noCandidate
        ? const <String>[]
        : _candidates.map((c) => c.text.trim()).where((t) => t.isNotEmpty).toList();

    if (_id == 'dream') {
      if (_story.text.trim().isEmpty) _story.text = _dreamStoryDraft();
      if (_pickedSymbols.isEmpty && _story.text.trim().isEmpty) {
        return _toast('꿈에 나온 것을 하나 이상 고르거나 적어 주세요');
      }
      if (_reason == '기타' && _reasonOther.text.trim().isEmpty) {
        return _toast('해몽이 필요한 이유를 적어 주세요');
      }
    }
    if (_id == 'thing_name' && _thingKind == '그 외' && _thingOther.text.trim().isEmpty) {
      return _toast('무엇을 부를지 짧게 적어 주세요');
    }

    final input = <String, dynamic>{
      ...baseFortuneInput(profile),
      if (_id == 'my_fortune' || _id == 'family' || _id == 'colleague') 'period': _period,
      if (_id == 'my_fortune') 'theme': _theme,
      if (_id == 'family' || _id == 'colleague')
        'people': [for (final member in chosen) personInput(member)],
      if (_id == 'date_pick') ...{
        'purpose': _purpose == '기타' ? _otherPurpose.text.trim() : _purpose,
        'purpose_detail': ?purposeDetail,
        'range': _range,
        if (_range != '연·월·일' && _year != '상관없음') 'year': _year,
        if (_range == '일' && _month != '상관없음') 'month': _month,
      },
      if (_id == 'naming') ...{
        'baby_gender': _namingGender,
        'birth_status': _birthStatus,
        if (_birthStatus != '미정') 'birth_or_due': ProfilePickers.formatBirth(_eventDate),
        'candidates': candidates,
      },
      if (_id == 'thing_name') ...{
        'thing_kind': _thingKind,
        'thing_label': _thingKind == '그 외' ? _thingOther.text.trim() : _thingKind,
        'vibe': _thingMood,
        'owner_mbti': profile.mbti,
      },
      if (_id == 'dream') ...{
        'symbols': _pickedSymbols.toList(),
        'who': _who,
        'action': _action,
        'mood': _mood,
        'outcome': _outcome,
        'time': _dreamTime,
        'place': _place,
        'dream_story': _story.text.trim(),
        'reason': _reason == '기타' ? _reasonOther.text.trim() : _reason,
      },
    };

    setState(() => _busy = true);
    await runFortune(context, ref, category: _id, profile: profile, input: input);
    if (mounted) setState(() => _busy = false);
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final members = ref.watch(membersProvider).asData?.value ?? const <Member>[];
    return HanjiBackground(
      calm: true,
      child: Scaffold(
        appBar: AppBar(title: Text(widget.category.label)),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text('부적 1개를 사용합니다.', style: TextStyle(color: AppColors.inkSoft)),
            const SizedBox(height: 16),
            ..._fields(members),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _busy ? null : _submit,
              child: Text(_id == 'naming' || _id == 'thing_name' ? '이름 받기' : '운세 보기'),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _fields(List<Member> members) {
    switch (_id) {
      case 'my_fortune':
        return [
          _chips('기간', _periods, _period, (v) => setState(() => _period = v)),
          _chips('테마', _themes, _theme, (v) => setState(() => _theme = v)),
        ];
      case 'family':
      case 'colleague':
        final kind = _id == 'colleague' ? 'colleague' : 'family';
        final pool = members.where((m) => m.kind == kind || m.kind == 'other').toList();
        return [
          _chips('기간', _periods, _period, (v) => setState(() => _period = v)),
          const Text('함께 볼 사람', style: TextStyle(fontWeight: FontWeight.w700)),
          ..._memberChecks(pool, _memberIds),
          _addMemberButton(kind),
        ];
      case 'date_pick':
        return _datePickFields(members);
      case 'naming':
        return _namingFields();
      case 'thing_name':
        return [
          const Text('주인 사주와 MBTI, 요즘 말맛을 조금 섞어 부를 이름을 여러 개 드립니다.'),
          const SizedBox(height: 12),
          _chips('무엇을 부르나요', _thingKinds, _thingKind, (v) => setState(() => _thingKind = v)),
          if (_thingKind == '그 외')
            TextField(
              controller: _thingOther,
              decoration: const InputDecoration(
                labelText: '예: 토끼, 자전거, 가게',
                border: OutlineInputBorder(),
              ),
            ),
          _chips('결', _thingMoods, _thingMood, (v) => setState(() => _thingMood = v)),
        ];
      default:
        return _dreamFields();
    }
  }

  List<Widget> _datePickFields(List<Member> members) {
    final now = DateTime.now();
    final years = ['상관없음', for (var y = now.year; y <= now.year + 3; y++) '$y년'];
    final months = ['상관없음', for (var m = 1; m <= 12; m++) '$m월'];
    return [
      _chips('무엇의 날', _purposes, _purpose, (v) => setState(() => _purpose = v)),
      if (_purpose == '기타')
        _gap(TextField(
          controller: _otherPurpose,
          decoration: const InputDecoration(
            labelText: '어떤 날을 받을까요? (예: 첫 출근, 수술 없는 상담일)',
            border: OutlineInputBorder(),
          ),
        )),
      if (_purpose == '결혼') ...[
        const Text('배우자', style: TextStyle(fontWeight: FontWeight.w700)),
        const Text('이름, 한자, 생년월일, 태어난 시(모르면 모름)는 사람 추가에서 넣습니다.',
            style: TextStyle(color: AppColors.inkSoft)),
        for (final member in members)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              _partnerId == member.id ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              color: AppColors.crimson,
            ),
            title: Text(member.hanja.isEmpty ? member.name : '${member.name} (${member.hanja})'),
            subtitle: Text(member.birthDate.isEmpty ? '생년월일 없음' : member.birthDate),
            onTap: () => setState(() => _partnerId = member.id),
          ),
        _addMemberButton('family'),
      ],
      if (_purpose == '출산') ...[
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          value: _babyNameUndecided,
          activeColor: AppColors.crimson,
          title: const Text('아기 이름 미정'),
          onChanged: (v) => setState(() => _babyNameUndecided = v ?? true),
        ),
        if (!_babyNameUndecided)
          _gap(TextField(
            controller: _babyName,
            decoration: const InputDecoration(labelText: '아기 이름', border: OutlineInputBorder()),
          )),
        _dateTile('출산 예정일', _dueDate, () async {
          final picked = await _pickDate(_dueDate, first: DateTime(now.year - 1));
          if (picked != null) setState(() => _dueDate = picked);
        }),
        _chips('아기 성별', const ['여아', '남아', '모름'], _babyGender, (v) => setState(() => _babyGender = v)),
      ],
      if (_purpose == '여행') ...[
        const Text('동행자 (본인은 자동 포함)', style: TextStyle(fontWeight: FontWeight.w700)),
        ..._memberChecks(members, _companionIds),
        _addMemberButton('other'),
        _chips('나라', _countries, _country, (v) => setState(() => _country = v)),
        _gap(TextField(
          controller: _city,
          decoration: const InputDecoration(
            labelText: '도시 (선택, 예: 제주, 오사카)',
            border: OutlineInputBorder(),
          ),
        )),
      ],
      _chips('무엇을 받을까요', _ranges, _range, (v) => setState(() => _range = v)),
      if (_range != '연·월·일')
        _chips('연도 (선택)', years, _year, (v) => setState(() => _year = v)),
      if (_range == '일')
        _chips('월 (선택)', months, _month, (v) => setState(() => _month = v)),
    ];
  }

  List<Widget> _namingFields() {
    return [
      _chips('아이 성별', const ['여성', '남성', '미정'], _namingGender, (v) => setState(() => _namingGender = v)),
      _chips('태어난 날', const ['태어난 날', '예정일', '미정'], _birthStatus, (v) => setState(() => _birthStatus = v)),
      if (_birthStatus != '미정')
        _dateTile(_birthStatus == '예정일' ? '출산 예정일' : '태어난 날', _eventDate, () async {
          final picked = await _pickDate(_eventDate);
          if (picked != null) setState(() => _eventDate = picked);
        }),
      CheckboxListTile(
        contentPadding: EdgeInsets.zero,
        value: _noCandidate,
        activeColor: AppColors.crimson,
        title: const Text('후보 이름 없음'),
        subtitle: const Text('5개 모두 새로 추천받습니다'),
        onChanged: (v) => setState(() => _noCandidate = v ?? false),
      ),
      if (!_noCandidate) ...[
        const Text('후보 이름 (5개까지)', style: TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        for (var i = 0; i < _candidates.length; i++)
          _gap(TextField(
            controller: _candidates[i],
            decoration: InputDecoration(
              labelText: '후보 ${i + 1}',
              border: const OutlineInputBorder(),
              suffixIcon: _candidates.length > 1
                  ? IconButton(
                      tooltip: '지우기',
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        final removed = _candidates.removeAt(i);
                        setState(() {});
                        WidgetsBinding.instance.addPostFrameCallback((_) => removed.dispose());
                      },
                    )
                  : null,
            ),
          )),
        if (_candidates.length < 5)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              style: TextButton.styleFrom(minimumSize: const Size(88, 48)),
              onPressed: () => setState(() => _candidates.add(TextEditingController())),
              icon: const Icon(Icons.add),
              label: const Text('후보 추가'),
            ),
          ),
        const Text('적은 후보는 그대로 풀고, 모자란 만큼 새 이름을 더해 5개를 드립니다.',
            style: TextStyle(color: AppColors.inkSoft)),
      ],
    ];
  }

  List<Widget> _dreamFields() {
    return [
      DreamSymbolPicker(
        selected: _pickedSymbols,
        onChanged: (next) => setState(() => _pickedSymbols = next),
      ),
      const SizedBox(height: 16),
      _chips('누가 나왔나요', _whos, _who, (v) => setState(() => _who = v)),
      _chips('언제', _times, _dreamTime, (v) => setState(() => _dreamTime = v)),
      _chips('어디서', _places, _place, (v) => setState(() => _place = v)),
      _chips('꿈에서 한 일', _actions, _action, (v) => setState(() => _action = v)),
      _chips('그때 기분', _moods, _mood, (v) => setState(() => _mood = v)),
      _chips('어떻게 끝났나요', _outcomes, _outcome, (v) => setState(() => _outcome = v)),
      Align(
        alignment: Alignment.centerLeft,
        child: OutlinedButton.icon(
          style: OutlinedButton.styleFrom(minimumSize: const Size(88, 48)),
          onPressed: () => setState(() => _story.text = _dreamStoryDraft()),
          icon: const Icon(Icons.edit_note),
          label: const Text('고른 내용으로 꿈 이야기 만들기'),
        ),
      ),
      const SizedBox(height: 8),
      _gap(TextField(
        controller: _story,
        maxLines: 5,
        decoration: const InputDecoration(
          labelText: '꿈 이야기 (다른 부분은 고쳐 주세요)',
          alignLabelWithHint: true,
          border: OutlineInputBorder(),
        ),
      )),
      _chips('해몽이 필요한 이유', _reasons, _reason, (v) => setState(() => _reason = v)),
      if (_reason == '기타')
        _gap(TextField(
          controller: _reasonOther,
          decoration: const InputDecoration(labelText: '이유를 짧게', border: OutlineInputBorder()),
        )),
    ];
  }

  List<Widget> _memberChecks(List<Member> pool, Set<String> picked) {
    if (pool.isEmpty) {
      return [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Text('아직 등록한 사람이 없습니다. 아래에서 추가해 주세요.',
              style: TextStyle(color: AppColors.inkSoft)),
        ),
      ];
    }
    return [
      for (final member in pool)
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          value: picked.contains(member.id),
          activeColor: AppColors.crimson,
          title: Text(member.name),
          subtitle: Text(member.relation.isEmpty ? '관계 없음' : member.relation),
          onChanged: (v) {
            setState(() {
              if (v ?? false) {
                picked.add(member.id);
              } else {
                picked.remove(member.id);
              }
            });
          },
        ),
    ];
  }

  Widget _addMemberButton(String kind) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          style: TextButton.styleFrom(minimumSize: const Size(88, 48)),
          onPressed: () => _addMember(kind),
          icon: const Icon(Icons.person_add_alt),
          label: const Text('사람 추가'),
        ),
      ),
    );
  }

  Widget _dateTile(String label, DateTime value, VoidCallback onTap) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      subtitle: Text('${value.year}년 ${value.month}월 ${value.day}일'),
      trailing: const Icon(Icons.calendar_month),
      onTap: onTap,
    );
  }

  Widget _gap(Widget child) {
    return Padding(padding: const EdgeInsets.only(bottom: 12), child: child);
  }

  Widget _chips(String label, List<String> values, String selected, ValueChanged<String> onPick) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final value in values)
                ChoiceChip(
                  label: Text(value),
                  selected: selected == value,
                  onSelected: (_) => onPick(value),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
