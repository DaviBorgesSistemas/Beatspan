// © 2026 Davi Borges <daviborges.sistemas@gmail.com>
// Projeto : Beatspan
// Website : 
// Token   : AFA32A23171530AD
// @wm:AFA32A23171530AD
//
// Todos os direitos reservados.

import 'package:flutter/material.dart';
import '../../domain/enum/flow_state.dart';
import '../resource/assets_manager.dart';
import '../resource/color_manager.dart';
import '../resource/font_manager.dart';
import '../resource/screen_manager.dart';

import '../resource/style_manager.dart';
import '../resource/value_manager.dart';
import '../share/widgets/empty_container.dart';
import 'faqs_view_model.dart';
import 'widgets/faq_tile.dart';

class FaqsView extends StatefulWidget {
  final FaqsViewModel viewModel;

  const FaqsView({super.key, required this.viewModel});

  @override
  State<FaqsView> createState() => _FaqsViewState();
}

class _FaqsViewState extends State<FaqsView> {
  late final FaqsViewModel _viewModel = widget.viewModel;

  @override
  void initState() {
    super.initState();
    _bind();
  }

  void _bind() {
    _viewModel.start();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorManager.backgroundColor,
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
                border: Border.all(
                  width: 1,
                  color: ColorManager.lavender.withValues(alpha: 0.20),
                ),
              ),
              child: Icon(Icons.arrow_back, color: Colors.white),
            ),
          ),
        ),
        backgroundColor: ColorManager.backgroundColor,
        title: SizedBox(
          width: context.percentWidth(.5),
          child: Image.asset(ImageAssets.splashWordmark),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppPadding.p22,
            AppPadding.p32,
            AppPadding.p22,
            AppPadding.p46,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Perguntas frequentes',
                style: getBoldStyle(
                  color: ColorManager.white,
                  fontSize: FontSize.s24,
                ),
              ),
              const SizedBox(height: AppPadding.p16),
              ListenableBuilder(
                listenable: Listenable.merge([
                  _viewModel.state,
                  _viewModel.faqs,
                ]),
                builder: (_, child) => switch (_viewModel.state.value) {
                  FlowState.loading => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  FlowState.success => Column(
                    children: _viewModel.faqs.value!
                        .map((f) => FaqTile(faq: f))
                        .toList(),
                  ),
                  _ => const EmptyContainer(),
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
