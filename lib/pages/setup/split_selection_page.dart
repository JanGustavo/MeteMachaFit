// lib/pages/setup/split_selection_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/providers.dart';
import '../../core/theme/app_theme.dart';

class SplitSelectionPage extends ConsumerWidget {
  final bool isOnboarding;
  const SplitSelectionPage({super.key, this.isOnboarding = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: isOnboarding
          ? null
          : AppBar(
              title: const Text('ADICIONAR TREINO'),
              backgroundColor: Colors.transparent,
              elevation: 0,
            ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isOnboarding) ...[
                const SizedBox(height: 20),
                // Header do App
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.fitness_center_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'GYM TRACKER',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Título
                Text(
                  'Selecione seu\nTreino',
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        fontSize: 42,
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                        letterSpacing: -1.5,
                        color: Colors.white,
                      ),
                ),
                const SizedBox(height: 24),
              ] else ...[
                const SizedBox(height: 16),
                const Text(
                  'Selecione uma divisão abaixo para adicioná-la à sua lista de treinos ativos.',
                  style: TextStyle(
                    color: AppColors.onSurface,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Grid 2x2 dos Cards de Treino
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.85,
                  children: [
                    _buildSplitCard(
                      context,
                      ref,
                      tipo: 'ABC',
                      richTitle: RichText(
                        text: const TextSpan(
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                          ),
                          children: [
                            TextSpan(text: 'A', style: TextStyle(color: Colors.white)),
                            TextSpan(text: 'B', style: TextStyle(color: AppColors.primaryLight)),
                            TextSpan(text: 'C', style: TextStyle(color: Colors.white)),
                          ],
                        ),
                      ),
                      subtitle: 'Básico - 3 dias/sem.',
                      iconWidget: _buildWeightStackIcon(),
                      desc: 'Ideal para iniciantes ou quem tem tempo limitado. Foco em consistência.',
                      daysInfo: const [
                        'Dia A: Peito, Ombro e Tríceps',
                        'Dia B: Costas e Bíceps',
                        'Dia C: Perna e Core',
                      ],
                    ),
                    _buildSplitCard(
                      context,
                      ref,
                      tipo: 'ABCD',
                      richTitle: RichText(
                        text: const TextSpan(
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                          ),
                          children: [
                            TextSpan(text: 'A', style: TextStyle(color: Colors.white)),
                            TextSpan(text: 'B', style: TextStyle(color: AppColors.primaryLight)),
                            TextSpan(text: 'C', style: TextStyle(color: Colors.white)),
                            TextSpan(text: 'D', style: TextStyle(color: AppColors.primaryLight)),
                          ],
                        ),
                      ),
                      subtitle: 'Intermediário - 4 dias/sem.',
                      iconWidget: _buildDumbbellsIcon(),
                      desc: 'Excelente para quem já treina e quer isolar grupos musculares específicos.',
                      daysInfo: const [
                        'Dia A: Peito e Tríceps',
                        'Dia B: Costas e Bíceps',
                        'Dia C: Ombro e Core',
                        'Dia D: Perna Completa',
                      ],
                    ),
                    _buildSplitCard(
                      context,
                      ref,
                      tipo: 'ABCDE',
                      richTitle: RichText(
                        text: const TextSpan(
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                          ),
                          children: [
                            TextSpan(text: 'A', style: TextStyle(color: Colors.white)),
                            TextSpan(text: 'B', style: TextStyle(color: AppColors.primaryLight)),
                            TextSpan(text: 'C', style: TextStyle(color: Colors.white)),
                            TextSpan(text: 'D', style: TextStyle(color: AppColors.primaryLight)),
                            TextSpan(text: 'E', style: TextStyle(color: AppColors.primaryLight)),
                          ],
                        ),
                      ),
                      subtitle: 'Avançado - 5 dias/sem.',
                      iconWidget: _buildKettlebellIcon(),
                      desc: 'Foco alto em volume e intensidade, treinando quase todos os dias da semana.',
                      daysInfo: const [
                        'Dia A: Peito',
                        'Dia B: Costas',
                        'Dia C: Ombro',
                        'Dia D: Perna',
                        'Dia E: Braços (Bíceps e Tríceps)',
                      ],
                    ),
                    _buildSplitCard(
                      context,
                      ref,
                      tipo: 'CUSTOM',
                      richTitle: const Text(
                        'CUSTOM',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                          color: Colors.white,
                        ),
                      ),
                      subtitle: 'Crie sua própria rotina',
                      iconWidget: const Icon(
                        Icons.assignment_rounded,
                        size: 44,
                        color: AppColors.onSurface,
                      ),
                      desc: 'Crie um treino do zero, adicionando dias e exercícios conforme sua necessidade.',
                      daysInfo: const [
                        'Dia A: Meu Treino A (Personalizado)',
                      ],
                    ),
                  ],
                ),
              ),

              // Footer Text
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Toque para ver os detalhes',
                        style: TextStyle(color: AppColors.onSurface, fontSize: 13),
                      ),
                      SizedBox(width: 4),
                      Icon(Icons.star_rounded, size: 14, color: AppColors.primaryLight),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Card do Grid
  Widget _buildSplitCard(
    BuildContext context,
    WidgetRef ref, {
    required String tipo,
    required Widget richTitle,
    required String subtitle,
    required Widget iconWidget,
    required String desc,
    required List<String> daysInfo,
  }) {
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      color: AppColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.divider, width: 1),
      ),
      child: InkWell(
        onTap: () => _showDetailsSheet(
          context,
          ref,
          tipo: tipo,
          titleWidget: richTitle,
          subtitle: subtitle,
          desc: desc,
          daysInfo: daysInfo,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Título (A B C, etc.)
              richTitle,
              const SizedBox(height: 6),
              // Subtítulo
              Text(
                subtitle,
                style: const TextStyle(
                  color: AppColors.onSurface,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              // Ícone Customizado no centro/fim
              Center(child: iconWidget),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  // Detalhes em Bottom Sheet
  void _showDetailsSheet(
    BuildContext context,
    WidgetRef ref, {
    required String tipo,
    required Widget titleWidget,
    required String subtitle,
    required String desc,
    required List<String> daysInfo,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      titleWidget,
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(color: AppColors.onSurface, fontSize: 13),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const Divider(height: 24),
              const Text(
                'COMO FUNCIONA:',
                style: TextStyle(
                  color: AppColors.primaryLight,
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                desc,
                style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.4),
              ),
              const SizedBox(height: 16),
              const Text(
                'DIAS E GRUPOS MUSCULARES:',
                style: TextStyle(
                  color: AppColors.primaryLight,
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              ...daysInfo.map(
                (info) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_outline_rounded,
                          size: 16, color: AppColors.primaryLight),
                      const SizedBox(width: 8),
                      Text(
                        info,
                        style: const TextStyle(color: AppColors.onBackground, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(ctx); // Fecha o bottom sheet

                    // Adiciona o treino selecionado no banco
                    await ref.read(workoutDaoProvider).addSplit(tipo);
                    ref.invalidate(splitsProvider);
                    ref.invalidate(activeSplitProvider);
                    ref.invalidate(activeSplitDaysProvider);

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Treino adicionado com sucesso! ✓')),
                      );
                      if (!isOnboarding) {
                        Navigator.pop(context); // Volta ao Dashboard se não estiver no onboarding
                      }
                    }
                  },
                  child: const Text('ATIVAR ESTE TREINO'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── DESENHO DOS ÍCONES CUSTOMIZADOS ──────────────────────────────────────────

  // Ícone de pilha de anilhas
  Widget _buildWeightStackIcon() {
    return SizedBox(
      height: 50,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(4, (index) {
          final width = 36.0 + (index * 8.0);
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2.0),
            child: Container(
              width: width,
              height: 6,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.3 + (index * 0.15)),
                    AppColors.primaryLight.withValues(alpha: 0.5 + (index * 0.15)),
                  ],
                ),
                borderRadius: BorderRadius.circular(3),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.6),
                  width: 1,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // Ícone de halteres cruzados/paralelos
  Widget _buildDumbbellsIcon() {
    Widget dumbbell() {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 18,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primaryDark, AppColors.primaryLight],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          Container(
            width: 16,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(1),
            ),
          ),
          Container(
            width: 8,
            height: 18,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primaryDark, AppColors.primaryLight],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ],
      );
    }

    return SizedBox(
      height: 50,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          dumbbell(),
          const SizedBox(height: 6),
          Transform.translate(
            offset: const Offset(10, 0),
            child: dumbbell(),
          ),
        ],
      ),
    );
  }

  // Ícone de Kettlebell
  Widget _buildKettlebellIcon() {
    return SizedBox(
      width: 44,
      height: 50,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Alça
          Positioned(
            top: 4,
            child: Container(
              width: 28,
              height: 22,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.7),
                  width: 4.5,
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
              ),
            ),
          ),
          // Corpo redondo
          Positioned(
            bottom: 4,
            child: Container(
               width: 38,
               height: 32,
               decoration: BoxDecoration(
                 gradient: const LinearGradient(
                   colors: [AppColors.primaryDark, AppColors.primaryLight],
                   begin: Alignment.topLeft,
                   end: Alignment.bottomRight,
                 ),
                 borderRadius: BorderRadius.circular(19),
                 border: Border.all(
                   color: AppColors.primaryLight.withValues(alpha: 0.8),
                   width: 1,
                 ),
               ),
             ),
          ),
          // Detalhe de brilho/texto
          Positioned(
            bottom: 12,
            child: Text(
              'KG',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 9,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
