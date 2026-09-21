// © 2026 Davi Borges <daviborges.sistemas@gmail.com>
// Projeto : Beatspan
// Website :
// Token   : AFA32A23171530AD
// @wm:AFA32A23171530AD
//
// Todos os direitos reservados.

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../../domain/enum/flow_state.dart';
import '../../domain/model/contact_message.dart';
import '../resource/assets_manager.dart';
import '../resource/color_manager.dart';
import '../resource/screen_manager.dart';
import '../routes_manager.dart';
import 'contact_view_model.dart';

class ContactView extends StatefulWidget {
  final ContactViewModel viewModel;

  const ContactView({super.key, required this.viewModel});

  @override
  State<ContactView> createState() => _ContactViewState();
}

class _ContactViewState extends State<ContactView> {
  late final ContactViewModel _viewModel = widget.viewModel;
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _itemNumberController = TextEditingController();
  final _messageController = TextEditingController();
  ContactSubject? _subject;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _itemNumberController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_subject == null) {
      Fluttertoast.showToast(msg: 'Selecione um assunto');
      return;
    }

    final message = ContactMessage(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      itemNumber: _itemNumberController.text.trim(),
      subject: _subject!,
      message: _messageController.text.trim(),
    );

    final success = await _viewModel.send(message);
    if (!mounted) return;

    if (success) {
      Fluttertoast.showToast(msg: 'Mensagem enviada com sucesso!');
      Navigator.of(context).pop();
    } else {
      Fluttertoast.showToast(
        msg: _viewModel.errorMessage.value ?? 'Falha ao enviar a mensagem.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorManager.backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                SizedBox(
                  width: context.percentWidth(0.5),
                  child: Image.asset(ImageAssets.splashWordmark),
                ),
                const SizedBox(height: 24),
                Text(
                  'ENTRE EM CONTATO',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                    color: ColorManager.textLight,
                  ),
                ),
                const SizedBox(height: 12),
                _IntroText(
                  onFaqTap: () =>
                      Navigator.of(context).pushNamed(Routes.faqRoute),
                ),
                const SizedBox(height: 24),
                _ContactCard(
                  nameController: _nameController,
                  emailController: _emailController,
                  itemNumberController: _itemNumberController,
                  messageController: _messageController,
                  subject: _subject,
                  onSubjectChanged: (value) => setState(() => _subject = value),
                  onSubmit: _submit,
                  state: _viewModel.state,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _IntroText extends StatelessWidget {
  const _IntroText({required this.onFaqTap});

  final VoidCallback onFaqTap;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        style: TextStyle(
          color: ColorManager.textLight.withValues(alpha: 0.70),
          fontSize: 15,
          height: 1.5,
        ),
        children: [
          const TextSpan(
            text:
                'Você tem uma pergunta, sugestão ou comentário? Por '
                'favor, nos envie uma mensagem utilizando o formulário '
                'abaixo. Se você ainda não verificou o FAQ, pode '
                'encontrá-lo ',
          ),
          TextSpan(
            text: 'aqui',
            style: TextStyle(
              color: ColorManager.yellowLink,
              fontWeight: FontWeight.w600,
              decoration: TextDecoration.underline,
            ),
            recognizer: TapGestureRecognizer()..onTap = onFaqTap,
          ),
          const TextSpan(text: '.'),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}

class _ContactCard extends StatelessWidget {
  const _ContactCard({
    required this.nameController,
    required this.emailController,
    required this.itemNumberController,
    required this.messageController,
    required this.subject,
    required this.onSubjectChanged,
    required this.onSubmit,
    required this.state,
  });

  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController itemNumberController;
  final TextEditingController messageController;
  final ContactSubject? subject;
  final ValueChanged<ContactSubject?> onSubjectChanged;
  final VoidCallback onSubmit;
  final ValueNotifier<FlowState> state;

  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Campo obrigatório';
    }
    return null;
  }

  String? _emailValidator(String? value) {
    final requiredError = _requiredValidator(value);
    if (requiredError != null) return requiredError;
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(value!.trim())) {
      return 'E-mail inválido';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: ColorManager.cardBackground,
        border: Border.all(
          width: 1,
          color: Colors.white.withValues(alpha: 0.10),
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            height: 4,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  ColorManager.gradientPink,
                  ColorManager.gradientPurple,
                  ColorManager.primary,
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _FieldLabel('Seu nome'),
                const SizedBox(height: 8),
                _ContactTextField(
                  controller: nameController,
                  hintText: 'ex.: João Silva',
                  validator: _requiredValidator,
                ),
                const SizedBox(height: 20),
                _FieldLabel('Seu e-mail'),
                const SizedBox(height: 8),
                _ContactTextField(
                  controller: emailController,
                  hintText: 'ex.: joaosilva@mail.com',
                  keyboardType: TextInputType.emailAddress,
                  validator: _emailValidator,
                ),
                const SizedBox(height: 20),
                _FieldLabel('Num. do item'),
                const SizedBox(height: 8),
                _ContactTextField(
                  controller: itemNumberController,
                  hintText:
                      'ex.: 12345, cinco a dez dígitos próximos ao '
                      'código de barras',
                  keyboardType: TextInputType.number,
                  validator: _requiredValidator,
                ),
                const SizedBox(height: 20),
                _FieldLabel('Assunto'),
                const SizedBox(height: 8),
                _SubjectDropdown(value: subject, onChanged: onSubjectChanged),
                const SizedBox(height: 20),
                _FieldLabel('Mensagem'),
                const SizedBox(height: 8),
                _ContactTextField(
                  controller: messageController,
                  hintText: 'Escreva sua mensagem aqui...',
                  maxLines: 5,
                  validator: _requiredValidator,
                ),
                const SizedBox(height: 24),
                ListenableBuilder(
                  listenable: state,
                  builder: (_, __) => _SubmitButton(
                    loading: state.value == FlowState.loading,
                    onTap: onSubmit,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 15,
          color: ColorManager.textLight,
        ),
        children: [
          TextSpan(text: label),
          TextSpan(
            text: '*',
            style: TextStyle(color: ColorManager.accentPink),
          ),
        ],
      ),
    );
  }
}

class _ContactTextField extends StatelessWidget {
  const _ContactTextField({
    required this.controller,
    required this.hintText,
    this.keyboardType,
    this.maxLines = 1,
    this.validator,
  });

  final TextEditingController controller;
  final String hintText;
  final TextInputType? keyboardType;
  final int maxLines;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      style: TextStyle(color: ColorManager.textLight),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: ColorManager.textMuted),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.06),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: ColorManager.gradientPink, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: ColorManager.warning),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: ColorManager.warning, width: 1.5),
        ),
      ),
    );
  }
}

class _SubjectDropdown extends StatelessWidget {
  const _SubjectDropdown({required this.value, required this.onChanged});

  final ContactSubject? value;
  final ValueChanged<ContactSubject?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<ContactSubject>(
      initialValue: value,
      onChanged: onChanged,
      dropdownColor: ColorManager.cardBackground,
      style: TextStyle(color: ColorManager.textLight, fontSize: 15),
      icon: Icon(Icons.keyboard_arrow_down, color: ColorManager.textMuted),
      hint: Text(
        'Selecione um assunto',
        style: TextStyle(color: ColorManager.textMuted),
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.06),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: ColorManager.gradientPink, width: 1.5),
        ),
      ),
      items: ContactSubject.values
          .map(
            (subject) =>
                DropdownMenuItem(value: subject, child: Text(subject.label)),
          )
          .toList(),
    );
  }
}

class _SubmitButton extends StatelessWidget {
  const _SubmitButton({required this.loading, required this.onTap});

  final bool loading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Enviar mensagem',
      excludeSemantics: true,
      onTap: loading ? null : onTap,
      child: Container(
        height: 56,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: LinearGradient(
            colors: [ColorManager.gradientPink, ColorManager.primary],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(28),
            onTap: loading ? null : onTap,
            child: Center(
              child: loading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'ENVIAR',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.send_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
