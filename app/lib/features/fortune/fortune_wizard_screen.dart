import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/manseryeok/four_pillars.dart';
import '../../core/theme/app_theme.dart';
import '../ads/reward_ad_button.dart';
import '../profile/member_repository.dart';
import '../profile/profile_models.dart';
import '../profile/profile_pickers.dart';
import '../profile/user_repository.dart';
import 'fortune_api.dart';
import 'fortune_models.dart';
import 'fortune_result_screen.dart';

class FortuneWizardScreen extends ConsumerStatefulWidget {
  const FortuneWizardScreen({super.key, required this.category});

  final FortuneCategory category;

  @override
  ConsumerState<FortuneWizardScreen> createState() => _FortuneWizardScreenState();
}

class _FortuneWizardScreenState extends ConsumerState<FortuneWizardScreen> {
  String _period = '오늘';
  String _theme = '전체';
  String _purpose = '결혼';
  String _range = '이번 달 좋은 날';
  String _namingGender = '여성';
  String _thingKind = '강아지';
  String _thingMood = '귀여움';
  DateTime _eventDate = DateTime.now();
  final _name = TextEditingController();
  final _thingOther = TextEditingController();
  final _dreamNote = TextEditingController();
  final Set<String> _memberIds = {};
  final Set<String> _pickedSymbols = {};
  String _mood = '모름';
  String _dreamTime = '밤';
  String _place = '집';
  bool _busy = false;

  static const _periods = ['오늘', '이번 주', '이번 달', '올해'];
  static const _themes = ['전체', '재물·사업', '직장·이직', '연애·애정', '건강·휴식'];
  static const _purposes = ['결혼', '출산', '여행', '이사', '개업', '기타'];
  static const _ranges = ['올해 중 좋은 달', '이번 달 좋은 날', '가까운 좋은 날'];
  static const _symbolChoices = [
    '물', '불', '뱀', '호랑이', '금', '돈', '이빨', '집', '바다', '산', '아기', '조상', '비', '해',
  ];
  static const _moods = ['기쁨', '불안', '무서움', '평온', '슬픔', '모름'];
  static const _times = ['낮', '밤', '새벽', '모름'];
  static const _thingKinds = ['강아지', '고양이', '자동차', '그 외'];
  static const _thingMoods = ['귀여움', '든든', '발랄', '시크', '웃김'];
  static const _places = ['집', '산', '물가', '길', '직장', '모름'];

  @override
  void dispose() {
    _name.dispose();
    _thingOther.dispose();
    _dreamNote.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _eventDate,
      firstDate: DateTime(1920),
      lastDate: DateTime(2100),
      helpText: '날짜 선택',
    );
    if (picked != null) setState(() => _eventDate = picked);
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
    final chosen = members.where((m) => _memberIds.contains(m.id)).toList();
    if (widget.category.id == 'family' || widget.category.id == 'colleague') {
      if (chosen.isEmpty) {
        _toast('사람을 한 명 이상 선택해 주세요');
        return;
      }
      if (chosen.any((m) => m.birthDate.isEmpty)) {
        _toast('생년월일이 없는 사람은 궁합에 넣을 수 없습니다');
        return;
      }
    }
    if (widget.category.id == 'dream' && _pickedSymbols.isEmpty && _dreamNote.text.trim().isEmpty) {
      _toast('꿈에 나온 것을 하나 이상 고르거나 적어 주세요');
      return;
    }
    if (widget.category.id == 'thing_name' && _thingKind == '그 외' && _thingOther.text.trim().isEmpty) {
      _toast('무엇을 부를지 짧게 적어 주세요');
      return;
    }

    final natal = _pillarsOfProfile(profile);
    final today = pillarsFor(date: DateTime.now(), isLunar: false, hour: DateTime.now().hour);
    final input = <String, dynamic>{
      'profile': profile.toJson(),
      'natal': natal.toJson(),
      'today': today.toJson(),
      if (widget.category.id == 'my_fortune') 'period': _period,
      if (widget.category.id == 'my_fortune') 'theme': _theme,
      if (widget.category.id == 'family' || widget.category.id == 'colleague')
        'people': [
          for (final member in chosen)
            {
              'name': member.name,
              'hanja': member.hanja,
              'relation': member.relation,
              'gender': member.gender,
              'mbti': member.mbti,
              'pillars': _pillarsOfMember(member).toJson(),
            },
        ],
      if (widget.category.id == 'date_pick') ...{
        'purpose': _purpose,
        'range': _range,
        'anchor_date': ProfilePickers.formatBirth(_eventDate),
      },
      if (widget.category.id == 'naming') ...{
        'baby_gender': _namingGender,
        'birth_or_due': ProfilePickers.formatBirth(_eventDate),
        'desired_name': _name.text.trim(),
      },
      if (widget.category.id == 'thing_name') ...{
        'thing_kind': _thingKind,
        'thing_label': _thingKind == '그 외' ? _thingOther.text.trim() : _thingKind,
        'vibe': _thingMood,
        'owner_mbti': profile.mbti,
      },
      if (widget.category.id == 'dream') ...{
        'symbols': _pickedSymbols.toList(),
        'mood': _mood,
        'time': _dreamTime,
        'place': _place,
        'note': _dreamNote.text.trim(),
      },
    };

    setState(() => _busy = true);
    final future = ref.read(fortuneApiProvider).generate(
          category: widget.category.id,
          input: input,
          fourPillars: natal.toJson(),
        );
    final record = await Navigator.of(context).push<FortuneRecord>(
      MaterialPageRoute(
        builder: (_) => FortuneLoadingScreen(task: future),
      ),
    );
    if (!mounted) return;
    setState(() => _busy = false);
    ref.invalidate(appUserProvider);
    if (record == null) return;
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => FortuneResultScreen(record: record)),
    );
  }

  PillarSet _pillarsOfProfile(MyProfile profile) {
    return pillarsFor(
      date: ProfilePickers.parseBirth(profile.birthDate),
      isLunar: profile.isLunar,
      hour: hourFromLabel(profile.birthTime),
    );
  }

  PillarSet _pillarsOfMember(Member member) {
    return pillarsFor(
      date: ProfilePickers.parseBirth(member.birthDate),
      isLunar: member.isLunar,
      hour: hourFromLabel(member.birthTime),
    );
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final members = ref.watch(membersProvider).asData?.value ?? const <Member>[];
    final kind = widget.category.id == 'colleague' ? 'colleague' : 'family';
    final pool = members.where((m) => m.kind == kind || m.kind == 'other').toList();
    return Scaffold(
      appBar: AppBar(title: Text(widget.category.label)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            '부적 1개를 사용합니다.',
            style: const TextStyle(color: AppColors.inkSoft),
          ),
          const SizedBox(height: 16),
          ..._fields(pool),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _busy ? null : _submit,
            child: Text(widget.category.id == 'naming' || widget.category.id == 'thing_name' ? '이름 받기' : '운세 보기'),
          ),
        ],
      ),
    );
  }

  List<Widget> _fields(List<Member> pool) {
    switch (widget.category.id) {
      case 'my_fortune':
        return [
          _chips('기간', _periods, _period, (v) => setState(() => _period = v)),
          _chips('테마', _themes, _theme, (v) => setState(() => _theme = v)),
        ];
      case 'family':
      case 'colleague':
        if (pool.isEmpty) {
          return [
            const Text('설정에서 가족·지인을 먼저 추가해 주세요.'),
          ];
        }
        return [
          for (final member in pool)
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _memberIds.contains(member.id),
              activeColor: AppColors.crimson,
              title: Text(member.name),
              subtitle: Text(member.relation.isEmpty ? '관계 없음' : member.relation),
              onChanged: (v) {
                setState(() {
                  if (v ?? false) {
                    _memberIds.add(member.id);
                  } else {
                    _memberIds.remove(member.id);
                  }
                });
              },
            ),
        ];
      case 'date_pick':
        return [
          _chips('무엇의 날', _purposes, _purpose, (v) => setState(() => _purpose = v)),
          _chips('범위', _ranges, _range, (v) => setState(() => _range = v)),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('기준 날짜'),
            subtitle: Text('${_eventDate.year}년 ${_eventDate.month}월 ${_eventDate.day}일'),
            trailing: const Icon(Icons.calendar_month),
            onTap: _pickDate,
          ),
        ];
      case 'naming':
        return [
          _chips('아이 성별', const ['여성', '남성', '미정'], _namingGender, (v) => setState(() => _namingGender = v)),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('출산일 또는 예정일'),
            subtitle: Text('${_eventDate.year}년 ${_eventDate.month}월 ${_eventDate.day}일'),
            trailing: const Icon(Icons.calendar_month),
            onTap: _pickDate,
          ),
          TextField(
            controller: _name,
            decoration: const InputDecoration(
              labelText: '원하는 한글 이름 (없으면 비움)',
              border: OutlineInputBorder(),
            ),
          ),
        ];
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
        return [
          const Text('꿈에 나온 것'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final symbol in _symbolChoices)
                FilterChip(
                  label: Text(symbol),
                  selected: _pickedSymbols.contains(symbol),
                  onSelected: (v) {
                    setState(() {
                      if (v) {
                        _pickedSymbols.add(symbol);
                      } else {
                        _pickedSymbols.remove(symbol);
                      }
                    });
                  },
                ),
            ],
          ),
          const SizedBox(height: 12),
          _chips('기분', _moods, _mood, (v) => setState(() => _mood = v)),
          _chips('때', _times, _dreamTime, (v) => setState(() => _dreamTime = v)),
          _chips('장소', _places, _place, (v) => setState(() => _place = v)),
          TextField(
            controller: _dreamNote,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: '더 기억나는 장면 (선택)',
              border: OutlineInputBorder(),
            ),
          ),
        ];
    }
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

class FortuneLoadingScreen extends StatefulWidget {
  const FortuneLoadingScreen({super.key, required this.task});

  final Future<FortuneRecord> task;

  @override
  State<FortuneLoadingScreen> createState() => _FortuneLoadingScreenState();
}

class _FortuneLoadingScreenState extends State<FortuneLoadingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spin;

  @override
  void initState() {
    super.initState();
    _spin = AnimationController(vsync: this, duration: const Duration(seconds: 2))
      ..repeat();
    widget.task.then((record) {
      if (!mounted) return;
      Navigator.of(context).pop(record);
    }).catchError((Object error) {
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).pop();
      messenger.showSnackBar(SnackBar(content: Text('$error')));
    });
  }

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('운세를 보는 중')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 12),
          Center(
            child: RotationTransition(
              turns: _spin,
              child: Container(
                width: 72,
                height: 96,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFF6E27A),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.crimson, width: 2),
                ),
                child: const Text(
                  '福',
                  style: TextStyle(fontSize: 36, color: AppColors.crimson, fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            '부적을 펼치는 동안 아래 안내를 보아도 됩니다.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.inkSoft),
          ),
          const SizedBox(height: 20),
          const NativeLoadingAd(),
        ],
      ),
    );
  }
}
