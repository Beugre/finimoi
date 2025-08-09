import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finimoi/presentation/widgets/common/custom_app_bar.dart';
import 'package:finimoi/data/providers/gamification_provider.dart';
import 'package:finimoi/domain/entities/question_model.dart';
import 'package:go_router/go_router.dart';

class QuizScreen extends ConsumerStatefulWidget {
  const QuizScreen({super.key});

  @override
  ConsumerState<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends ConsumerState<QuizScreen> {
  int? _selectedOptionIndex;
  bool? _isCorrect;
  bool _answered = false;

  void _submitAnswer(Question question) async {
    if (_selectedOptionIndex == null) return;

    setState(() {
      _answered = true;
    });

    final correct = await ref
        .read(gamificationServiceProvider)
        .submitQuizAnswer(question.id, _selectedOptionIndex!);

    setState(() {
      _isCorrect = correct;
    });
  }

  void _nextQuestion() {
    setState(() {
      _selectedOptionIndex = null;
      _isCorrect = null;
      _answered = false;
    });
    ref.invalidate(quizQuestionProvider);
  }

  @override
  Widget build(BuildContext context) {
    final questionAsync = ref.watch(quizQuestionProvider);

    return Scaffold(
      appBar: const CustomAppBar(title: 'Quiz Financier'),
      body: questionAsync.when(
        data: (question) {
          if (question == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Félicitations, vous avez répondu à toutes les questions !'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.pop(),
                    child: const Text('Retour aux récompenses'),
                  )
                ],
              ),
            );
          }
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  question.text,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 24),
                ...List.generate(question.options.length, (index) {
                  return _buildOption(context, question.options[index], index, question.correctAnswerIndex);
                }),
                const Spacer(),
                if (_answered)
                  _buildResult(context),
                if (!_answered)
                  ElevatedButton(
                    onPressed: _selectedOptionIndex != null ? () => _submitAnswer(question) : null,
                    child: const Text('Soumettre'),
                  ),
                if (_answered)
                  ElevatedButton(
                    onPressed: _nextQuestion,
                    child: const Text('Question suivante'),
                  ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Erreur: $err')),
      ),
    );
  }

  Widget _buildOption(BuildContext context, String text, int index, int correctIndex) {
    Color? color;
    if (_answered) {
      if (index == correctIndex) {
        color = Colors.green.withOpacity(0.3);
      } else if (index == _selectedOptionIndex) {
        color = Colors.red.withOpacity(0.3);
      }
    }

    return Card(
      color: color,
      child: ListTile(
        title: Text(text),
        onTap: _answered ? null : () {
          setState(() {
            _selectedOptionIndex = index;
          });
        },
        selected: _selectedOptionIndex == index,
      ),
    );
  }

  Widget _buildResult(BuildContext context) {
    if (_isCorrect == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _isCorrect! ? Colors.green.shade100 : Colors.red.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        _isCorrect! ? 'Bonne réponse ! +10 points' : 'Mauvaise réponse. Essayez encore !',
        style: TextStyle(
          color: _isCorrect! ? Colors.green.shade800 : Colors.red.shade800,
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
