import 'package:flutter/material.dart';

import '../resource/assets_manager.dart';
import '../resource/color_manager.dart';
import '../resource/font_manager.dart';
import '../resource/screen_manager.dart';
import '../routes_manager.dart';
import '../resource/style_manager.dart';
import '../resource/value_manager.dart';
import '../settings/widget/card_border.dart';

class RulesView extends StatefulWidget {
  const RulesView({super.key});

  @override
  State<RulesView> createState() => _RulesViewState();
}

class _RulesViewState extends State<RulesView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorManager.bagroundColor,
      appBar: AppBar(
        leading: GestureDetector(
          onTap: () { 
            Navigator.of(context).pop();
          },
          child: Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Container(
              decoration: BoxDecoration( 
                shape: BoxShape.circle,
                border: Border.all(width: 1, color: Color(0X33CDBDFF)),
              ),
              child: Icon(Icons.arrow_back, color: Colors.white),
            ),
          ),
        ),
        backgroundColor: ColorManager.bagroundColor,
        title: SizedBox(
          width: context.percentWidth(.5),
          child: Image.asset(ImageAssets.splashWordmark),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _Header(context: context),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppPadding.p22,
                AppPadding.p32,
                AppPadding.p22,
                AppPadding.p46,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SectionTitle('Preparação'),
                  const SizedBox(height: AppPadding.p16),
                  const _BulletList(
                    items: [
                      'Decidam se vocês estão jogando em equipes ou individualmente.',
                      'Cada jogador/equipe recebe uma carta de música (virada para cima), que mostra o nome da música, o artista e o ano de lançamento. Este é o lado sem o QR code e inicia a linha do tempo.',
                      'Você pode jogar uma partida mais simples sem usar fichas. No entanto, se quiser uma partida mais desafiadora, distribua 2 fichas de BEATSPAN para cada jogador/equipe.',
                      'Um jogador aleatório escaneia a carta do topo do baralho. Aquele que escanear ainda poderá jogar. Mantenha um único jogador para escanear ou alterne os jogadores; a escolha é de vocês!',
                      'Importante: Os jogadores que desempenham o papel de DJ não devem usar smartwatches (ex.: Apple Watch) durante a partida, pois eles podem revelar informações sobre a música na tela.',
                    ],
                  ),
                  const SizedBox(height: AppPadding.p32),

                  const _SectionTitle('Preparação da música'),
                  const SizedBox(height: AppPadding.p16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _InfoCard(
                          title: 'Spotify Free',
                          items: const [
                            '🔄 Sensor de giro — a música toca ao virar o celular',
                            '⏳ Contagem regressiva — 3 segundos e a música começa',
                          ],
                        ),
                      ),
                      const SizedBox(width: AppPadding.p16),
                      Expanded(
                        child: _InfoCard(
                          title: 'Spotify Premium',
                          items: const [
                            '🎵 Faixas completas — a música inteira',
                            '⚡ Prévias de 30s — modo rápido',
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppPadding.p32),

                  const _SectionTitle('Como jogar'),
                  const SizedBox(height: AppPadding.p16),
                  const _StepTile(
                    number: 1,
                    title: 'Escanear',
                    description:
                        'Um jogador escaneia uma carta usando o aplicativo, '
                        'e uma música começa a tocar.',
                  ),
                  const SizedBox(height: AppPadding.p16),
                  const _StepTile(
                    number: 2,
                    title: 'Colocar',
                    description:
                        'O jogador à esquerda do DJ coloca a carta (virada '
                        'para baixo) na posição em que acha correta na sua '
                        'linha do tempo.',
                  ),
                  const SizedBox(height: AppPadding.p16),
                  const _StepTile(
                    number: 3,
                    title: 'Virar',
                    description:
                        'Vire a carta para verificar se ela está na posição '
                        'correta da linha do tempo.',
                  ),
                  const SizedBox(height: AppPadding.p32),

                  const _SectionTitle('Vitória'),
                  const SizedBox(height: AppPadding.p16),
                  Text(
                    'O primeiro jogador (ou equipe) a acertar a posição de '
                    '10 cartas em sua linha do tempo vence o jogo!',
                    style: getRegularStyle(
                      color: ColorManager.white,
                      fontSize: FontSize.s16,
                    ),
                  ),
                  const SizedBox(height: AppPadding.p32),

                  const _SectionTitle('Usando as fichas'),
                  const SizedBox(height: AppPadding.p16),
                  const _BulletList(
                    items: [
                      'No seu turno: use 1 ficha para pular a música e receber '
                          'uma carta nova.',
                      'No turno do oponente: grite "HITSTER" e use 1 ficha '
                          'para colocar a carta também na sua linha do tempo.',
                      'A qualquer momento: use 3 fichas para pegar uma carta '
                          'sem precisar adivinhar a posição.',
                    ],
                  ),
                  const SizedBox(height: AppPadding.p16),
                  Text(
                    'Ganhando fichas: acertar o nome da música e do artista '
                    'garante 1 ficha extra (máximo de 5).',
                    style: getRegularStyle(
                      color: ColorManager.white,
                      fontSize: FontSize.s16,
                    ),
                  ),
                  const SizedBox(height: AppPadding.p32),

                  const _SectionTitle('Variantes'),
                  const SizedBox(height: AppPadding.p16),
                  _InfoCard(
                    title: 'Profissional',
                    items: const [
                      'É obrigatório acertar o artista e a música.',
                      '5 fichas iniciais, sem ganhar novas.',
                    ],
                  ),
                  const SizedBox(height: AppPadding.p16),
                  _InfoCard(
                    title: 'Especialista',
                    items: const [
                      'É obrigatório acertar o artista, a música e o ano '
                          'exato.',
                      '3 fichas iniciais, sem ganhar novas.',
                    ],
                  ),
                  const SizedBox(height: AppPadding.p16),
                  _InfoCard(
                    title: 'Cooperativo',
                    items: const [
                      'Todos jogam em uma única equipe.',
                      '5 fichas + 1 carta inicial.',
                      'Objetivo: acertar 10 cartas antes que as fichas '
                          'acabem.',
                      'Cada erro custa 1 ficha.',
                    ],
                  ),
                  const SizedBox(height: AppPadding.p32),

                  const _SectionTitle('Perguntas frequentes'),
                  const SizedBox(height: AppPadding.p16),
                  const _FaqAccordion(
                    question: 'Como reproduzir a música?',
                    answer:
                        'Ao abrir o aplicativo, siga as instruções na tela '
                        'para se conectar ao Spotify ou escolha jogar com o '
                        'Spotify Free. Se você estiver usando o Spotify '
                        'Free, a faixa começará a tocar após você virar o '
                        'celular para baixo ("Sensor de Giro") ou após uma '
                        'breve contagem regressiva de 3 segundos '
                        '("Contagem Regressiva"). Se estiver jogando com o '
                        'Spotify Premium, você poderá ouvir a música '
                        'inteira desde o início ("Faixas Completas") ou '
                        'curtir uma prévia de 30 segundos ("Prévias de 30 '
                        'segundos"). Consulte as regras do jogo para mais '
                        'detalhes sobre como reproduzir a música.',
                  ),
                  const SizedBox(height: AppPadding.p16),
                  const _FaqAccordion(
                    question: 'Quais músicas estão no BEATSPAN?',
                    answer:
                        'BEATSPAN traz centenas de sucessos inesquecíveis '
                        'de diversas décadas e gêneros. De clássicos '
                        'atemporais a sucessos recentes nas paradas, há '
                        'música para todos os gostos. E não se preocupe se '
                        'você não for um especialista em música: qualquer '
                        'pessoa que jogue BEATSPAN tem chance de vencer.',
                  ),
                  const SizedBox(height: AppPadding.p32),

                  Center(
                    child: TextButton(
                      onPressed: () =>
                          Navigator.pushNamed(context, Routes.faqRoute),
                      child: Text(
                        'Ver todas as perguntas',
                        style: getSemiBoldStyle(
                          color: ColorManager.yellowLink,
                          fontSize: FontSize.s16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.context});

  final BuildContext context;

  @override
  Widget build(BuildContext _) {
    return Container(
      height: context.screenWidth / 1.5,
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage(ImageAssets.rulesImage),
          fit: BoxFit.cover,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'COMO JOGAR',
              style: getSemiBoldStyle(
                color: ColorManager.white,
                fontSize: FontSize.s32,
              ),
            ),
            const SizedBox(height: AppPadding.p16),
            Text(
              'Beatspan',
              style: getRegularStyle(
                color: ColorManager.white,
                fontSize: FontSize.s20,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: getBoldStyle(color: ColorManager.white, fontSize: FontSize.s24),
    );
  }
}

class _BulletList extends StatelessWidget {
  const _BulletList({required this.items});

  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items
          .map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: AppPadding.p16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '•  ',
                    style: getBoldStyle(
                      color: ColorManager.primary,
                      fontSize: FontSize.s16,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      item,
                      style: getRegularStyle(
                        color: ColorManager.white,
                        fontSize: FontSize.s16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

class _StepTile extends StatelessWidget {
  const _StepTile({
    required this.number,
    required this.title,
    required this.description,
  });

  final int number;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return CardBorder(
      selected: false,
      child: Padding(
        padding: const EdgeInsets.all(AppPadding.p16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: AppPadding.p32,
              height: AppPadding.p32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: kSelectedGradient,
                shape: BoxShape.circle,
              ),
              child: Text(
                '$number',
                style: getBoldStyle(
                  color: ColorManager.white,
                  fontSize: FontSize.s16,
                ),
              ),
            ),
            const SizedBox(width: AppPadding.p16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: getSemiBoldStyle(
                      color: ColorManager.white,
                      fontSize: FontSize.s20,
                    ),
                  ),
                  const SizedBox(height: AppPadding.p4),
                  Text(
                    description,
                    style: getRegularStyle(
                      color: ColorManager.white,
                      fontSize: FontSize.s16,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FaqAccordion extends StatefulWidget {
  const _FaqAccordion({required this.question, required this.answer});

  final String question;
  final String answer;

  @override
  State<_FaqAccordion> createState() => _FaqAccordionState();
}

class _FaqAccordionState extends State<_FaqAccordion> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: ColorManager.primary, width: 1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.all(AppPadding.p16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.question.toUpperCase(),
                      style: getBoldStyle(
                        color: ColorManager.primary,
                        fontSize: FontSize.s20,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppPadding.p16),
                  Icon(
                    _expanded
                        ? Icons.remove_circle_outline
                        : Icons.add_circle_outline,
                    color: ColorManager.primary,
                  ),
                ],
              ),
            ),
          ),
          if (_expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppPadding.p16,
                AppPadding.zero,
                AppPadding.p16,
                AppPadding.p16,
              ),
              child: Text(
                widget.answer,
                style: getRegularStyle(
                  color: ColorManager.white,
                  fontSize: FontSize.s16,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.title, required this.items});

  final String title;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return CardBorder(
      selected: false,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppPadding.p16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: getSemiBoldStyle(
                color: ColorManager.white,
                fontSize: FontSize.s20,
              ),
            ),
            const SizedBox(height: AppPadding.p16),
            ...items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: AppPadding.p4),
                child: Text(
                  item,
                  style: getRegularStyle(
                    color: ColorManager.white,
                    fontSize: FontSize.s14,
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
