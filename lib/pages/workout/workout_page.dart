// lib/pages/workout/workout_page.dart
//
// Fluxo por exercício:
//   1. Usuário vê o exercício atual, desempenho anterior e séries já salvas
//   2. Preenche peso + reps (+ lado se unilateral)
//   3. [Salvar Série] → salva no DB, incrementa série, inicia descanso
//   4. [Próximo →]   → vai ao próximo exercício (sem exigir série)
//   5. [Pular]       → pula sem registrar
//   6. Na última: [Finalizar] → dialog de resumo → volta ao Home

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/database/app_database.dart';
import '../../core/providers/providers.dart';
import '../../core/services/audio_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/week_utils.dart';

// Registro local de uma série (exibição imediata, sem roundtrip)
class _SetEntry {
  final int serie;
  final double peso;
  final int reps;
  final String lado;
  final String? equipamento;
  _SetEntry({
    required this.serie,
    required this.peso,
    required this.reps,
    required this.lado,
    this.equipamento,
  });
}

class WorkoutPage extends ConsumerStatefulWidget {
  final int dayId;
  final String dayName;
  final int sessionId;

  const WorkoutPage({
    super.key,
    required this.dayId,
    required this.dayName,
    required this.sessionId,
  });

  @override
  ConsumerState<WorkoutPage> createState() => _WorkoutPageState();
}

class _WorkoutPageState extends ConsumerState<WorkoutPage> {
  // ── Exercise list ───────────────────────────────────────────────
  List<Exercise> _exercises = [];
  int _currentIndex = 0;
  bool _loading = true;

  // ── Set tracking ────────────────────────────────────────────────
  int _currentSerie = 1;
  final List<_SetEntry> _setsLogged = [];
  List<ExerciseLog> _prevLogs = []; // último treino deste exercício

  // ── Inputs ──────────────────────────────────────────────────────
  final _pesoCtrl = TextEditingController(text: '0');
  final _repsCtrl = TextEditingController(text: '10');
  String _lado = 'ambos';
  String? _equipamentoSelecionado;
  bool _executandoUnilateral = false;

  // ── Rest timer ──────────────────────────────────────────────────
  bool _resting = false;
  int _restTotal = 90;
  int _restLeft = 90;
  Timer? _restTimer;

  // ── Session timer ───────────────────────────────────────────────
  int _sessionSecs = 0;
  Timer? _sessionTimer;

  // ── Lifecycle ───────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _loadExercises();
    _startSessionTimer();
  }

  @override
  void dispose() {
    _restTimer?.cancel();
    _sessionTimer?.cancel();
    _pesoCtrl.dispose();
    _repsCtrl.dispose();
    super.dispose();
  }

  // ── Data loading ────────────────────────────────────────────────

  Future<void> _loadExercises() async {
    final exs =
        await ref.read(exerciseDaoProvider).getExercisesForDay(widget.dayId);
    setState(() {
      _exercises = exs;
      _loading = false;
    });
    if (exs.isNotEmpty) await _loadExerciseContext();
  }

  Future<void> _loadExerciseContext() async {
    if (_exercises.isEmpty) return;
    final ex = _current;

    // Busca desempenho do último treino para pré-preencher os campos
    final prev = await ref.read(logDaoProvider).getLastLogsForExercise(ex.id);

    setState(() {
      _prevLogs = prev;
      _currentSerie = 1;
      _setsLogged.clear();
      _lado = 'ambos';
      _restTotal = ex.tempoDescansoSegundos;
      _executandoUnilateral = ex.isUnilateral;
      _equipamentoSelecionado = ex.equipamento;

      if (prev.isNotEmpty) {
        _pesoCtrl.text = prev.last.peso.toString();
        _repsCtrl.text = prev.last.repeticoes.toString();
      } else {
        _pesoCtrl.text = '0';
        _repsCtrl.text = '10';
      }
    });
  }

  // ── Timers ──────────────────────────────────────────────────────

  void _startSessionTimer() {
    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _sessionSecs++);
    });
  }

  void _startRestTimer(int seconds) {
    _restTimer?.cancel();
    setState(() {
      _resting = true;
      _restTotal = seconds;
      _restLeft = seconds;
    });
    _restTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() => _restLeft--);
      if (_restLeft <= 0) {
        t.cancel();
        AudioService().restEnd();
        setState(() => _resting = false);
      }
    });
  }

  void _skipRest() {
    _restTimer?.cancel();
    setState(() => _resting = false);
  }

  // ── Convenience getters ─────────────────────────────────────────

  Exercise get _current => _exercises[_currentIndex];
  bool get _isLast => _currentIndex >= _exercises.length - 1;

  // ── Actions ─────────────────────────────────────────────────────

  Future<void> _salvarSerie() async {
    final peso = double.tryParse(_pesoCtrl.text.replaceAll(',', '.')) ?? 0;
    final reps = int.tryParse(_repsCtrl.text) ?? 0;
    final logDao = ref.read(logDaoProvider);
    final now = DateTime.now().toIso8601String();

    if (_executandoUnilateral && _lado == 'ambos') {
      // Grava dois logs: esquerdo e direito
      for (final l in ['esquerdo', 'direito']) {
        await logDao.insertLog(ExerciseLogsCompanion.insert(
          exerciseId: _current.id,
          sessionId: widget.sessionId,
          data: now,
          peso: peso,
          repeticoes: reps,
          serie: Value(_currentSerie),
          lado: Value(l),
          equipamento: Value(_equipamentoSelecionado),
        ));
      }
    } else {
      await logDao.insertLog(ExerciseLogsCompanion.insert(
        exerciseId: _current.id,
        sessionId: widget.sessionId,
        data: now,
        peso: peso,
        repeticoes: reps,
        serie: Value(_currentSerie),
        lado: Value(_lado),
        equipamento: Value(_equipamentoSelecionado),
      ));
    }

    AudioService().beep();

    setState(() {
      _setsLogged.add(_SetEntry(
        serie: _currentSerie,
        peso: peso,
        reps: reps,
        lado: _lado,
        equipamento: _equipamentoSelecionado,
      ));
      _currentSerie++;
    });

    _startRestTimer(_current.tempoDescansoSegundos);
  }

  Future<void> _proximoExercicio() async {
    // Incrementa vezesFeito se ao menos uma série foi salva
    if (_setsLogged.isNotEmpty) {
      await ref.read(exerciseDaoProvider).incrementVezesFeito(_current.id);
    }

    _restTimer?.cancel();

    if (_isLast) {
      await _finalizarTreino();
    } else {
      setState(() {
        _currentIndex++;
        _resting = false;
      });
      await _loadExerciseContext();
    }
  }

  Future<void> _pularExercicio() async {
    _restTimer?.cancel();
    if (_isLast) {
      await _finalizarTreino();
    } else {
      setState(() {
        _currentIndex++;
        _resting = false;
      });
      await _loadExerciseContext();
    }
  }

  Future<void> _finalizarTreino() async {
    _sessionTimer?.cancel();
    _restTimer?.cancel();

    await ref
        .read(workoutDaoProvider)
        .finishSession(widget.sessionId, _sessionSecs);

    AudioService().workoutDone();

    if (!mounted) return;
    _showFinishDialog();
  }

  void _showFinishDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.card,
        title: Row(
          children: [
            const Icon(Icons.emoji_events_rounded, color: AppColors.warning),
            const SizedBox(width: 8),
            const Text('Treino Concluído!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _statRow('Duração', WeekUtils.formatDuration(_sessionSecs)),
            _statRow('Exercícios', '${_exercises.length}'),
            _statRow('Séries salvas', '${_setsLogged.length}'),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            child: const Text('Voltar ao Início'),
          ),
        ],
      ),
    );
  }

  Widget _statRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.onSurface)),
          Text(value,
              style: const TextStyle(
                  fontWeight: FontWeight.w700, color: AppColors.onBackground)),
        ],
      ),
    );
  }

  // ── Build ────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_exercises.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.dayName)),
        body: const Center(
          child: Text('Nenhum exercício configurado para este dia.'),
        ),
      );
    }

    final ex = _current;

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        final ok = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Sair do treino?'),
            content: const Text('O treino será marcado como em andamento.'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Continuar')),
              TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Sair')),
            ],
          ),
        );
        if (ok == true && context.mounted) Navigator.pop(context);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.dayName),
          actions: [
            // Cronômetro da sessão
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: Text(
                  WeekUtils.formatDuration(_sessionSecs),
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            // Barra de progresso
            LinearProgressIndicator(
              value: (_currentIndex + 1) / _exercises.length,
              minHeight: 3,
            ),

            // Banner de descanso
            if (_resting)
              _RestBanner(
                left: _restLeft,
                total: _restTotal,
                onSkip: _skipRest,
              ),

            // Conteúdo scrollável
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                children: [
                  // ── Contador + grupo ───────────────────────────
                  Row(
                    children: [
                      Text(
                        '${_currentIndex + 1} / ${_exercises.length}',
                        style: const TextStyle(
                          color: AppColors.onSurface,
                          fontSize: 13,
                        ),
                      ),
                      const Spacer(),
                      _Chip(ex.grupoMuscular),
                      if (ex.equipamento != 'Livre') ...[
                        const SizedBox(width: 6),
                        _Chip(ex.equipamento),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),

                  // ── Nome do exercício ──────────────────────────
                  Text(
                    ex.nome,
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          fontSize: 26,
                          letterSpacing: -0.5,
                        ),
                  ),

                  // ── Badges ────────────────────────────────────
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      if (ex.isUnilateral)
                        const _BadgeTag(
                          label: 'Unilateral',
                          icon: Icons.swap_horiz_rounded,
                        ),
                      _BadgeTag(
                        label: 'Descanso ${ex.tempoDescansoSegundos}s',
                        icon: Icons.timer_rounded,
                        color: AppColors.info,
                      ),
                      if (ex.link != null)
                        GestureDetector(
                          onTap: () => _openLink(ex.link!),
                          child: const _BadgeTag(
                            label: 'Ver referência',
                            icon: Icons.play_circle_rounded,
                            color: AppColors.warning,
                          ),
                        ),
                    ],
                  ),

                  // ── Desempenho anterior ────────────────────────
                  if (_prevLogs.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _PreviousPerformance(logs: _prevLogs, exercise: ex),
                  ],

                  // ── Séries já salvas nesta sessão ──────────────
                  if (_setsLogged.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _SetsList(sets: _setsLogged, exercise: ex),
                  ],

                  // ── Inputs ────────────────────────────────────
                  const SizedBox(height: 20),
                  _InputRow(
                    serie: _currentSerie,
                    pesoCtrl: _pesoCtrl,
                    repsCtrl: _repsCtrl,
                  ),

                  // ── Modo de Execução ──
                  const SizedBox(height: 16),
                  const Text(
                    'MODO DE EXECUÇÃO',
                    style: TextStyle(
                      color: AppColors.onSurface,
                      fontSize: 11,
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(value: false, label: Text('Bilateral'), icon: Icon(Icons.people_rounded)),
                      ButtonSegment(value: true, label: Text('Unilateral'), icon: Icon(Icons.person_rounded)),
                    ],
                    selected: {_executandoUnilateral},
                    onSelectionChanged: (v) {
                      setState(() {
                        _executandoUnilateral = v.first;
                        if (!_executandoUnilateral) {
                          _lado = 'ambos'; // Reseta para ambos
                        }
                      });
                    },
                  ),

                  // ── Lado (apenas se unilateral) ───────────────────
                  if (_executandoUnilateral) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'LADO EM EXECUÇÃO',
                      style: TextStyle(
                        color: AppColors.onSurface,
                        fontSize: 11,
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: 'ambos', label: Text('Ambos')),
                        ButtonSegment(value: 'esquerdo', label: Text('Esq.')),
                        ButtonSegment(value: 'direito', label: Text('Dir.')),
                      ],
                      selected: {_lado},
                      onSelectionChanged: (v) =>
                          setState(() => _lado = v.first),
                    ),
                  ],

                  // ── Equipamento Utilizado (Sobrescrever Recomendação) ──
                  const SizedBox(height: 16),
                  const Text(
                    'EQUIPAMENTO UTILIZADO',
                    style: TextStyle(
                      color: AppColors.onSurface,
                      fontSize: 11,
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _equipamentoSelecionado,
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    dropdownColor: AppColors.card,
                    items: const [
                      DropdownMenuItem(value: 'Livre', child: Text('Livre')),
                      DropdownMenuItem(value: 'Barra', child: Text('Barra')),
                      DropdownMenuItem(value: 'Haltere', child: Text('Haltere')),
                      DropdownMenuItem(value: 'Cabo', child: Text('Cabo')),
                      DropdownMenuItem(value: 'Máquina', child: Text('Máquina')),
                      DropdownMenuItem(value: 'Peso Corporal', child: Text('Peso Corporal')),
                      DropdownMenuItem(value: 'Smith', child: Text('Smith')),
                    ],
                    onChanged: (val) {
                      setState(() {
                        _equipamentoSelecionado = val;
                      });
                    },
                  ),

                  const SizedBox(height: 80),
                ],
              ),
            ),

            // ── Botões de ação ─────────────────────────────────
            _ActionBar(
              isLast: _isLast,
              resting: _resting,
              hasSets: _setsLogged.isNotEmpty,
              onSkip: _pularExercicio,
              onSalvarSerie: _salvarSerie,
              onProximo: _proximoExercicio,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openLink(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }
}

// ─── Sub-widgets ──────────────────────────────────────────────────────────────

class _RestBanner extends StatelessWidget {
  final int left;
  final int total;
  final VoidCallback onSkip;
  const _RestBanner(
      {required this.left, required this.total, required this.onSkip});

  @override
  Widget build(BuildContext context) {
    final progress = total > 0 ? left / total : 0.0;
    final m = (left ~/ 60).toString().padLeft(2, '0');
    final s = (left % 60).toString().padLeft(2, '0');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: const BoxDecoration(
        color: AppColors.card,
        border: Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 44,
            height: 44,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 3,
                  backgroundColor: AppColors.divider,
                  valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                ),
                Text(
                  '$m:$s',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onBackground,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'DESCANSO',
                style: TextStyle(
                  color: AppColors.onSurface,
                  fontSize: 10,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'Próxima série quando pronto',
                style: TextStyle(color: AppColors.onSurface, fontSize: 12),
              ),
            ],
          ),
          const Spacer(),
          TextButton(
            onPressed: onSkip,
            child: const Text('Pular'),
          ),
        ],
      ),
    );
  }
}

class _PreviousPerformance extends StatelessWidget {
  final List<ExerciseLog> logs;
  final Exercise exercise;
  const _PreviousPerformance({required this.logs, required this.exercise});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ÚLTIMO TREINO',
            style: TextStyle(
              color: AppColors.onSurface,
              fontSize: 10,
              letterSpacing: 1.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: logs.map((l) {
              final ladoStr = (l.lado != 'ambos') ? ' (${l.lado})' : '';
              final eqStr = (l.equipamento != null && l.equipamento != exercise.equipamento)
                  ? ' [${l.equipamento}]'
                  : '';
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'S${l.serie}: ${l.peso}kg × ${l.repeticoes}$ladoStr$eqStr',
                  style: const TextStyle(
                    color: AppColors.onBackground,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _SetsList extends StatelessWidget {
  final List<_SetEntry> sets;
  final Exercise exercise;
  const _SetsList({required this.sets, required this.exercise});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'SÉRIES SALVAS',
            style: TextStyle(
              color: AppColors.primaryLight,
              fontSize: 10,
              letterSpacing: 1.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: sets.map((s) {
              final ladoStr = (s.lado != 'ambos') ? ' (${s.lado})' : '';
              final eqStr = (s.equipamento != null && s.equipamento != exercise.equipamento)
                  ? ' [${s.equipamento}]'
                  : '';
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'S${s.serie}: ${s.peso}kg × ${s.reps}$ladoStr$eqStr',
                  style: const TextStyle(
                    color: AppColors.onBackground,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _InputRow extends StatelessWidget {
  final int serie;
  final TextEditingController pesoCtrl;
  final TextEditingController repsCtrl;
  const _InputRow({
    required this.serie,
    required this.pesoCtrl,
    required this.repsCtrl,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'SÉRIE $serie',
          style: const TextStyle(
            color: AppColors.onSurface,
            fontSize: 11,
            letterSpacing: 1.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
                child: _NumberField(
                    ctrl: pesoCtrl, label: 'Peso (kg)', decimal: true)),
            const SizedBox(width: 12),
            Expanded(child: _NumberField(ctrl: repsCtrl, label: 'Repetições')),
          ],
        ),
      ],
    );
  }
}

class _NumberField extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final bool decimal;
  const _NumberField({
    required this.ctrl,
    required this.label,
    this.decimal = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: ctrl,
      textAlign: TextAlign.center,
      keyboardType: TextInputType.numberWithOptions(decimal: decimal),
      style: const TextStyle(
        fontSize: 26,
        fontWeight: FontWeight.w700,
        color: AppColors.onBackground,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 12),
        contentPadding: const EdgeInsets.symmetric(vertical: 18),
      ),
    );
  }
}

class _ActionBar extends StatelessWidget {
  final bool isLast;
  final bool resting;
  final bool hasSets;
  final VoidCallback onSkip;
  final VoidCallback onSalvarSerie;
  final VoidCallback onProximo;

  const _ActionBar({
    required this.isLast,
    required this.resting,
    required this.hasSets,
    required this.onSkip,
    required this.onSalvarSerie,
    required this.onProximo,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        children: [
          // Pular exercício
          OutlinedButton(
            onPressed: onSkip,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            child: const Text('Pular'),
          ),
          const SizedBox(width: 8),

          // Salvar série
          Expanded(
            child: ElevatedButton.icon(
              onPressed: resting ? null : onSalvarSerie,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Salvar Série'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryDark,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Próximo / Finalizar
          Expanded(
            child: ElevatedButton(
              onPressed: onProximo,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(isLast ? 'Finalizar' : 'Próximo'),
                  const SizedBox(width: 4),
                  Icon(
                    isLast ? Icons.flag_rounded : Icons.arrow_forward_rounded,
                    size: 16,
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

class _Chip extends StatelessWidget {
  final String label;
  const _Chip(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.divider),
      ),
      child: Text(
        label,
        style: const TextStyle(color: AppColors.onSurface, fontSize: 11),
      ),
    );
  }
}

class _BadgeTag extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  const _BadgeTag({
    required this.label,
    required this.icon,
    this.color = AppColors.primaryLight,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  color: color, fontSize: 11, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
